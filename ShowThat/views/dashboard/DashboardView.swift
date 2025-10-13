//
//  DashboardView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import FirebaseAuth

@available(iOS 17.0, *)
struct DashboardView: View {
    @EnvironmentObject var viewModel: QRCodeManager
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    @State private var showingUpgradeSheet = false
    @State private var showingProfileSheet = false
    @State private var searchText = ""
    @State private var animateQR = false
    @State private var scrollOffset: CGFloat = 0
    @State private var bannerHeight: CGFloat = 0
    
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
                    ScrollView {
                        // Tracker offset in cima
                        Color.clear
                            .frame(height: 1)
                            .background(
                                GeometryReader { geo in
                                    let offset = max(0, -geo.frame(in: .named("dashboardScroll")).minY)
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: offset)
                                }
                            )

                        // Header scrollabile (banner + search + tabs)
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
                        }

                        // Lista
                        qrCodesList
                    }
                    .coordinateSpace(name: "dashboardScroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollOffset = value
                        }
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
            })
            .overlay(alignment: .bottomTrailing) {
                if !filteredQRCodes.isEmpty {
                    floatingActionButtons
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
                            colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Business & QR Studio")
                    .font(.subheadline)
                    .foregroundStyle(.gray.opacity(0.7))
            }
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(DesignTokens.Colors.primary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
        .padding(.bottom, 20)
        .fadeIn()
    }
    
    private var collapseProgress: CGFloat {
        min(max(scrollOffset / 120, 0), 1)
    }
    
    private var qrCodesList: some View {
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
                    .slideIn(direction: .fromBottom, delay: Double(filteredQRCodes.firstIndex(where: { $0.id == qrCode.id }) ?? 0) * 0.1)
                    .trackPerformance("QR Code Card: \(qrCode.name)")
                }
            }
        }
        .padding(.vertical)
        .padding(.bottom, 40)
    }
    
    private var subscriptionStatusCard: some View {
        SubscriptionStatusView()
            .environmentObject(viewModel)
            .environmentObject(PaymentManager.shared)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: BannerHeightKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(BannerHeightKey.self) { bannerHeight = $0 }
            // collapse effect
            .opacity(1 - collapseProgress)
            .scaleEffect(1 - 0.15 * collapseProgress, anchor: .top)
            .frame(height: bannerHeight > 0 ? max(0, bannerHeight * (1 - collapseProgress)) : nil, alignment: .top)
            .clipped()
            .animation(.easeOut(duration: 0.2), value: collapseProgress)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search QR codes...", text: $searchText)
                .textFieldStyle(ModernTextFieldStyle())
                .onChange(of: searchText) { _, newValue in
                    Task {
                        try await Task.sleep(nanoseconds: 300_000_000)
                        if searchText == newValue {
                            HapticManager.shared.selectionChanged()
                        }
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    HapticManager.shared.buttonTapped()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.surface)
                .shadow(color: DesignTokens.Shadow.sm, radius: 5, y: 2)
        )
        .slideIn(direction: .fromTop, delay: 0.1)
        // fade-in effect
        .scaleEffect(1 - 0.1 * collapseProgress, anchor: .top)
        .offset(y: -12 * collapseProgress)
        .animation(.easeOut(duration: 0.2), value: collapseProgress)
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                TabButton(title: "All", count: viewModel.qrCodes.count, isSelected: selectedTab == 0) {
                    selectedTab = 0
                    HapticManager.shared.cardSelected()
                }
                
                TabButton(title: "Dynamic", count: viewModel.qrCodes.filter { $0.isDynamic }.count, isSelected: selectedTab == 1) {
                    selectedTab = 1
                    HapticManager.shared.cardSelected()
                }
                
                TabButton(title: "Business Cards", count: viewModel.qrCodes.filter { $0.type == .vCard }.count, isSelected: selectedTab == 2) {
                    selectedTab = 2
                    HapticManager.shared.cardSelected()
                }
            }
            .padding(.horizontal)
        }
        .slideIn(direction: .fromTop, delay: 0.2)
        .offset(y: -6 * collapseProgress)
        .animation(.easeOut(duration: 0.2), value: collapseProgress)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "qrcode",
            title: "No QR Codes",
            message: "Design your first QR Code",
            actionTitle: "Create"
        ) {
            withAnimation(AnimationManager.springBouncy) {
                showingCreateSheet = true
            }
            HapticManager.shared.buttonTapped()
        }
        .scaleIn(delay: 0.3)
    }
    
    private var floatingActionButtons: some View {
        FloatingActionButton {
            if viewModel.canCreateQRCode(isDynamic: false) {
                withAnimation(AnimationManager.springBouncy) {
                    showingCreateSheet = true
                }
                HapticManager.shared.buttonTapped()
            } else {
                HapticManager.shared.warningAction()
                AlertManager.shared.showError(
                    title: "Limite Raggiunto",
                    message: "Aggiorna per creare più QR codes!"
                ) {
                    withAnimation(AnimationManager.springBouncy) {
                        showingUpgradeSheet = true
                    }
                }
            }
        }
        .padding()
        .scaleIn(delay: 0.5)
        .pulse(minScale: 0.95, maxScale: 1.05, duration: 2.0)
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
    if #available(iOS 17.0, *) {
        DashboardView()
            .environmentObject(QRCodeManager())
            .environmentObject(PaymentManager.shared)
    } else {
        // Fallback on earlier versions
    }
}

// MARK: - Helpers for scroll
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BannerHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
