//
//  ShowThatApp.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppConfiguration.shared.configureFirebase()
        _ = EncryptionService.shared
        Logger.shared.logInfo("App launched successfully!")
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Logger.shared.logWarning("Memory warning received")
        ErrorManager.shared.handle(SystemError.memoryWarning, context: .general)
    }
}

@available(iOS 17.0, *)
@main
struct ShowThatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthState()
    @StateObject private var qrManager = QRCodeManager()
    @StateObject private var paymentManager = PaymentManager.shared
    private var errorManager = ErrorManager.shared
    @State private var showingLaunchScreen = true
    
    init() {
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showingLaunchScreen {
                    LaunchScreen()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showingLaunchScreen = false
                                }
                            }
                        }
                } else {
                    ContentView()
                        .environmentObject(authState)
                        .environmentObject(qrManager)
                        .environmentObject(paymentManager)
                        .preferredColorScheme(.light)
                        .withErrorHandling()
                }
            }
            .environmentObject(errorManager)
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.shadowColor = .clear
        navBarAppearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // Configure tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure other UI elements
        UITableView.appearance().backgroundColor = .clear
        UITextView.appearance().backgroundColor = .clear
    }
}
