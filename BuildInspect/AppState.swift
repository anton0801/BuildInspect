import SwiftUI
import UserNotifications
import Combine

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: BIUser? = nil
    @Published var hasCompletedOnboarding: Bool = false
    @Published var appTheme: AppTheme = .system
    @Published var unitSystem: UnitSystem = .metric
    @Published var notificationsEnabled: Bool = true
    @Published var reminderDays: Int = 7
    @Published var autoBackup: Bool = true
    
    private let defaults = UserDefaults.standard
    
    init() {
        loadState()
    }
    
    // MARK: - Auth
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            completion(false, "All fields are required"); return
        }
        guard email.contains("@") && email.contains(".") else {
            completion(false, "Please enter a valid email"); return
        }
        guard password.count >= 6 else {
            completion(false, "Password must be at least 6 characters"); return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let user = BIUser(id: UUID().uuidString, name: name, email: email, createdAt: Date())
            self.currentUser = user
            self.saveUser(user)
            self.isAuthenticated = true
            self.defaults.set(true, forKey: "isAuthenticated")
            self.defaults.set(email, forKey: "userEmail")
            self.defaults.set(name, forKey: "userName")
            self.defaults.set(user.id, forKey: "userId")
            completion(true, "")
        }
    }
    
    func logIn(email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        guard !email.isEmpty, !password.isEmpty else {
            completion(false, "Email and password required"); return
        }
        guard email.contains("@") else {
            completion(false, "Invalid email format"); return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let savedEmail = self.defaults.string(forKey: "userEmail") ?? ""
            // For demo: accept any valid email/password combo, or check if matches saved
            if !savedEmail.isEmpty && savedEmail != email {
                completion(false, "No account found for this email"); return
            }
            guard password.count >= 6 else {
                completion(false, "Incorrect password"); return
            }
            
            let userId = self.defaults.string(forKey: "userId") ?? UUID().uuidString
            let name = self.defaults.string(forKey: "userName") ?? "User"
            let user = BIUser(id: userId, name: name, email: email, createdAt: Date())
            self.currentUser = user
            self.saveUser(user)
            self.isAuthenticated = true
            self.defaults.set(true, forKey: "isAuthenticated")
            completion(true, "")
        }
    }
    
    func logOut() {
        isAuthenticated = false
        defaults.set(false, forKey: "isAuthenticated")
    }
    
    func deleteAccount() {
        DataStore.shared.clearAllData()
        currentUser = nil
        isAuthenticated = false
        hasCompletedOnboarding = false
        defaults.removeObject(forKey: "isAuthenticated")
        defaults.removeObject(forKey: "userEmail")
        defaults.removeObject(forKey: "userName")
        defaults.removeObject(forKey: "userId")
        defaults.removeObject(forKey: "savedUser")
        defaults.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    func updateProfile(name: String, email: String) {
        guard var user = currentUser else { return }
        user.name = name
        user.email = email
        currentUser = user
        saveUser(user)
        defaults.set(name, forKey: "userName")
        defaults.set(email, forKey: "userEmail")
    }
    
    // MARK: - Settings
    func setTheme(_ theme: AppTheme) {
        appTheme = theme
        defaults.set(theme.rawValue, forKey: "appTheme")
    }
    
    func setUnitSystem(_ system: UnitSystem) {
        unitSystem = system
        defaults.set(system.rawValue, forKey: "unitSystem")
    }
    
    func setNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        defaults.set(enabled, forKey: "notificationsEnabled")
        if enabled {
            requestNotificationPermission()
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    func setReminderDays(_ days: Int) {
        reminderDays = days
        defaults.set(days, forKey: "reminderDays")
    }
    
    func setAutoBackup(_ enabled: Bool) {
        autoBackup = enabled
        defaults.set(enabled, forKey: "autoBackup")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                    self.defaults.set(false, forKey: "notificationsEnabled")
                }
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, date: Date, identifier: String) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Persistence
    private func saveUser(_ user: BIUser) {
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: "savedUser")
        }
    }
    
    private func loadState() {
        isAuthenticated = defaults.bool(forKey: "isAuthenticated")
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        
        if let data = defaults.data(forKey: "savedUser"),
           let user = try? JSONDecoder().decode(BIUser.self, from: data) {
            currentUser = user
        }
        
        if let themeRaw = defaults.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeRaw) {
            appTheme = theme
        }
        if let unitRaw = defaults.string(forKey: "unitSystem"),
           let unit = UnitSystem(rawValue: unitRaw) {
            unitSystem = unit
        }
        notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true
        reminderDays = defaults.object(forKey: "reminderDays") as? Int ?? 7
        autoBackup = defaults.object(forKey: "autoBackup") as? Bool ?? true
    }
}
