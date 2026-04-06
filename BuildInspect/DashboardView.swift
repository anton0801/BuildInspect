import SwiftUI

// MARK: - Main Tab Bar
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                BuildingsView()
                    .tag(1)
                CracksListView(buildingId: nil, buildingName: "All Buildings")
                    .tag(2)
                InspectionsView(buildingId: nil)
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(DefaultTabViewStyle())
            
            // Custom tab bar
            BITabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct BITabBar: View {
    @Binding var selectedTab: Int
    
    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Dashboard"),
        ("building.2.fill", "Buildings"),
        ("exclamationmark.triangle.fill", "Cracks"),
        ("shield.fill", "Inspect"),
        ("gear", "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 20, weight: selectedTab == i ? .bold : .regular))
                            .foregroundColor(selectedTab == i ? .biOrange : .biMidGray)
                            .scaleEffect(selectedTab == i ? 1.1 : 1.0)
                        
                        Text(tabs[i].label)
                            .font(.system(size: 9, weight: selectedTab == i ? .semibold : .regular, design: .rounded))
                            .foregroundColor(selectedTab == i ? .biOrange : .biMidGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.biSurface)
                .shadow(color: Color.biDark.opacity(0.1), radius: 20, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        DashboardHeader()
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : -20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)
                        
                        VStack(spacing: 20) {
                            // Stats row
                            HStack(spacing: 12) {
                                DashStatCard(
                                    value: "\(dataStore.openCracks().count)",
                                    label: "Open Cracks",
                                    icon: "exclamationmark.triangle.fill",
                                    color: .biHigh
                                )
                                DashStatCard(
                                    value: "\(dataStore.criticalCracks().count)",
                                    label: "Critical",
                                    icon: "bolt.fill",
                                    color: .biCritical
                                )
                                DashStatCard(
                                    value: "\(dataStore.buildings.count)",
                                    label: "Buildings",
                                    icon: "building.2.fill",
                                    color: .biOrange
                                )
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
                            
                            // Critical Issues
                            if !dataStore.criticalCracks().isEmpty {
                                CriticalIssuesSection()
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
                            }
                            
                            // Recent Inspections
                            RecentInspectionsSection()
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)
                            
                            // Pending Tasks
                            if !dataStore.tasks.filter({ !$0.isCompleted }).isEmpty {
                                PendingTasksSection()
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)
                            }
                            
                            // Building Overview
                            BuildingOverviewSection()
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appeared)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true } }
    }
}

struct DashboardHeader: View {
    @EnvironmentObject var appState: AppState
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(BIFont.body(14))
                    .foregroundColor(.biMidGray)
                Text(appState.currentUser?.name.components(separatedBy: " ").first ?? "Inspector")
                    .font(BIFont.display(22))
                    .foregroundColor(.biDark)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient.biOrangeGradient)
                    .frame(width: 44, height: 44)
                Text((appState.currentUser?.name.prefix(1) ?? "U").uppercased())
                    .font(BIFont.headline(18))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

struct DashStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        BICard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.biDark)
                Text(label)
                    .font(BIFont.caption(11))
                    .foregroundColor(.biMidGray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct CriticalIssuesSection: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Critical Issues", icon: "bolt.fill", iconColor: .biCritical)
            
            ForEach(dataStore.criticalCracks().prefix(3)) { crack in
                NavigationLink(destination: CrackDetailView(crack: crack)) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(crack.severity.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: crack.severity.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(crack.severity.color)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(crack.location)
                                .font(BIFont.headline(14))
                                .foregroundColor(.biDark)
                                .lineLimit(1)
                            if let building = dataStore.building(for: crack.buildingId) {
                                Text(building.name)
                                    .font(BIFont.caption(12))
                                    .foregroundColor(.biMidGray)
                            }
                        }
                        
                        Spacer()
                        
                        SeverityBadge(severity: crack.severity)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.biLightGray)
                    }
                    .padding(14)
                    .background(Color.biSurface)
                    .cornerRadius(12)
                    .shadow(color: Color.biDark.opacity(0.04), radius: 6, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct RecentInspectionsSection: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Inspections", icon: "shield.fill", iconColor: .biBlue)
            
            if dataStore.recentInspections(3).isEmpty {
                BICard {
                    EmptyStateView(
                        icon: "shield.slash",
                        title: "No Inspections Yet",
                        message: "Schedule your first inspection"
                    )
                }
            } else {
                ForEach(dataStore.recentInspections(3)) { inspection in
                    NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.biBlue.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: inspection.isCompleted ? "checkmark.shield.fill" : "shield")
                                        .font(.system(size: 16))
                                        .foregroundColor(.biBlue)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if let building = dataStore.building(for: inspection.buildingId) {
                                    Text(building.name)
                                        .font(BIFont.headline(14))
                                        .foregroundColor(.biDark)
                                }
                                Text(inspection.date, style: .date)
                                    .font(BIFont.caption(12))
                                    .foregroundColor(.biMidGray)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                SeverityBadge(severity: inspection.overallSeverity)
                                Text(inspection.isCompleted ? "Done" : "Pending")
                                    .font(BIFont.caption(11))
                                    .foregroundColor(inspection.isCompleted ? .biLow : .biMedium)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.biLightGray)
                        }
                        .padding(14)
                        .background(Color.biSurface)
                        .cornerRadius(12)
                        .shadow(color: Color.biDark.opacity(0.04), radius: 6, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct PendingTasksSection: View {
    @EnvironmentObject var dataStore: DataStore
    
    var pendingTasks: [InspectionTask] {
        dataStore.tasks.filter { !$0.isCompleted }.prefix(3).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pending Tasks", icon: "checklist", iconColor: .biMedium)
            
            ForEach(pendingTasks) { task in
                NavigationLink(destination: TasksView()) {
                    HStack(spacing: 12) {
                        Button(action: {
                            var updated = task
                            updated.isCompleted = true
                            dataStore.updateTask(updated)
                        }) {
                            Image(systemName: "circle")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(task.priority.color)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(BIFont.headline(14))
                                .foregroundColor(.biDark)
                                .lineLimit(1)
                            if let date = task.dueDate {
                                Text("Due: \(date, style: .date)")
                                    .font(BIFont.caption(12))
                                    .foregroundColor(.biMidGray)
                            }
                        }
                        
                        Spacer()
                        SeverityBadge(severity: task.priority)
                    }
                    .padding(14)
                    .background(Color.biSurface)
                    .cornerRadius(12)
                    .shadow(color: Color.biDark.opacity(0.04), radius: 6, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct BuildingOverviewSection: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Buildings", icon: "building.2.fill", iconColor: .biOrange)
            
            if dataStore.buildings.isEmpty {
                BICard {
                    EmptyStateView(
                        icon: "building.2.crop.circle",
                        title: "No Buildings",
                        message: "Add your first building to start tracking"
                    )
                }
            } else {
                ForEach(dataStore.buildings.prefix(3)) { building in
                    NavigationLink(destination: BuildingDetailView(building: building)) {
                        BuildingRowCard(building: building)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(iconColor)
            Text(title)
                .font(BIFont.headline(16))
                .foregroundColor(.biDark)
            Spacer()
        }
    }
}
