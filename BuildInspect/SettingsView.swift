import SwiftUI
import UserNotifications

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showLogOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteFinalConfirm = false
    @State private var deletionText = ""
    @State private var navigateToProfile = false
    @State private var navigateToNotifications = false
    @State private var navigateToActivity = false
    @State private var navigateToCalendar = false
    @State private var navigateToReports = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        profileHeaderCard
                        appearanceSection
                        unitsSection
                        notificationsSection
                        dataSection
                        accountSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BINavBar(title: "Settings")
                }
            }
            .background(
                NavigationLink(destination: ProfileView().environmentObject(appState).environmentObject(dataStore), isActive: $navigateToProfile) { EmptyView() }
                    .hidden()
            )
            .background(
                NavigationLink(destination: NotificationsView().environmentObject(appState).environmentObject(dataStore), isActive: $navigateToNotifications) { EmptyView() }
                    .hidden()
            )
            .background(
                NavigationLink(destination: ActivityHistoryView().environmentObject(dataStore), isActive: $navigateToActivity) { EmptyView() }
                    .hidden()
            )
            .background(
                NavigationLink(destination: CalendarScheduleView().environmentObject(appState).environmentObject(dataStore), isActive: $navigateToCalendar) { EmptyView() }
                    .hidden()
            )
            .background(
                NavigationLink(destination: ReportsView().environmentObject(dataStore), isActive: $navigateToReports) { EmptyView() }
                    .hidden()
            )
            .alert("Log Out", isPresented: $showLogOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    appState.logOut()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Delete Account", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showDeleteFinalConfirm = true
                }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
            .alert("Confirm Deletion", isPresented: $showDeleteFinalConfirm) {
                TextField("Type DELETE to confirm", text: $deletionText)
                Button("Cancel", role: .cancel) { deletionText = "" }
                Button("Delete Forever", role: .destructive) {
                    if deletionText.uppercased() == "DELETE" {
                        appState.deleteAccount()
                    }
                    deletionText = ""
                }
            } message: {
                Text("Type DELETE in all caps to permanently delete your account.")
            }
        }
    }

    // MARK: Profile Header

    private var profileHeaderCard: some View {
        Button(action: { navigateToProfile = true }) {
            BICard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.biOrangeGradient)
                            .frame(width: 56, height: 56)
                        Text(appState.currentUser?.name.prefix(1).uppercased() ?? "U")
                            .font(BIFont.display(16))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.currentUser?.name ?? "User")
                            .font(BIFont.headline(13))
                            .foregroundColor(.biDark)
                        Text(appState.currentUser?.email ?? "")
                            .font(BIFont.caption(11))
                            .foregroundColor(.biMidGray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.biMidGray)
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill", iconColor: .biPurple) {
            VStack(spacing: 0) {
                ThemePickerRow(currentTheme: appState.appTheme) { theme in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        appState.setTheme(theme)
                    }
                }
            }
        }
    }

    // MARK: Units

    private var unitsSection: some View {
        SettingsSection(title: "Measurements", icon: "ruler.fill", iconColor: .biBlue) {
            VStack(spacing: 0) {
                UnitSystemRow(current: appState.unitSystem) { unit in
                    appState.setUnitSystem(unit)
                }
            }
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: .biMedium) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Enable Notifications",
                    subtitle: "Receive inspection reminders",
                    isOn: Binding(
                        get: { appState.notificationsEnabled },
                        set: { appState.setNotifications($0) }
                    )
                )

                if appState.notificationsEnabled {
                    Divider().padding(.horizontal, 16)

                    SettingsStepperRow(
                        title: "Remind Before",
                        subtitle: "Days before inspection due",
                        value: Binding(
                            get: { appState.reminderDays },
                            set: { appState.setReminderDays($0) }
                        ),
                        range: 1...14,
                        unit: "days"
                    )

                    Divider().padding(.horizontal, 16)

                    SettingsNavigationRow(title: "Notification Schedule", subtitle: "View upcoming reminders", icon: "calendar.badge.clock") {
                        navigateToNotifications = true
                    }
                }
            }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        SettingsSection(title: "Data & Reports", icon: "chart.bar.fill", iconColor: .biLow) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Auto Backup",
                    subtitle: "Save data automatically",
                    isOn: Binding(
                        get: { appState.autoBackup },
                        set: { appState.setAutoBackup($0) }
                    )
                )

                Divider().padding(.horizontal, 16)

                SettingsNavigationRow(title: "Reports", subtitle: "Analytics and crack growth", icon: "chart.line.uptrend.xyaxis") {
                    navigateToReports = true
                }

                Divider().padding(.horizontal, 16)

                SettingsNavigationRow(title: "Activity History", subtitle: "All recorded actions", icon: "clock.arrow.circlepath") {
                    navigateToActivity = true
                }

                Divider().padding(.horizontal, 16)

                SettingsNavigationRow(title: "Calendar", subtitle: "Inspection schedule", icon: "calendar") {
                    navigateToCalendar = true
                }
            }
        }
    }

    // MARK: Account

    private var accountSection: some View {
        VStack(spacing: 12) {
            // Log Out
            Button(action: { showLogOutConfirm = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Log Out")
                        .font(BIFont.body(13))
                    Spacer()
                }
                .foregroundColor(.biOrange)
                .padding(16)
                .background(Color.biSurface)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())

            // Delete Account
            Button(action: { showDeleteConfirm = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Delete Account")
                        .font(BIFont.body(12))
                    Spacer()
                    Text("Permanent")
                        .font(BIFont.caption(11))
                        .foregroundColor(.biHigh.opacity(0.7))
                }
                .foregroundColor(.biHigh)
                .padding(16)
                .background(Color.biSurface)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())

            Text("Build Inspect v1.0.0")
                .font(BIFont.caption(11))
                .foregroundColor(.biMidGray)
                .padding(.top, 4)
        }
    }
}

// MARK: - Settings Section Container

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.biMidGray)
                    .tracking(0.8)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.biSurface)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Theme Picker Row

struct ThemePickerRow: View {
    let currentTheme: AppTheme
    let onSelect: (AppTheme) -> Void
    @State private var selected: AppTheme

    init(currentTheme: AppTheme, onSelect: @escaping (AppTheme) -> Void) {
        self.currentTheme = currentTheme
        self.onSelect = onSelect
        _selected = State(initialValue: currentTheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("App Theme")
                    .font(BIFont.body(11))
                    .foregroundColor(.biDark)
                Spacer()
                Text(selected.displayName)
                    .font(BIFont.caption(11))
                    .foregroundColor(.biMidGray)
            }

            HStack(spacing: 8) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    ThemeOptionButton(theme: theme, isSelected: selected == theme) {
                        selected = theme
                        onSelect(theme)
                    }
                }
            }
        }
        .padding(16)
    }
}

struct ThemeOptionButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themePreviewBackground)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.biOrange : Color.biMidGray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )

                    HStack(spacing: 4) {
                        Circle().fill(themePreviewDot).frame(width: 8, height: 8)
                        RoundedRectangle(cornerRadius: 2).fill(themePreviewLine).frame(height: 6)
                    }
                    .padding(.horizontal, 8)

                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.biOrange)
                                    .background(Circle().fill(Color.biSurface).padding(1))
                                    .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                    }
                }

                Text(theme.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .biOrange : .biMidGray)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(ScaleButtonStyle())
    }

    private var themePreviewBackground: Color {
        switch theme {
        case .light: return Color.white
        case .dark: return Color(hex: "#1A1614")
        case .system: return Color(hex: "#F0EDE8")
        }
    }

    private var themePreviewDot: Color {
        switch theme {
        case .light: return Color.biOrange
        case .dark: return Color.biOrange
        case .system: return Color.biBlue
        }
    }

    private var themePreviewLine: Color {
        switch theme {
        case .light: return Color.biMidGray.opacity(0.3)
        case .dark: return Color.white.opacity(0.2)
        case .system: return Color.biMidGray.opacity(0.3)
        }
    }
}

extension AppTheme {
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    static var allCases: [AppTheme] { [.light, .dark, .system] }
}

// MARK: - Unit System Row

struct UnitSystemRow: View {
    let current: UnitSystem
    let onSelect: (UnitSystem) -> Void
    @State private var selected: UnitSystem

    init(current: UnitSystem, onSelect: @escaping (UnitSystem) -> Void) {
        self.current = current
        self.onSelect = onSelect
        _selected = State(initialValue: current)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Measurement Units")
                    .font(BIFont.body(12))
                    .foregroundColor(.biDark)
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach([UnitSystem.metric, UnitSystem.imperial], id: \.self) { unit in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = unit
                            onSelect(unit)
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text(unit.rawValue.capitalized)
                                .font(BIFont.body(12))
                                .foregroundColor(selected == unit ? Color.white : Color.biMidGray)
                            Text(unit == .metric ? "mm / cm / m" : "in / ft")
                                .font(.system(size: 10))
                                .foregroundColor(selected == unit ? Color.white.opacity(0.8) : Color.biMidGray.opacity(0.6))
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selected == unit ? Color.biOrange : Color.clear)
                        .cornerRadius(selected == unit ? 8 : 0)
                    }
                }
            }
            .padding(3)
            .background(Color.biBackground)
            .cornerRadius(10)
        }
        .padding(16)
    }
}

// MARK: - Reusable Setting Rows

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BIFont.body(12))
                    .foregroundColor(.biDark)
                Text(subtitle)
                    .font(BIFont.caption(11))
                    .foregroundColor(.biMidGray)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.biOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsStepperRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BIFont.body(12))
                    .foregroundColor(.biDark)
                Text(subtitle)
                    .font(BIFont.caption(11))
                    .foregroundColor(.biMidGray)
            }
            Spacer()
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            value -= 1
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? .biOrange : .biMidGray.opacity(0.3))
                }

                Text("\(value)")
                    .font(BIFont.headline(13))
                    .foregroundColor(.biDark)
                    .frame(minWidth: 28, alignment: .center)

                Button(action: {
                    if value < range.upperBound {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            value += 1
                        }
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? .biOrange : .biMidGray.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BIFont.body(13))
                        .foregroundColor(.biDark)
                    Text(subtitle)
                        .font(BIFont.caption(11))
                        .foregroundColor(.biMidGray)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.biMidGray)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.biMidGray.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
