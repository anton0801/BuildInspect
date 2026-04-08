import SwiftUI


final class PushBridge: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(from: payload) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: .init("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from p: [AnyHashable: Any]) -> String? {
        if let u = p["url"] as? String { return u }
        if let d = p["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let a = p["aps"] as? [String: Any], let d = a["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let c = p["custom"] as? [String: Any], let u = c["target_url"] as? String { return u }
        return nil
    }
}

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showSignUp = false
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            
            // Decorative background
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.biOrange.opacity(0.06))
                        .frame(width: 320, height: 320)
                        .offset(x: 80, y: -60)
                    Circle()
                        .fill(Color.biOrange.opacity(0.04))
                        .frame(width: 200, height: 200)
                        .offset(x: -60, y: 20)
                }
                Spacer()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo + tagline
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient.biOrangeGradient)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.biOrange.opacity(0.35), radius: 20, y: 8)
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("Build")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.biDark)
                            Text("Inspect")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.biOrange)
                        }
                        
                        Text("Structural crack monitoring\nfor buildings you care about.")
                            .font(BIFont.body(16))
                            .foregroundColor(.biMidGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)
                
                Spacer()
                
                // Feature highlights
                HStack(spacing: 16) {
                    WelcomeFeatureChip(icon: "camera.fill", label: "Track")
                    WelcomeFeatureChip(icon: "ruler.fill", label: "Measure")
                    WelcomeFeatureChip(icon: "wrench.fill", label: "Repair")
                }
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appeared)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    BIPrimaryButton(title: "Create Account", icon: "person.badge.plus") {
                        showSignUp = true
                    }
                    BIPrimaryButton(title: "Log In", icon: "arrow.right.circle", action: { showLogin = true }, style: .outlined)
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appeared)
                
                Spacer().frame(height: 50)
            }
        }
        .fullScreenCover(isPresented: $showSignUp) { SignUpView() }
        .fullScreenCover(isPresented: $showLogin) { LogInView() }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true } }
    }
}

struct WelcomeFeatureChip: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.biOrange)
            Text(label)
                .font(BIFont.caption(12))
                .foregroundColor(.biMidGray)
        }
        .frame(width: 72, height: 64)
        .background(Color.biSurface)
        .cornerRadius(12)
        .shadow(color: Color.biDark.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.biMidGray)
                                    .frame(width: 32, height: 32)
                                    .background(Color.biSurface)
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        VStack(spacing: 6) {
                            Text("Create Account")
                                .font(BIFont.display(28))
                                .foregroundColor(.biDark)
                            Text("Join BuildInspect to monitor your buildings")
                                .font(BIFont.body(15))
                                .foregroundColor(.biMidGray)
                        }
                        .padding(.top, 16)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
                    
                    // Form
                    VStack(spacing: 16) {
                        BITextField(placeholder: "Full Name", text: $name, icon: "person.fill")
                        BITextField(placeholder: "Email Address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        BITextField(placeholder: "Password (min 6 chars)", text: $password, icon: "lock.fill", isSecure: true)
                        
                        if !errorMessage.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.biHigh)
                                    .font(.system(size: 14))
                                Text(errorMessage)
                                    .font(BIFont.body(14))
                                    .foregroundColor(.biHigh)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, -4)
                        }
                        
                        BIPrimaryButton(
                            title: "Create Account",
                            icon: nil,
                            action: attemptSignUp,
                            isLoading: isLoading
                        )
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
                    
                    // Terms
                    Text("By creating an account, you agree to our Terms of Service and Privacy Policy.")
                        .font(BIFont.caption(12))
                        .foregroundColor(.biLightGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                }
            }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true } }
    }
    
    private func attemptSignUp() {
        isLoading = true
        errorMessage = ""
        appState.signUp(name: name, email: email, password: password) { success, error in
            isLoading = false
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = error
            }
        }
    }
}

// MARK: - Log In View
struct LogInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            
            // Background decoration
            VStack {
                Spacer()
                Circle()
                    .fill(Color.biOrange.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: 100, y: 80)
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.biMidGray)
                                    .frame(width: 32, height: 32)
                                    .background(Color.biSurface)
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient.biOrangeGradient)
                                .frame(width: 64, height: 64)
                                .shadow(color: Color.biOrange.opacity(0.3), radius: 12, y: 4)
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 6) {
                            Text("Welcome Back")
                                .font(BIFont.display(28))
                                .foregroundColor(.biDark)
                            Text("Sign in to continue monitoring")
                                .font(BIFont.body(15))
                                .foregroundColor(.biMidGray)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
                    
                    // Form
                    VStack(spacing: 16) {
                        BITextField(placeholder: "Email Address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        BITextField(placeholder: "Password", text: $password, icon: "lock.fill", isSecure: true)
                        
                        if !errorMessage.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.biHigh)
                                    .font(.system(size: 14))
                                Text(errorMessage)
                                    .font(BIFont.body(14))
                                    .foregroundColor(.biHigh)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        BIPrimaryButton(
                            title: "Log In",
                            icon: nil,
                            action: attemptLogin,
                            isLoading: isLoading
                        )
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
                }
            }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true } }
    }
    
    private func attemptLogin() {
        isLoading = true
        errorMessage = ""
        appState.logIn(email: email, password: password) { success, error in
            isLoading = false
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = error
            }
        }
    }
}
