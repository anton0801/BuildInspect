import SwiftUI

@main
struct BuildInspectApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(dataStore)
                .preferredColorScheme(appState.appTheme.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView(isShowing: $showSplash)
            } else if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
            } else if !appState.isAuthenticated {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
    }
}
