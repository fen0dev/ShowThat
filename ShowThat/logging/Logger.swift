//
//  Logger.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import Foundation
import os.log

/// Sistema di logging strutturato per debugging e monitoring
final class Logger {
    static let shared = Logger()
    
    private let osLog = OSLog(subsystem: "com.ShowThat.ShowThat", category: "App")
    private let fileManager = FileManager.default
    private let logQueue = DispatchQueue(label: "com.showthat.logging", qos: .utility)
    
    private var logDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("Logs")
    }
    
    private init() {
        setupLogDirectory()
    }
    
    // MARK: - Public Methods
    
    func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func logError(_ error: AppError, file: String = #file, function: String = #function, line: Int = #line) {
        let message = "Error: \(error.localizedDescription) | Type: \(error.type.rawValue)"
        log(message, level: .error, category: "Error", file: file, function: function, line: line)
    }
    
    func logError(_ message: String, category: String = "Error", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func logNetwork(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: "Network", file: file, function: function, line: line)
    }
    
    func logAnalytics(_ event: String, parameters: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        let paramsString = parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let message = "Analytics: \(event) | \(paramsString)"
        log(message, level: .info, category: "Analytics", file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private func log(_ message: String, level: LogLevel, category: String, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.iso8601.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue.uppercased())] [\(category)] \(fileName):\(line) \(function) - \(message)"
        
        // Console logging
        if AppConfiguration.shared.debugMode {
            print(logMessage)
        }
        
        // OS Log
        let osLogType: OSLogType = {
            switch level {
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }()
        os_log("%{public}@", log: osLog, type: osLogType, logMessage)
        
        // File logging (async)
        logQueue.async { [weak self] in
            self?.writeToFile(logMessage)
        }
    }
    
    private func writeToFile(_ message: String) {
        let logFile = logDirectory.appendingPathComponent("app.log")
        
        do {
            if !fileManager.fileExists(atPath: logFile.path) {
                try "".write(to: logFile, atomically: true, encoding: .utf8)
            }
            
            let fileHandle = try FileHandle(forWritingTo: logFile)
            defer { fileHandle.closeFile() }
            
            fileHandle.seekToEndOfFile()
            fileHandle.write((message + "\n").data(using: .utf8)!)
            
            // Rotate logs if too large (> 10MB)
            let attributes = try fileManager.attributesOfItem(atPath: logFile.path)
            if let fileSize = attributes[.size] as? Int64, fileSize > 10 * 1024 * 1024 {
                rotateLogFile(logFile)
            }
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    private func rotateLogFile(_ logFile: URL) {
        let timestamp = DateFormatter.iso8601.string(from: Date())
        let rotatedFile = logDirectory.appendingPathComponent("app_\(timestamp).log")
        
        do {
            try fileManager.moveItem(at: logFile, to: rotatedFile)
            try "".write(to: logFile, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to rotate log file: \(error)")
        }
    }
    
    private func setupLogDirectory() {
        do {
            try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create log directory: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum LogLevel: String, CaseIterable {
    case info = "info"
    case warning = "warning"
    case error = "error"
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}
