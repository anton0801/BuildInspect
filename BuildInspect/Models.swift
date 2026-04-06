import Foundation
import SwiftUI

// MARK: - User Model
struct BIUser: Codable {
    var id: String
    var name: String
    var email: String
    var createdAt: Date
    
    static func empty() -> BIUser {
        BIUser(id: UUID().uuidString, name: "", email: "", createdAt: Date())
    }
}

// MARK: - Building Model
struct Building: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var address: String
    var conditionScore: Int  // 0-100
    var createdAt: Date = Date()
    var notes: String = ""
    
    var conditionLabel: String {
        switch conditionScore {
        case 80...100: return "Good"
        case 60..<80: return "Fair"
        case 40..<60: return "Poor"
        default: return "Critical"
        }
    }
    
    var conditionColor: Color {
        switch conditionScore {
        case 80...100: return .biLow
        case 60..<80: return .biMedium
        case 40..<60: return .biHigh
        default: return .biCritical
        }
    }
}

// MARK: - Room Model
struct Room: Identifiable, Codable {
    var id: String = UUID().uuidString
    var buildingId: String
    var name: String
    var area: Double  // m²
    var createdAt: Date = Date()
    var notes: String = ""
}

// MARK: - Crack Model
struct Crack: Identifiable, Codable {
    var id: String = UUID().uuidString
    var buildingId: String
    var roomId: String?
    var location: String
    var type: CrackType
    var severity: Severity
    var description: String = ""
    var createdAt: Date = Date()
    var photoIds: [String] = []
    var isResolved: Bool = false
}

enum CrackType: String, CaseIterable, Codable {
    case hairline = "Hairline"
    case structural = "Structural"
    case settlement = "Settlement"
    case shrinkage = "Shrinkage"
    case corrosion = "Corrosion"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .hairline: return "line.diagonal"
        case .structural: return "building.2"
        case .settlement: return "arrow.down.to.line"
        case .shrinkage: return "arrow.left.and.right"
        case .corrosion: return "drop.fill"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - Measurement Model
struct Measurement: Identifiable, Codable {
    var id: String = UUID().uuidString
    var crackId: String
    var width: Double   // mm
    var length: Double  // cm
    var depth: Double?  // mm
    var date: Date = Date()
    var notes: String = ""
    var photoId: String?
}

// MARK: - Photo Model
struct CrackPhoto: Identifiable, Codable {
    var id: String = UUID().uuidString
    var crackId: String?
    var buildingId: String?
    var location: String
    var imageData: Data?
    var date: Date = Date()
    var notes: String = ""
    var tag: PhotoTag = .general
}

enum PhotoTag: String, CaseIterable, Codable {
    case general = "General"
    case before = "Before"
    case after = "After"
    case progress = "Progress"
    case closeUp = "Close-up"
}

// MARK: - Inspection Model
struct Inspection: Identifiable, Codable {
    var id: String = UUID().uuidString
    var buildingId: String
    var date: Date
    var notes: String = ""
    var inspector: String = ""
    var overallSeverity: Severity = .low
    var crackIds: [String] = []
    var isCompleted: Bool = false
}

// MARK: - Repair Model
struct Repair: Identifiable, Codable {
    var id: String = UUID().uuidString
    var buildingId: String
    var crackId: String?
    var repairType: RepairType
    var cost: Double
    var scheduledDate: Date?
    var completedDate: Date?
    var notes: String = ""
    var status: RepairStatus = .planned
    var contractor: String = ""
}

enum RepairType: String, CaseIterable, Codable {
    case epoxy = "Epoxy Injection"
    case sealant = "Sealant"
    case patching = "Patching"
    case reinforcement = "Reinforcement"
    case underpinning = "Underpinning"
    case waterproofing = "Waterproofing"
    case cosmetic = "Cosmetic"
    case other = "Other"
}

enum RepairStatus: String, CaseIterable, Codable {
    case planned = "Planned"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .planned: return .biBlue
        case .inProgress: return .biMedium
        case .completed: return .biLow
        case .cancelled: return .biMidGray
        }
    }
}

// MARK: - Task Model
struct InspectionTask: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var notes: String = ""
    var dueDate: Date?
    var crackId: String?
    var buildingId: String?
    var isCompleted: Bool = false
    var priority: Severity = .medium
    var createdAt: Date = Date()
}

// MARK: - Activity Model
struct ActivityItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: ActivityType
    var title: String
    var subtitle: String = ""
    var date: Date = Date()
    var relatedId: String = ""
}

enum ActivityType: String, Codable {
    case crackAdded = "crack_added"
    case measurementAdded = "measurement_added"
    case inspectionCompleted = "inspection_completed"
    case repairScheduled = "repair_scheduled"
    case repairCompleted = "repair_completed"
    case photoAdded = "photo_added"
    case taskCompleted = "task_completed"
    case buildingAdded = "building_added"
    
    var icon: String {
        switch self {
        case .crackAdded: return "exclamationmark.triangle.fill"
        case .measurementAdded: return "ruler.fill"
        case .inspectionCompleted: return "checkmark.shield.fill"
        case .repairScheduled: return "wrench.fill"
        case .repairCompleted: return "checkmark.circle.fill"
        case .photoAdded: return "camera.fill"
        case .taskCompleted: return "checklist"
        case .buildingAdded: return "building.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .crackAdded: return .biHigh
        case .measurementAdded: return .biBlue
        case .inspectionCompleted: return .biLow
        case .repairScheduled: return .biMedium
        case .repairCompleted: return .biLow
        case .photoAdded: return .biPurple
        case .taskCompleted: return .biLow
        case .buildingAdded: return .biOrange
        }
    }
}

// MARK: - App Settings
struct AppSettings: Codable {
    var unitSystem: UnitSystem = .metric
    var notificationsEnabled: Bool = true
    var reminderDays: Int = 7
    var theme: AppTheme = .system
    var defaultSeverity: Severity = .medium
    var autoBackup: Bool = true
}

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "Metric (mm/cm)"
    case imperial = "Imperial (in/ft)"
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Notification Models
struct ScheduledReminder: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var body: String
    var date: Date
    var relatedId: String = ""
    var type: ReminderType
}

enum ReminderType: String, Codable {
    case inspection = "inspection"
    case repair = "repair"
    case task = "task"
    case measurement = "measurement"
}
