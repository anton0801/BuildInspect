import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary Brand
    static let biOrange = Color(hex: "#E8682A")
    static let biOrangeDark = Color(hex: "#C4521F")
    static let biOrangeLight = Color(hex: "#F5895A")
    
    // Neutrals
    static let biBackground = Color(hex: "#F7F5F2")
    static let biSurface = Color(hex: "#FFFFFF")
    static let biSurfaceElevated = Color(hex: "#FDFCFB")
    
    // Dark
    static let biDark = Color(hex: "#1A1614")
    static let biDarkSecondary = Color(hex: "#2D2825")
    static let biMidGray = Color(hex: "#7A7470")
    static let biLightGray = Color(hex: "#C8C4C0")
    static let biDivider = Color(hex: "#EAE8E5")
    
    // Severity
    static let biLow = Color(hex: "#4CAF7D")
    static let biMedium = Color(hex: "#F5A623")
    static let biHigh = Color(hex: "#E53935")
    static let biCritical = Color(hex: "#B71C1C")
    
    // Accent
    static let biBlue = Color(hex: "#2A7BE8")
    static let biPurple = Color(hex: "#7B2AE8")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Presets
extension LinearGradient {
    static let biOrangeGradient = LinearGradient(
        colors: [.biOrange, .biOrangeDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let biDarkGradient = LinearGradient(
        colors: [.biDark, .biDarkSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
    static let biCardGradient = LinearGradient(
        colors: [Color.white, Color(hex: "#F7F5F2")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography
struct BIFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Severity Helper
enum Severity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .biLow
        case .medium: return .biMedium
        case .high: return .biHigh
        case .critical: return .biCritical
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "xmark.octagon.fill"
        case .critical: return "bolt.fill"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
}

// MARK: - Reusable Components

struct BIPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var style: ButtonStyle = .filled
    
    enum ButtonStyle { case filled, outlined, ghost }
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    pressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style == .filled ? .white : .biOrange))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(BIFont.headline(16))
                }
            }
            .foregroundColor(style == .filled ? .white : .biOrange)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Group {
                    if style == .filled {
                        LinearGradient.biOrangeGradient
                    } else if style == .outlined {
                        Color.clear
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style == .outlined ? Color.biOrange : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(14)
            .scaleEffect(pressed ? 0.97 : 1.0)
            .shadow(color: style == .filled ? Color.biOrange.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(isLoading)
    }
}

struct BITextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isFocused ? .biOrange : .biMidGray)
                    .frame(width: 20)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(BIFont.body(15))
                    .foregroundColor(.biDark)
            } else {
                TextField(placeholder, text: $text)
                    .font(BIFont.body(15))
                    .foregroundColor(.biDark)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.biSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.biOrange : Color.biDivider, lineWidth: isFocused ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onTapGesture { isFocused = true }
    }
}

struct BICard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.biSurface)
            .cornerRadius(16)
            .shadow(color: Color.biDark.opacity(0.06), radius: 12, y: 4)
    }
}

struct SeverityBadge: View {
    let severity: Severity
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: severity.icon)
                .font(.system(size: 10, weight: .bold))
            Text(severity.rawValue)
                .font(BIFont.caption(11))
        }
        .foregroundColor(severity.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(severity.color.opacity(0.12))
        .cornerRadius(8)
    }
}

struct BINavBar: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    var trailingAction: (() -> Void)? = nil
    var trailingIcon: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.biDark)
                        .frame(width: 36, height: 36)
                        .background(Color.biBackground)
                        .cornerRadius(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 1) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(BIFont.caption(11))
                        .foregroundColor(.biMidGray)
                }
                Text(title)
                    .font(BIFont.display(20))
                    .foregroundColor(.biDark)
            }
            
            Spacer()
            
            if let trailingAction = trailingAction, let icon = trailingIcon {
                Button(action: trailingAction) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.biOrange)
                        .frame(width: 36, height: 36)
                        .background(Color.biOrange.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.biOrange.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.biOrange.opacity(0.6))
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(BIFont.headline(17))
                    .foregroundColor(.biDark)
                Text(message)
                    .font(BIFont.body(14))
                    .foregroundColor(.biMidGray)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(BIFont.headline(14))
                        .foregroundColor(.biOrange)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
