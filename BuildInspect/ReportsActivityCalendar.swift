import SwiftUI

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    
    var totalCrackGrowth: Double {
        dataStore.cracks.compactMap { dataStore.widthGrowth(for: $0.id) }.reduce(0, +)
    }
    var avgConditionScore: Int {
        guard !dataStore.buildings.isEmpty else { return 0 }
        return dataStore.buildings.map { $0.conditionScore }.reduce(0, +) / dataStore.buildings.count
    }
    var totalRepairCost: Double {
        dataStore.repairs.map { $0.cost }.reduce(0, +)
    }
    var cracksBySeverity: [(Severity, Int)] {
        Severity.allCases.map { s in (s, dataStore.cracks.filter { $0.severity == s }.count) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        BINavBar(title: "Reports", subtitle: "Analytics Overview")
                        
                        // Overview cards
                        VStack(spacing: 12) {
                            Text("Overview")
                                .font(BIFont.headline(16))
                                .foregroundColor(.biDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                ReportStatCard(value: "\(dataStore.cracks.count)", label: "Total Cracks", icon: "exclamationmark.triangle.fill", color: .biHigh)
                                ReportStatCard(value: "\(dataStore.inspections.count)", label: "Inspections", icon: "shield.fill", color: .biBlue)
                                ReportStatCard(value: "\(dataStore.repairs.count)", label: "Repairs", icon: "wrench.fill", color: .biMedium)
                            }
                            
                            HStack(spacing: 12) {
                                ReportStatCard(value: "\(avgConditionScore)%", label: "Avg Condition", icon: "percent", color: avgConditionScore >= 70 ? .biLow : avgConditionScore >= 50 ? .biMedium : .biHigh)
                                ReportStatCard(value: String(format: "$%.0f", totalRepairCost), label: "Total Repair Cost", icon: "dollarsign.circle.fill", color: .biOrange)
                                ReportStatCard(value: "\(dataStore.tasks.filter { !$0.isCompleted }.count)", label: "Open Tasks", icon: "checklist", color: .biPurple)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Cracks by severity
                        BICard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Cracks by Severity")
                                    .font(BIFont.headline(15))
                                    .foregroundColor(.biDark)
                                
                                ForEach(cracksBySeverity, id: \.0) { sev, count in
                                    VStack(spacing: 6) {
                                        HStack {
                                            HStack(spacing: 6) {
                                                Image(systemName: sev.icon)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(sev.color)
                                                Text(sev.rawValue)
                                                    .font(BIFont.body(14))
                                                    .foregroundColor(.biDark)
                                            }
                                            Spacer()
                                            Text("\(count)")
                                                .font(BIFont.mono(14))
                                                .foregroundColor(.biDark)
                                        }
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.biBackground)
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(sev.color)
                                                    .frame(width: dataStore.cracks.isEmpty ? 0 : geo.size.width * CGFloat(count) / CGFloat(max(dataStore.cracks.count, 1)), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Crack growth
                        BICard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Crack Growth Monitor")
                                    .font(BIFont.headline(15))
                                    .foregroundColor(.biDark)
                                
                                ForEach(dataStore.cracks.filter { !dataStore.measurements(for: $0.id).isEmpty }.prefix(5)) { crack in
                                    let growth = dataStore.widthGrowth(for: crack.id)
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(crack.location)
                                                .font(BIFont.body(13))
                                                .foregroundColor(.biDark)
                                                .lineLimit(1)
                                            if let latest = dataStore.latestMeasurement(for: crack.id) {
                                                Text(String(format: "Current: %.1f mm", latest.width))
                                                    .font(BIFont.caption(11))
                                                    .foregroundColor(.biMidGray)
                                            }
                                        }
                                        Spacer()
                                        HStack(spacing: 3) {
                                            Image(systemName: growth > 0 ? "arrow.up" : growth < 0 ? "arrow.down" : "minus")
                                                .font(.system(size: 10, weight: .bold))
                                            Text(String(format: "%+.1f mm", growth))
                                                .font(BIFont.mono(13))
                                        }
                                        .foregroundColor(growth > 0 ? .biHigh : growth < 0 ? .biLow : .biMidGray)
                                    }
                                    if crack.id != dataStore.cracks.last?.id {
                                        Divider()
                                    }
                                }
                                
                                if dataStore.cracks.filter({ !dataStore.measurements(for: $0.id).isEmpty }).isEmpty {
                                    Text("Add measurements to see growth trends")
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Buildings overview
                        BICard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Building Condition")
                                    .font(BIFont.headline(15))
                                    .foregroundColor(.biDark)
                                
                                ForEach(dataStore.buildings) { building in
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(building.name)
                                                .font(BIFont.body(13))
                                                .foregroundColor(.biDark)
                                            Text("\(dataStore.cracks(for: building.id).count) cracks")
                                                .font(BIFont.caption(11))
                                                .foregroundColor(.biMidGray)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 3).fill(Color.biBackground)
                                                    RoundedRectangle(cornerRadius: 3).fill(building.conditionColor)
                                                        .frame(width: geo.size.width * CGFloat(building.conditionScore) / 100)
                                                }
                                            }
                                            .frame(width: 80, height: 6)
                                            Text("\(building.conditionScore)")
                                                .font(BIFont.mono(13))
                                                .foregroundColor(building.conditionColor)
                                        }
                                    }
                                }
                                
                                if dataStore.buildings.isEmpty {
                                    Text("No buildings added yet")
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ReportStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.biDark)
            Text(label)
                .font(BIFont.caption(10))
                .foregroundColor(.biMidGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.biSurface)
        .cornerRadius(12)
        .shadow(color: Color.biDark.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    BINavBar(title: "Activity History")
                    
                    if dataStore.activities.isEmpty {
                        Spacer()
                        EmptyStateView(icon: "clock.fill", title: "No Activity", message: "Your actions will appear here")
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(dataStore.activities) { activity in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(activity.type.color.opacity(0.12))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: activity.type.icon)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(activity.type.color)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(activity.title)
                                                .font(BIFont.headline(14))
                                                .foregroundColor(.biDark)
                                            if !activity.subtitle.isEmpty {
                                                Text(activity.subtitle)
                                                    .font(BIFont.caption(12))
                                                    .foregroundColor(.biMidGray)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text(activity.date, style: .relative)
                                            .font(BIFont.caption(11))
                                            .foregroundColor(.biLightGray)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    
                                    Divider().padding(.leading, 74)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Calendar View
struct CalendarScheduleView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var selectedDate = Date()
    @State private var showAddInspection = false
    @State private var showAddTask = false
    
    var scheduledInspections: [Inspection] {
        dataStore.inspections.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    var scheduledTasks: [InspectionTask] {
        dataStore.tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return Calendar.current.isDate(due, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    BINavBar(title: "Calendar", subtitle: "Schedule")
                    
                    // Date picker
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.horizontal, 16)
                        .background(Color.biSurface)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .shadow(color: Color.biDark.opacity(0.05), radius: 8, y: 3)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Scheduled inspections
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    SectionHeader(title: "Inspections", icon: "shield.fill", iconColor: .biBlue)
                                    Spacer()
                                    Button(action: { showAddInspection = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.biBlue)
                                    }
                                }
                                
                                if scheduledInspections.isEmpty {
                                    Text("No inspections scheduled for this date")
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                } else {
                                    ForEach(scheduledInspections) { inspection in
                                        NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                                            InspectionRowCard(inspection: inspection)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            // Scheduled tasks
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    SectionHeader(title: "Tasks Due", icon: "checklist", iconColor: .biMedium)
                                    Spacer()
                                    Button(action: { showAddTask = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.biMedium)
                                    }
                                }
                                
                                if scheduledTasks.isEmpty {
                                    Text("No tasks due on this date")
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                } else {
                                    ForEach(scheduledTasks) { task in
                                        TaskRowCard(task: task)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddInspection) {
                AddInspectionView(buildingId: dataStore.buildings.first?.id ?? "")
            }
            .sheet(isPresented: $showAddTask) { AddTaskView() }
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var pendingNotifications: [UNNotificationRequest] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    BINavBar(title: "Notifications")
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Master toggle
                            BICard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Enable Notifications")
                                            .font(BIFont.headline(15))
                                            .foregroundColor(.biDark)
                                        Text("Get reminded about inspections and tasks")
                                            .font(BIFont.caption(12))
                                            .foregroundColor(.biMidGray)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { appState.notificationsEnabled },
                                        set: { appState.setNotifications($0) }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .biOrange))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if appState.notificationsEnabled {
                                // Upcoming reminders
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Upcoming Reminders", icon: "bell.fill", iconColor: .biOrange)
                                    
                                    // Upcoming inspections
                                    let upcomingInspections = dataStore.inspections
                                        .filter { !$0.isCompleted && $0.date > Date() }
                                        .sorted { $0.date < $1.date }
                                        .prefix(5)
                                    
                                    if upcomingInspections.isEmpty && pendingNotifications.isEmpty {
                                        BICard {
                                            EmptyStateView(icon: "bell.slash", title: "No Upcoming", message: "No scheduled reminders")
                                        }
                                    } else {
                                        ForEach(Array(upcomingInspections), id: \.id) { inspection in
                                            HStack(spacing: 12) {
                                                Image(systemName: "shield.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.biBlue)
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.biBlue.opacity(0.1))
                                                    .cornerRadius(8)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Inspection scheduled")
                                                        .font(BIFont.headline(13))
                                                        .foregroundColor(.biDark)
                                                    if let building = dataStore.building(for: inspection.buildingId) {
                                                        Text(building.name)
                                                            .font(BIFont.caption(12))
                                                            .foregroundColor(.biMidGray)
                                                    }
                                                }
                                                Spacer()
                                                Text(inspection.date, style: .date)
                                                    .font(BIFont.caption(11))
                                                    .foregroundColor(.biMidGray)
                                            }
                                            .padding(12)
                                            .background(Color.biSurface)
                                            .cornerRadius(12)
                                        }
                                        
                                        // Upcoming tasks with due dates
                                        let upcomingTasks = dataStore.tasks
                                            .filter { !$0.isCompleted && ($0.dueDate ?? Date.distantPast) > Date() }
                                            .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
                                            .prefix(5)
                                        
                                        ForEach(Array(upcomingTasks), id: \.id) { task in
                                            HStack(spacing: 12) {
                                                Image(systemName: "checklist")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.biMedium)
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.biMedium.opacity(0.1))
                                                    .cornerRadius(8)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(task.title)
                                                        .font(BIFont.headline(13))
                                                        .foregroundColor(.biDark)
                                                        .lineLimit(1)
                                                    Text("Task due")
                                                        .font(BIFont.caption(12))
                                                        .foregroundColor(.biMidGray)
                                                }
                                                Spacer()
                                                if let due = task.dueDate {
                                                    Text(due, style: .date)
                                                        .font(BIFont.caption(11))
                                                        .foregroundColor(.biMidGray)
                                                }
                                            }
                                            .padding(12)
                                            .background(Color.biSurface)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var editName = ""
    @State private var editEmail = ""
    @State private var isEditing = false
    @State private var saved = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    BINavBar(title: "Profile")
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.biOrangeGradient)
                                    .frame(width: 88, height: 88)
                                Text((appState.currentUser?.name.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 8)
                            
                            BICard {
                                VStack(spacing: 16) {
                                    if isEditing {
                                        VStack(spacing: 12) {
                                            BITextField(placeholder: "Full Name", text: $editName, icon: "person.fill")
                                            BITextField(placeholder: "Email", text: $editEmail, icon: "envelope.fill", keyboardType: .emailAddress)
                                        }
                                    } else {
                                        VStack(spacing: 8) {
                                            Text(appState.currentUser?.name ?? "")
                                                .font(BIFont.display(20))
                                                .foregroundColor(.biDark)
                                            Text(appState.currentUser?.email ?? "")
                                                .font(BIFont.body(14))
                                                .foregroundColor(.biMidGray)
                                        }
                                    }
                                    
                                    if saved {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(.biLow)
                                            Text("Profile updated!").font(BIFont.body(13)).foregroundColor(.biLow)
                                        }
                                    }
                                    
                                    Button(action: {
                                        if isEditing {
                                            appState.updateProfile(name: editName, email: editEmail)
                                            withAnimation { saved = true; isEditing = false }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                                        } else {
                                            editName = appState.currentUser?.name ?? ""
                                            editEmail = appState.currentUser?.email ?? ""
                                            isEditing = true
                                        }
                                    }) {
                                        Text(isEditing ? "Save Changes" : "Edit Profile")
                                            .font(BIFont.headline(14))
                                            .foregroundColor(isEditing ? .white : .biOrange)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(isEditing ? Color.biOrange : Color.biOrange.opacity(0.1))
                                            .cornerRadius(10)
                                    }
                                    
                                    if isEditing {
                                        Button(action: { isEditing = false }) {
                                            Text("Cancel")
                                                .font(BIFont.headline(14))
                                                .foregroundColor(.biMidGray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Stats
                            BICard {
                                HStack(spacing: 0) {
                                    ProfileStat(value: "\(dataStore_count(.buildings))", label: "Buildings")
                                    Divider().frame(height: 40)
                                    ProfileStat(value: "\(dataStore_count(.cracks))", label: "Cracks")
                                    Divider().frame(height: 40)
                                    ProfileStat(value: "\(dataStore_count(.inspections))", label: "Inspections")
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    enum StatType { case buildings, cracks, inspections }
    
    @EnvironmentObject private var dataStore: DataStore
    
    private func dataStore_count(_ type: StatType) -> Int {
        switch type {
        case .buildings: return dataStore.buildings.count
        case .cracks: return dataStore.cracks.count
        case .inspections: return dataStore.inspections.count
        }
    }
}

struct ProfileStat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.biDark)
            Text(label)
                .font(BIFont.caption(11))
                .foregroundColor(.biMidGray)
        }
        .frame(maxWidth: .infinity)
    }
}
