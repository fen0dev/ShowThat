//
//  DashboardView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var viewModel: QRCodeManager
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    @State private var showingUpgradeSheet = false
    @State private var showingProfileSheet = false
    @State private var searchText = ""
    @State private var animateQR = false
    
    var filteredQRCodes: [QRCodeModel] {
        if searchText.isEmpty {
            return viewModel.qrCodes
        }
        return viewModel.qrCodes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.content.displayText.localizedCaseInsensitiveContains(searchText)
        }
    }
    var body: some View {
        NavigationView {
            ZStack {
                // background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 1.0),
                        Color(red: 0.92, green: 0.94, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    subscriptionStatusCard
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    
                    searchBar
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    
                    tabSelector
                        .padding(.bottom, 10)
                    
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            if filteredQRCodes.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(filteredQRCodes) { qrCode in
                                    QRCodeCard(
                                        qrCode: qrCode,
                                        qrManager: viewModel
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                animateQR = true
            }
            .sheet(isPresented: $showingCreateSheet, content: {
                CreateQRCodeView(qrManager: viewModel)
            })
            .sheet(isPresented: $showingUpgradeSheet, content: {
                UpgradeView(qrManager: viewModel)
            })
            .sheet(isPresented: $showingProfileSheet, content: {
                ProfileSettingsView()
                    .environmentObject(QRCodeManager())
            })
            .overlay(alignment: .bottomTrailing) {
                if !filteredQRCodes.isEmpty {
                    FloatingActionButton {
                        if viewModel.canCreateQRCode(isDynamic: false) {
                            withAnimation(.spring()) {
                                showingCreateSheet = true
                            }
                        } else {
                            AlertManager.shared.showError(
                                title: "Limit Reached",
                                message: "Upgrade to create more QR codes!"
                            ) {
                                withAnimation(.spring()) {
                                    showingUpgradeSheet = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Components
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("ShowThat")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Business & QR Studio")
                    .font(.subheadline)
                    .foregroundStyle(.gray.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 50)
        .padding(.bottom, 20)
    }
    
    private var subscriptionStatusCard: some View {
        SubscriptionStatusView()
            .environmentObject(viewModel)
            .environmentObject(PaymentManager.shared)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search QR codes...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
        )
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                TabButton(title: "All", count: viewModel.qrCodes.count, isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Dynamic", count: viewModel.qrCodes.filter { $0.isDynamic }.count, isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                TabButton(title: "Business Cards", count: viewModel.qrCodes.filter { $0.type == .vCard }.count, isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "qrcode")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                         colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing
                     )
                )
            
            Text("No QR Codes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first QR code to start growing your business connections")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                withAnimation(.spring()) {
                    showingCreateSheet = true
                }
            }) {
                Label("Create QR Code", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background {
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .cornerRadius(25)
                    .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
            }
        }
        .padding(.top, 35)
    }
    
    // MARK: - Actions
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(QRCodeManager())
        .environmentObject(PaymentManager.shared)
}
