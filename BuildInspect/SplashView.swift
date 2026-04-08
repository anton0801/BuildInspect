import SwiftUI
import Combine
import Network

struct SplashView: View {
    
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var crackOffset: CGFloat = 30
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var backgroundOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var exitOpacity: Double = 1
    
    // Crack particle positions
    private let particles: [(CGFloat, CGFloat, CGFloat)] = [
        (0.2, 0.3, 30), (0.8, 0.2, 50), (0.1, 0.7, 20),
        (0.9, 0.8, 40), (0.5, 0.15, 60), (0.3, 0.85, 25),
        (0.7, 0.6, 35), (0.15, 0.5, 45)
    ]
    
    @StateObject private var app: BuildInspectApplication
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = UserDefaultsStorageService()
        let validation = SupabaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        _app = StateObject(wrappedValue: BuildInspectApplication(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        ))
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                app.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                app.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.biBackground
                    .ignoresSafeArea()
                    .opacity(backgroundOpacity)
                
                GeometryReader { geometry in
                    Image("vert_ldng_bg")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea().opacity(0.7)
                        .blur(radius: 9)
                }
                .ignoresSafeArea()
                
                // Subtle grid texture
                GeometryReader { geo in
                    ForEach(0..<8, id: \.self) { i in
                        ForEach(0..<15, id: \.self) { j in
                            Rectangle()
                                .fill(Color.biOrange.opacity(0.03))
                                .frame(width: 1, height: geo.size.height)
                                .offset(x: CGFloat(i) * geo.size.width / 7)
                        }
                    }
                    ForEach(0..<12, id: \.self) { j in
                        Rectangle()
                            .fill(Color.biOrange.opacity(0.03))
                            .frame(width: geo.size.width, height: 1)
                            .offset(y: CGFloat(j) * geo.size.height / 11)
                    }
                }
                .opacity(particleOpacity)
                
                // Floating crack fragments
                GeometryReader { geo in
                    ForEach(0..<particles.count, id: \.self) { i in
                        let p = particles[i]
                        CrackFragment(rotation: p.2)
                            .frame(width: 16, height: 16)
                            .position(
                                x: geo.size.width * p.0,
                                y: geo.size.height * p.1
                            )
                            .opacity(particleOpacity * 0.3)
                    }
                }
                
                NavigationLink(
                    destination: BuildInspectWebView().navigationBarHidden(true),
                    isActive: $app.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $app.navigateToMain
                ) { EmptyView() }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo icon
                    ZStack {
                        // Background circle glow
                        Circle()
                            .fill(Color.biOrange.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color.biOrange.opacity(0.06))
                            .frame(width: 150, height: 150)
                        
                        // Brick wall with crack icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient.biOrangeGradient)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.biOrange.opacity(0.4), radius: 20, y: 8)
                            
                            // Wall cracks icon
                            VStack(spacing: 0) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    }
                    
                    Spacer().frame(height: 28)
                    
                    // App name
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("Build")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(.biDark)
                            Text("Inspect")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(.biOrange)
                        }
                        .opacity(logoOpacity)
                        
                        Text("Monitor structural cracks.")
                            .font(BIFont.body(16))
                            .foregroundColor(.biMidGray)
                            .opacity(taglineOpacity)
                            .offset(y: taglineOffset)
                        
                        ProgressView().tint(.white)
                    }
                    
                    Spacer()
                    
                    // Bottom loading indicator
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.biOrange.opacity(i == 0 ? 1 : 0.3))
                                    .frame(width: i == 0 ? 24 : 8, height: 4)
                            }
                        }
                        .opacity(taglineOpacity)
                        
                        Text("v1.1.0")
                            .font(BIFont.caption(12))
                            .foregroundColor(.biLightGray)
                            .opacity(taglineOpacity)
                    }
                    .padding(.bottom, 50)
                }
            }
            .opacity(exitOpacity)
            .onAppear {
                animate()
                setupStreams()
                setupNetworkMonitoring()
                app.initialize()
            }
            .fullScreenCover(isPresented: $app.showPermissionPrompt) {
                BuildInspectNotificationView(app: app)
            }
            .fullScreenCover(isPresented: $app.showOfflineView) {
                UnavailableView()
            }
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                app.networkStatusChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    private func animate() {
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            particleOpacity = 1
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
            taglineOpacity = 1
            taglineOffset = 0
        }
    }
}

struct CrackFragment: View {
    let rotation: Double
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 4, y: 0))
            path.addLine(to: CGPoint(x: 8, y: 6))
            path.addLine(to: CGPoint(x: 12, y: 4))
            path.addLine(to: CGPoint(x: 7, y: 12))
            path.addLine(to: CGPoint(x: 4, y: 8))
        }
        .stroke(Color.biOrange, lineWidth: 1.5)
        .rotationEffect(.degrees(rotation))
    }
}

struct BuildInspectNotificationView: View {
    let app: BuildInspectApplication
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "pp_lan_bg" : "pp_vert_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                app.requestPermission()
            } label: {
                Image("pp_b")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                app.deferPermission()
            } label: {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
    }
}

#Preview {
    SplashView()
}
