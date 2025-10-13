//
//  ImageCache.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 09/08/2025.
//

import UIKit
import CryptoKit
import Foundation

/// Sistema di cache avanzato per immagini con gestione memoria e disco
final class ImageCache {
    static let shared = ImageCache()
    
    // MARK: - Properties
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    private let networkManager = NetworkImageManager()
    private let maxMemorySize: Int = 50 * 1024 * 1024 // 50MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 giorni
    
    // MARK: - Initialization
    private init() {
        // Configura memory cache
        memoryCache.totalCostLimit = maxMemorySize
        memoryCache.countLimit = 100
        memoryCache.name = "ShowThatImageCache"
        
        // Setup disk cache
        self.diskCache = DiskCache(
            name: "ShowThatImages",
            maxSize: 200 * 1024 * 1024, // 200MB
            maxAge: maxCacheAge
        )
        
        // Setup memory warning observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func image(for url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        // 1. Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            Logger.shared.logInfo("Image loaded from memory cache: \(url.lastPathComponent)")
            return cachedImage
        }
        
        // 2. Check disk cache
        if let diskImage = await diskCache.image(for: url) {
            Logger.shared.logInfo("Image loaded from disk cache: \(url.lastPathComponent)")
            // Store in memory cache for faster access
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        // 3. Download from network
        Logger.shared.logInfo("Downloading image from network: \(url.lastPathComponent)")
        return await downloadAndCache(url: url)
    }
    
    func store(_ image: UIImage, for url: URL) {
        let cacheKey = url.absoluteString as NSString
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: cacheKey)
        
        // Store in disk cache asynchronously
        Task {
            await diskCache.store(image, for: url)
        }
    }
    
    func removeImage(for url: URL) {
        let cacheKey = url.absoluteString as NSString
        memoryCache.removeObject(forKey: cacheKey)
        
        Task {
            await diskCache.removeImage(for: url)
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        
        Task {
            await diskCache.clearCache()
        }
    }
    
    // MARK: - Private Methods
    
    private func downloadAndCache(url: URL) async -> UIImage? {
        do {
            let image = try await networkManager.downloadImage(from: url)
            
            if let image = image {
                store(image, for: url)
                Logger.shared.logInfo("Image downloaded and cached: \(url.lastPathComponent)")
            }
            
            return image
        } catch {
            Logger.shared.logError("Failed to download image: \(url.lastPathComponent) - \(error)")
            return nil
        }
    }
    
    @objc private func handleMemoryWarning() {
        Logger.shared.logWarning("Memory warning - clearing image cache")
        memoryCache.removeAllObjects()
    }
}

// MARK: - Disk Cache

final class DiskCache: @unchecked Sendable {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxSize: Int
    private let maxAge: TimeInterval
    private let queue = DispatchQueue(label: "com.showthat.diskcache", qos: .utility)
    
    init(name: String, maxSize: Int, maxAge: TimeInterval) {
        self.maxSize = maxSize
        self.maxAge = maxAge
        
        // Create cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDirectory.appendingPathComponent(name)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Clean old files on init
        Task {
            await cleanOldFiles()
        }
    }
    
    func image(for url: URL) async -> UIImage? {
        let fileURL = fileURL(for: url)
        
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                guard self.fileManager.fileExists(atPath: fileURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Check file age
                do {
                    let attributes = try self.fileManager.attributesOfItem(atPath: fileURL.path)
                    if let modificationDate = attributes[.modificationDate] as? Date,
                       Date().timeIntervalSince(modificationDate) > self.maxAge {
                        try? self.fileManager.removeItem(at: fileURL)
                        continuation.resume(returning: nil)
                        return
                    }
                } catch {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Load image
                if let data = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func store(_ image: UIImage, for url: URL) async {
        let fileURL = fileURL(for: url)
        
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard self != nil else {
                    continuation.resume()
                    return
                }
                
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    continuation.resume()
                    return
                }
                
                do {
                    try data.write(to: fileURL)
                    continuation.resume()
                } catch {
                    Logger.shared.logError("Failed to store image to disk: \(error)")
                    continuation.resume()
                }
            }
        }
        
        // Check cache size and clean if needed
        await checkCacheSize()
    }
    
    func removeImage(for url: URL) async {
        let fileURL = fileURL(for: url)
        
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                try? self.fileManager.removeItem(at: fileURL)
                continuation.resume()
            }
        }
    }
    
    func clearCache() async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    let files = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
                    for file in files {
                        try? self.fileManager.removeItem(at: file)
                    }
                    continuation.resume()
                } catch {
                    Logger.shared.logError("Failed to clear disk cache: \(error)")
                    continuation.resume()
                }
            }
        }
    }
    
    private func fileURL(for url: URL) -> URL {
        let filename = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent("\(filename).jpg")
        
    }
    
    private func checkCacheSize() async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    let files = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
                    
                    var totalSize = 0
                    var fileInfos: [(URL, Int64)] = []
                    
                    for file in files {
                        let attributes = try self.fileManager.attributesOfItem(atPath: file.path)
                        if let fileSize = attributes[.size] as? Int64 {
                            totalSize += Int(fileSize)
                            fileInfos.append((file, fileSize))
                        }
                    }
                    
                    if totalSize > self.maxSize {
                        // Sort by modification date (oldest first)
                        fileInfos.sort { file1, file2 in
                            let date1 = (try? self.fileManager.attributesOfItem(atPath: file1.0.path)[.modificationDate] as? Date) ?? Date.distantPast
                            let date2 = (try? self.fileManager.attributesOfItem(atPath: file2.0.path)[.modificationDate] as? Date) ?? Date.distantPast
                            return date1 < date2
                        }
                        
                        // Remove oldest files until under limit
                        var currentSize = totalSize
                        for (file, size) in fileInfos {
                            if currentSize <= self.maxSize {
                                break
                            }
                            try? self.fileManager.removeItem(at: file)
                            currentSize -= Int(size)
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    Logger.shared.logError("Failed to check cache size: \(error)")
                    continuation.resume()
                }
            }
        }
    }
    
    private func cleanOldFiles() async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    let files = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
                    
                    for file in files {
                        let attributes = try self.fileManager.attributesOfItem(atPath: file.path)
                        if let modificationDate = attributes[.modificationDate] as? Date,
                           Date().timeIntervalSince(modificationDate) > self.maxAge {
                            try? self.fileManager.removeItem(at: file)
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    Logger.shared.logError("Failed to clean old files: \(error)")
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Network Image Manager

final class NetworkImageManager: @unchecked Sendable {
    private let session: URLSession
    private let maxConcurrentDownloads = 5
    private let downloadQueue = DispatchQueue(label: "com.showthat.imagedownloads", qos: .userInitiated, attributes: .concurrent)
    private let semaphore: DispatchSemaphore
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        
        self.session = URLSession(configuration: config)
        self.semaphore = DispatchSemaphore(value: maxConcurrentDownloads)
    }
    
    func downloadImage(from url: URL) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            downloadQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: URLError(.cancelled))
                    return
                }
                
                self.semaphore.wait()
                
                let task = self.session.dataTask(with: url) { data, response, error in
                    defer { self.semaphore.signal() }
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let data = data,
                          let image = UIImage(data: data) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    continuation.resume(returning: image)
                }
                
                task.resume()
            }
        }
    }
}
