import Foundation
import Combine

class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var buildings: [Building] = []
    @Published var rooms: [Room] = []
    @Published var cracks: [Crack] = []
    @Published var measurements: [Measurement] = []
    @Published var photos: [CrackPhoto] = []
    @Published var inspections: [Inspection] = []
    @Published var repairs: [Repair] = []
    @Published var tasks: [InspectionTask] = []
    @Published var activities: [ActivityItem] = []
    
    private let defaults = UserDefaults.standard
    
    init() {
        loadAll()
        if buildings.isEmpty { seedDemoData() }
    }
    
    // MARK: - CRUD Buildings
    func addBuilding(_ building: Building) {
        buildings.append(building)
        saveBuildings()
        logActivity(.buildingAdded, title: "Building Added", subtitle: building.name, relatedId: building.id)
    }
    func updateBuilding(_ building: Building) {
        if let idx = buildings.firstIndex(where: { $0.id == building.id }) {
            buildings[idx] = building
            saveBuildings()
        }
    }
    func deleteBuilding(_ building: Building) {
        buildings.removeAll { $0.id == building.id }
        rooms.removeAll { $0.buildingId == building.id }
        cracks.removeAll { $0.buildingId == building.id }
        saveBuildings(); saveRooms(); saveCracks()
    }
    
    // MARK: - CRUD Rooms
    func addRoom(_ room: Room) {
        rooms.append(room)
        saveRooms()
    }
    func updateRoom(_ room: Room) {
        if let idx = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[idx] = room; saveRooms()
        }
    }
    func deleteRoom(_ room: Room) {
        rooms.removeAll { $0.id == room.id }
        saveRooms()
    }
    
    // MARK: - CRUD Cracks
    func addCrack(_ crack: Crack) {
        cracks.append(crack)
        saveCracks()
        logActivity(.crackAdded, title: "Crack Recorded", subtitle: crack.location, relatedId: crack.id)
    }
    func updateCrack(_ crack: Crack) {
        if let idx = cracks.firstIndex(where: { $0.id == crack.id }) {
            cracks[idx] = crack; saveCracks()
        }
    }
    func deleteCrack(_ crack: Crack) {
        cracks.removeAll { $0.id == crack.id }
        measurements.removeAll { $0.crackId == crack.id }
        saveCracks(); saveMeasurements()
    }
    
    // MARK: - CRUD Measurements
    func addMeasurement(_ m: Measurement) {
        measurements.append(m)
        saveMeasurements()
        logActivity(.measurementAdded, title: "Measurement Added", subtitle: String(format: "%.1f mm wide", m.width), relatedId: m.crackId)
    }
    func updateMeasurement(_ m: Measurement) {
        if let idx = measurements.firstIndex(where: { $0.id == m.id }) {
            measurements[idx] = m; saveMeasurements()
        }
    }
    func deleteMeasurement(_ m: Measurement) {
        measurements.removeAll { $0.id == m.id }; saveMeasurements()
    }
    
    // MARK: - CRUD Photos
    func addPhoto(_ photo: CrackPhoto) {
        photos.append(photo)
        savePhotos()
        logActivity(.photoAdded, title: "Photo Added", subtitle: photo.location, relatedId: photo.id)
    }
    func deletePhoto(_ photo: CrackPhoto) {
        photos.removeAll { $0.id == photo.id }; savePhotos()
    }
    
    // MARK: - CRUD Inspections
    func addInspection(_ inspection: Inspection) {
        inspections.append(inspection)
        saveInspections()
        logActivity(.inspectionCompleted, title: "Inspection Scheduled", subtitle: inspection.notes, relatedId: inspection.id)
    }
    func updateInspection(_ inspection: Inspection) {
        if let idx = inspections.firstIndex(where: { $0.id == inspection.id }) {
            inspections[idx] = inspection; saveInspections()
        }
    }
    func deleteInspection(_ inspection: Inspection) {
        inspections.removeAll { $0.id == inspection.id }; saveInspections()
    }
    
    // MARK: - CRUD Repairs
    func addRepair(_ repair: Repair) {
        repairs.append(repair)
        saveRepairs()
        logActivity(.repairScheduled, title: "Repair Scheduled", subtitle: repair.repairType.rawValue, relatedId: repair.id)
    }
    func updateRepair(_ repair: Repair) {
        if let idx = repairs.firstIndex(where: { $0.id == repair.id }) {
            repairs[idx] = repair; saveRepairs()
            if repair.status == .completed {
                logActivity(.repairCompleted, title: "Repair Completed", subtitle: repair.repairType.rawValue, relatedId: repair.id)
            }
        }
    }
    func deleteRepair(_ repair: Repair) {
        repairs.removeAll { $0.id == repair.id }; saveRepairs()
    }
    
    // MARK: - CRUD Tasks
    func addTask(_ task: InspectionTask) {
        tasks.append(task); saveTasks()
    }
    func updateTask(_ task: InspectionTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task; saveTasks()
            if task.isCompleted {
                logActivity(.taskCompleted, title: "Task Completed", subtitle: task.title, relatedId: task.id)
            }
        }
    }
    func deleteTask(_ task: InspectionTask) {
        tasks.removeAll { $0.id == task.id }; saveTasks()
    }
    
    // MARK: - Helpers
    func cracks(for buildingId: String) -> [Crack] {
        cracks.filter { $0.buildingId == buildingId }
    }
    func rooms(for buildingId: String) -> [Room] {
        rooms.filter { $0.buildingId == buildingId }
    }
    func measurements(for crackId: String) -> [Measurement] {
        measurements.filter { $0.crackId == crackId }.sorted { $0.date < $1.date }
    }
    func photos(for crackId: String) -> [CrackPhoto] {
        photos.filter { $0.crackId == crackId }
    }
    func inspections(for buildingId: String) -> [Inspection] {
        inspections.filter { $0.buildingId == buildingId }.sorted { $0.date > $1.date }
    }
    func openCracks() -> [Crack] {
        cracks.filter { !$0.isResolved }
    }
    func criticalCracks() -> [Crack] {
        cracks.filter { ($0.severity == .critical || $0.severity == .high) && !$0.isResolved }
    }
    func recentInspections(_ count: Int = 5) -> [Inspection] {
        inspections.sorted { $0.date > $1.date }.prefix(count).map { $0 }
    }
    func building(for id: String) -> Building? {
        buildings.first { $0.id == id }
    }
    func crack(for id: String) -> Crack? {
        cracks.first { $0.id == id }
    }
    func latestMeasurement(for crackId: String) -> Measurement? {
        measurements(for: crackId).last
    }
    func widthGrowth(for crackId: String) -> Double {
        let meas = measurements(for: crackId)
        guard meas.count >= 2, let first = meas.first, let last = meas.last else { return 0 }
        return last.width - first.width
    }
    
    // MARK: - Activity Log
    func logActivity(_ type: ActivityType, title: String, subtitle: String, relatedId: String) {
        let item = ActivityItem(type: type, title: title, subtitle: subtitle, date: Date(), relatedId: relatedId)
        activities.insert(item, at: 0)
        if activities.count > 100 { activities = Array(activities.prefix(100)) }
        saveActivities()
    }
    
    // MARK: - Clear All (for account deletion)
    func clearAllData() {
        buildings = []
        rooms = []
        cracks = []
        measurements = []
        photos = []
        inspections = []
        repairs = []
        tasks = []
        activities = []
        let keys = ["buildings","rooms","cracks","measurements","photos","inspections","repairs","tasks","activities"]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
    
    // MARK: - Persistence
    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func saveBuildings() { save(buildings, key: "buildings") }
    func saveRooms() { save(rooms, key: "rooms") }
    func saveCracks() { save(cracks, key: "cracks") }
    func saveMeasurements() { save(measurements, key: "measurements") }
    func savePhotos() { save(photos, key: "photos") }
    func saveInspections() { save(inspections, key: "inspections") }
    func saveRepairs() { save(repairs, key: "repairs") }
    func saveTasks() { save(tasks, key: "tasks") }
    func saveActivities() { save(activities, key: "activities") }
    
    func loadAll() {
        buildings = load([Building].self, key: "buildings") ?? []
        rooms = load([Room].self, key: "rooms") ?? []
        cracks = load([Crack].self, key: "cracks") ?? []
        measurements = load([Measurement].self, key: "measurements") ?? []
        photos = load([CrackPhoto].self, key: "photos") ?? []
        inspections = load([Inspection].self, key: "inspections") ?? []
        repairs = load([Repair].self, key: "repairs") ?? []
        tasks = load([InspectionTask].self, key: "tasks") ?? []
        activities = load([ActivityItem].self, key: "activities") ?? []
    }
    
    // MARK: - Demo Seed Data
    private func seedDemoData() {
        let b1 = Building(id: "b1", name: "Main Residence", address: "123 Oak Street", conditionScore: 72)
        let b2 = Building(id: "b2", name: "Workshop Garage", address: "123 Oak Street (Rear)", conditionScore: 45)
        buildings = [b1, b2]
        
        let r1 = Room(id: "r1", buildingId: "b1", name: "Living Room", area: 32)
        let r2 = Room(id: "r2", buildingId: "b1", name: "Kitchen", area: 18)
        let r3 = Room(id: "r3", buildingId: "b1", name: "Basement", area: 40)
        rooms = [r1, r2, r3]
        
        let c1 = Crack(id: "c1", buildingId: "b1", roomId: "r3", location: "North wall, basement corner", type: .structural, severity: .high, description: "Diagonal crack propagating from window corner")
        let c2 = Crack(id: "c2", buildingId: "b1", roomId: "r1", location: "Living room ceiling", type: .settlement, severity: .medium, description: "Hairline crack across ceiling plaster")
        let c3 = Crack(id: "c3", buildingId: "b2", location: "South exterior wall", type: .shrinkage, severity: .low, description: "Minor shrinkage cracks in render")
        cracks = [c1, c2, c3]
        
        let m1 = Measurement(id: "m1", crackId: "c1", width: 1.2, length: 34, date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!)
        let m2 = Measurement(id: "m2", crackId: "c1", width: 1.8, length: 37, date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
        let m3 = Measurement(id: "m3", crackId: "c1", width: 2.1, length: 40, date: Date())
        let m4 = Measurement(id: "m4", crackId: "c2", width: 0.3, length: 62, date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!)
        let m5 = Measurement(id: "m5", crackId: "c2", width: 0.4, length: 65, date: Date())
        measurements = [m1, m2, m3, m4, m5]
        
        let i1 = Inspection(id: "i1", buildingId: "b1", date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, notes: "Quarterly structural check", inspector: "John Smith", overallSeverity: .high, crackIds: ["c1","c2"], isCompleted: true)
        let i2 = Inspection(id: "i2", buildingId: "b2", date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, notes: "Annual inspection", inspector: "Jane Doe", overallSeverity: .low, crackIds: ["c3"], isCompleted: true)
        inspections = [i1, i2]
        
        let rep1 = Repair(id: "rep1", buildingId: "b1", crackId: "c1", repairType: .epoxy, cost: 850, scheduledDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()), notes: "Epoxy injection + monitoring", status: .planned, contractor: "FixPro Ltd")
        repairs = [rep1]
        
        let t1 = InspectionTask(id: "t1", title: "Re-measure basement crack", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), crackId: "c1", buildingId: "b1", priority: .high)
        let t2 = InspectionTask(id: "t2", title: "Schedule epoxy injection", dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()), buildingId: "b1", priority: .medium)
        tasks = [t1, t2]
        
        activities = [
            ActivityItem(type: .crackAdded, title: "Crack Recorded", subtitle: "North wall, basement corner", date: Calendar.current.date(byAdding: .day, value: -90, to: Date())!),
            ActivityItem(type: .measurementAdded, title: "Measurement Added", subtitle: "1.2 mm wide", date: Calendar.current.date(byAdding: .day, value: -90, to: Date())!),
            ActivityItem(type: .inspectionCompleted, title: "Inspection Completed", subtitle: "Main Residence", date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!),
            ActivityItem(type: .measurementAdded, title: "Measurement Added", subtitle: "2.1 mm wide", date: Date()),
            ActivityItem(type: .repairScheduled, title: "Repair Scheduled", subtitle: "Epoxy Injection", date: Date())
        ]
        
        saveAll()
    }
    
    private func saveAll() {
        saveBuildings(); saveRooms(); saveCracks(); saveMeasurements()
        savePhotos(); saveInspections(); saveRepairs(); saveTasks(); saveActivities()
    }
}
