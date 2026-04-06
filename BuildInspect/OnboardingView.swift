import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "camera.viewfinder",
            accentIcon: "exclamationmark.triangle.fill",
            title: "Record Cracks\n& Defects",
            subtitle: "Photograph and document structural defects with precise location tagging and severity classification.",
            color: Color(hex: "#E8682A"),
            shapes: [
                (0.15, 0.25, 60, 50), (0.82, 0.35, -30, 40),
                (0.5, 0.7, 15, 30), (0.7, 0.15, 45, 20)
            ]
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            accentIcon: "ruler.fill",
            title: "Track Changes\nOver Time",
            subtitle: "Measure crack width, compare before/after photos, and monitor if defects are growing or stabilizing.",
            color: Color(hex: "#2A7BE8"),
            shapes: [
                (0.2, 0.3, -20, 45), (0.78, 0.25, 40, 35),
                (0.4, 0.75, -15, 25), (0.85, 0.65, 25, 40)
            ]
        ),
        OnboardingPage(
            icon: "wrench.and.screwdriver.fill",
            accentIcon: "checkmark.shield.fill",
            title: "Plan Structural\nRepairs",
            subtitle: "Create repair plans, schedule contractors, track costs and get notified when inspections are due.",
            color: Color(hex: "#4CAF7D"),
            shapes: [
                (0.1, 0.2, 35, 55), (0.88, 0.4, -25, 30),
                (0.55, 0.8, 20, 45), (0.25, 0.7, -40, 35)
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { i in
                    OnboardingPageView(page: pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
            
            // Controls overlay
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        appState.completeOnboarding()
                    }
                    .font(BIFont.headline(15))
                    .foregroundColor(.biMidGray)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i == currentPage ? pages[currentPage].color : Color.biLightGray)
                                .frame(width: i == currentPage ? 24 : 8, height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button(action: nextAction) {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .font(BIFont.headline(16))
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(pages[currentPage].color)
                        .cornerRadius(14)
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 10, y: 4)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func nextAction() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            appState.completeOnboarding()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let accentIcon: String
    let title: String
    let subtitle: String
    let color: Color
    let shapes: [(CGFloat, CGFloat, Double, CGFloat)]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false
    @State private var iconBounce: CGFloat = 0
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Floating background shapes
                ForEach(0..<page.shapes.count, id: \.self) { i in
                    let s = page.shapes[i]
                    RoundedRectangle(cornerRadius: 8)
                        .fill(page.color.opacity(0.08))
                        .frame(width: s.3, height: s.3)
                        .rotationEffect(.degrees(s.2))
                        .position(x: geo.size.width * s.0, y: geo.size.height * s.1)
                        .offset(x: appeared ? 0 : 30, y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(Double(i) * 0.1), value: appeared)
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Illustration area
                    ZStack {
                        Circle()
                            .fill(page.color.opacity(0.08))
                            .frame(width: 200, height: 200)
                        Circle()
                            .fill(page.color.opacity(0.05))
                            .frame(width: 240, height: 240)
                        
                        VStack(spacing: 0) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(page.color)
                                    .frame(width: 100, height: 100)
                                    .shadow(color: page.color.opacity(0.35), radius: 20, y: 8)
                                
                                Image(systemName: page.icon)
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .offset(y: iconBounce)
                            .gesture(
                                DragGesture()
                                    .onChanged { v in dragOffset = v.translation }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                                            dragOffset = .zero
                                        }
                                    }
                            )
                            .offset(dragOffset)
                        }
                        
                        // Accent badge
                        Image(systemName: page.accentIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(page.color)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: page.color.opacity(0.2), radius: 8)
                            .offset(x: 55, y: -50)
                    }
                    .frame(height: 260)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1), value: appeared)
                    
                    Spacer().frame(height: 40)
                    
                    // Text content
                    VStack(spacing: 14) {
                        Text(page.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.biDark)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                        
                        Text(page.subtitle)
                            .font(BIFont.body(16))
                            .foregroundColor(.biMidGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
            // Subtle icon bounce
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1)) {
                iconBounce = -8
            }
        }
        .onDisappear { appeared = false }
    }
}
