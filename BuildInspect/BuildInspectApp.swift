import SwiftUI

@main
struct BuildInspectApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

struct RootView: View {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore.shared
    
    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
            } else if !appState.isAuthenticated {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .environmentObject(appState)
        .environmentObject(dataStore)
        .preferredColorScheme(appState.appTheme.colorScheme)
    }
}
