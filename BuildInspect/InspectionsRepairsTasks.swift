import SwiftUI

// MARK: - Inspections View
struct InspectionsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAdd = false
    let buildingId: String?
    
    var inspections: [Inspection] {
        let all = buildingId != nil ? dataStore.inspections(for: buildingId!) : dataStore.inspections.sorted { $0.date > $1.date }
        return all
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    BINavBar(title: "Inspections", trailingAction: { showAdd = true }, trailingIcon: "plus")
                    
                    if inspections.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "shield.slash",
                            title: "No Inspections",
                            message: "Schedule an inspection to monitor structural health",
                            actionTitle: "Add Inspection",
                            action: { showAdd = true }
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(inspections) { inspection in
                                    NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                                        InspectionRowCard(inspection: inspection)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) {
                AddInspectionView(buildingId: buildingId ?? (dataStore.buildings.first?.id ?? ""))
            }
        }
    }
}

struct InspectionRowCard: View {
    @EnvironmentObject var dataStore: DataStore
    let inspection: Inspection
    
    var body: some View {
        BICard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.biBlue.opacity(0.1))
                        .frame(width: 46, height: 46)
                    Image(systemName: inspection.isCompleted ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                        .font(.system(size: 18))
                        .foregroundColor(.biBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let building = dataStore.building(for: inspection.buildingId) {
                        Text(building.name)
                            .font(BIFont.headline(15))
                            .foregroundColor(.biDark)
                    }
                    HStack(spacing: 8) {
                        Text(inspection.date, style: .date)
                            .font(BIFont.caption(12))
                            .foregroundColor(.biMidGray)
                        if !inspection.inspector.isEmpty {
                            Text("•")
                                .foregroundColor(.biLightGray)
                                .font(BIFont.caption(12))
                            Text(inspection.inspector)
                                .font(BIFont.caption(12))
                                .foregroundColor(.biMidGray)
                        }
                    }
                    if !inspection.notes.isEmpty {
                        Text(inspection.notes)
                            .font(BIFont.caption(12))
                            .foregroundColor(.biMidGray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    SeverityBadge(severity: inspection.overallSeverity)
                    Text(inspection.isCompleted ? "Completed" : "Pending")
                        .font(BIFont.caption(10))
                        .foregroundColor(inspection.isCompleted ? .biLow : .biMedium)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.biLightGray)
            }
        }
    }
}

// MARK: - Inspection Detail
struct InspectionDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State var inspection: Inspection
    @State private var showDelete = false
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                BINavBar(title: "Inspection", onBack: { presentationMode.wrappedValue.dismiss() })
                
                ScrollView {
                    VStack(spacing: 16) {
                        BICard {
                            VStack(alignment: .leading, spacing: 14) {
                                if let building = dataStore.building(for: inspection.buildingId) {
                                    HStack {
                                        Text(building.name)
                                            .font(BIFont.display(18))
                                            .foregroundColor(.biDark)
                                        Spacer()
                                        SeverityBadge(severity: inspection.overallSeverity)
                                    }
                                }
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Date")
                                            .font(BIFont.caption(11))
                                            .foregroundColor(.biMidGray)
                                        Text(inspection.date, style: .date)
                                            .font(BIFont.headline(14))
                                            .foregroundColor(.biDark)
                                    }
                                    if !inspection.inspector.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Inspector")
                                                .font(BIFont.caption(11))
                                                .foregroundColor(.biMidGray)
                                            Text(inspection.inspector)
                                                .font(BIFont.headline(14))
                                                .foregroundColor(.biDark)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Cracks")
                                            .font(BIFont.caption(11))
                                            .foregroundColor(.biMidGray)
                                        Text("\(inspection.crackIds.count)")
                                            .font(BIFont.headline(14))
                                            .foregroundColor(.biDark)
                                    }
                                }
                                
                                if !inspection.notes.isEmpty {
                                    Divider()
                                    Text(inspection.notes)
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Mark as completed")
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biDark)
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { inspection.isCompleted },
                                        set: { val in
                                            inspection.isCompleted = val
                                            dataStore.updateInspection(inspection)
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .biLow))
                                }
                                
                                Button(action: { showDelete = true }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete Inspection")
                                    }
                                    .font(BIFont.headline(14))
                                    .foregroundColor(.biHigh)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.biHigh.opacity(0.08))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Related cracks
                        if !inspection.crackIds.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Inspected Cracks")
                                    .font(BIFont.headline(15))
                                    .foregroundColor(.biDark)
                                    .padding(.horizontal, 20)
                                
                                ForEach(inspection.crackIds, id: \.self) { id in
                                    if let crack = dataStore.crack(for: id) {
                                        NavigationLink(destination: CrackDetailView(crack: crack)) {
                                            CrackRowCard(crack: crack)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 4)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showDelete) {
            Alert(
                title: Text("Delete Inspection?"),
                primaryButton: .destructive(Text("Delete")) {
                    dataStore.deleteInspection(inspection)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Add Inspection
struct AddInspectionView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    let buildingId: String
    
    @State private var date = Date()
    @State private var notes = ""
    @State private var inspector = ""
    @State private var severity: Severity = .low
    @State private var selectedCrackIds: Set<String> = []
    
    var buildingCracks: [Crack] { dataStore.cracks(for: buildingId) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Inspector Name")
                            BITextField(placeholder: "Your name", text: $inspector, icon: "person.fill")
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Date")
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(Color.biSurface)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("Overall Severity")
                            HStack(spacing: 10) {
                                ForEach(Severity.allCases, id: \.self) { s in
                                    Button(action: { severity = s }) {
                                        Text(s.rawValue)
                                            .font(BIFont.caption(12))
                                            .foregroundColor(severity == s ? .white : s.color)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(severity == s ? s.color : s.color.opacity(0.08))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        if !buildingCracks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                FormLabel("Cracks Inspected")
                                ForEach(buildingCracks) { crack in
                                    Button(action: {
                                        if selectedCrackIds.contains(crack.id) {
                                            selectedCrackIds.remove(crack.id)
                                        } else {
                                            selectedCrackIds.insert(crack.id)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: selectedCrackIds.contains(crack.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedCrackIds.contains(crack.id) ? .biOrange : .biLightGray)
                                            Text(crack.location)
                                                .font(BIFont.body(14))
                                                .foregroundColor(.biDark)
                                            Spacer()
                                            SeverityBadge(severity: crack.severity)
                                        }
                                        .padding(12)
                                        .background(Color.biSurface)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Notes")
                            BITextField(placeholder: "Inspection notes...", text: $notes, icon: "doc.text.fill")
                        }
                        
                        BIPrimaryButton(title: "Save Inspection", icon: "shield.fill") { save() }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Inspection")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func save() {
        var inspection = Inspection(buildingId: buildingId, date: date, notes: notes, inspector: inspector, overallSeverity: severity, crackIds: Array(selectedCrackIds))
        dataStore.addInspection(inspection)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Repairs View
struct RepairsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAdd = false
    @State private var filterStatus: RepairStatus? = nil
    
    var filtered: [Repair] {
        if let status = filterStatus {
            return dataStore.repairs.filter { $0.status == status }
        }
        return dataStore.repairs
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    BINavBar(title: "Repairs", trailingAction: { showAdd = true }, trailingIcon: "plus")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                            ForEach(RepairStatus.allCases, id: \.self) { s in
                                FilterChip(label: s.rawValue, isSelected: filterStatus == s, color: s.color) {
                                    filterStatus = filterStatus == s ? nil : s
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)
                    
                    if filtered.isEmpty {
                        Spacer()
                        EmptyStateView(icon: "wrench.and.screwdriver", title: "No Repairs", message: "Plan and track crack repairs",
                                       actionTitle: "Add Repair", action: { showAdd = true })
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { repair in
                                    NavigationLink(destination: RepairDetailView(repair: repair)) {
                                        RepairRowCard(repair: repair)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) {
                AddRepairView(buildingId: dataStore.buildings.first?.id ?? "")
            }
        }
    }
}

struct RepairRowCard: View {
    @EnvironmentObject var dataStore: DataStore
    let repair: Repair
    
    var body: some View {
        BICard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(repair.status.color.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "wrench.fill")
                        .font(.system(size: 18))
                        .foregroundColor(repair.status.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(repair.repairType.rawValue)
                        .font(BIFont.headline(15))
                        .foregroundColor(.biDark)
                    if let building = dataStore.building(for: repair.buildingId) {
                        Text(building.name)
                            .font(BIFont.caption(12))
                            .foregroundColor(.biMidGray)
                    }
                    HStack(spacing: 8) {
                        Text(String(format: "$%.0f", repair.cost))
                            .font(BIFont.mono(13))
                            .foregroundColor(.biDark)
                        if !repair.contractor.isEmpty {
                            Text("• \(repair.contractor)")
                                .font(BIFont.caption(12))
                                .foregroundColor(.biMidGray)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(repair.status.rawValue)
                        .font(BIFont.caption(11))
                        .foregroundColor(repair.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(repair.status.color.opacity(0.1))
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.biLightGray)
                }
            }
        }
    }
}

// MARK: - Repair Detail
struct RepairDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State var repair: Repair
    @State private var showDelete = false
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                BINavBar(title: "Repair Details", onBack: { presentationMode.wrappedValue.dismiss() })
                
                ScrollView {
                    VStack(spacing: 16) {
                        BICard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text(repair.repairType.rawValue)
                                        .font(BIFont.display(18))
                                        .foregroundColor(.biDark)
                                    Spacer()
                                    Text(repair.status.rawValue)
                                        .font(BIFont.caption(12))
                                        .foregroundColor(repair.status.color)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(repair.status.color.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                Divider()
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Cost")
                                            .font(BIFont.caption(11))
                                            .foregroundColor(.biMidGray)
                                        Text(String(format: "$%.2f", repair.cost))
                                            .font(BIFont.mono(16))
                                            .foregroundColor(.biDark)
                                    }
                                    if let date = repair.scheduledDate {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Scheduled")
                                                .font(BIFont.caption(11))
                                                .foregroundColor(.biMidGray)
                                            Text(date, style: .date)
                                                .font(BIFont.headline(14))
                                                .foregroundColor(.biDark)
                                        }
                                    }
                                    if !repair.contractor.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Contractor")
                                                .font(BIFont.caption(11))
                                                .foregroundColor(.biMidGray)
                                            Text(repair.contractor)
                                                .font(BIFont.headline(14))
                                                .foregroundColor(.biDark)
                                        }
                                    }
                                }
                                
                                if !repair.notes.isEmpty {
                                    Text(repair.notes)
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                }
                                
                                Divider()
                                
                                // Status update
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Update Status")
                                        .font(BIFont.headline(14))
                                        .foregroundColor(.biDark)
                                    HStack(spacing: 8) {
                                        ForEach(RepairStatus.allCases, id: \.self) { s in
                                            Button(action: {
                                                repair.status = s
                                                dataStore.updateRepair(repair)
                                            }) {
                                                Text(s.rawValue)
                                                    .font(BIFont.caption(11))
                                                    .foregroundColor(repair.status == s ? .white : s.color)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 6)
                                                    .background(repair.status == s ? s.color : s.color.opacity(0.1))
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                
                                Button(action: { showDelete = true }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete Repair")
                                    }
                                    .font(BIFont.headline(14))
                                    .foregroundColor(.biHigh)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.biHigh.opacity(0.08))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 4)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showDelete) {
            Alert(
                title: Text("Delete Repair?"),
                primaryButton: .destructive(Text("Delete")) {
                    dataStore.deleteRepair(repair)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Add Repair
struct AddRepairView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    let buildingId: String
    
    @State private var repairType: RepairType = .epoxy
    @State private var cost = ""
    @State private var contractor = ""
    @State private var scheduledDate = Date()
    @State private var hasScheduledDate = false
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Repair Type")
                            Picker("", selection: $repairType) {
                                ForEach(RepairType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                            .background(Color.biSurface)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Estimated Cost ($)")
                            BITextField(placeholder: "e.g. 500", text: $cost, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Contractor (optional)")
                            BITextField(placeholder: "Contractor name", text: $contractor, icon: "person.fill.badge.plus")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                FormLabel("Schedule Date")
                                Spacer()
                                Toggle("", isOn: $hasScheduledDate)
                                    .toggleStyle(SwitchToggleStyle(tint: .biOrange))
                            }
                            if hasScheduledDate {
                                DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .padding(12)
                                    .background(Color.biSurface)
                                    .cornerRadius(12)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Notes")
                            BITextField(placeholder: "Repair notes...", text: $notes, icon: "doc.text.fill")
                        }
                        
                        BIPrimaryButton(title: "Add Repair", icon: "wrench.fill") { save() }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Repair")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func save() {
        let repair = Repair(
            buildingId: buildingId,
            repairType: repairType,
            cost: Double(cost) ?? 0,
            scheduledDate: hasScheduledDate ? scheduledDate : nil,
            notes: notes,
            contractor: contractor
        )
        dataStore.addRepair(repair)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAdd = false
    @State private var showCompleted = false
    
    var tasks: [InspectionTask] {
        dataStore.tasks
            .filter { showCompleted ? true : !$0.isCompleted }
            .sorted { $0.priority.sortOrder > $1.priority.sortOrder }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    BINavBar(title: "Tasks", trailingAction: { showAdd = true }, trailingIcon: "plus")
                    
                    HStack {
                        Spacer()
                        Button(action: { withAnimation { showCompleted.toggle() } }) {
                            HStack(spacing: 4) {
                                Image(systemName: showCompleted ? "eye.slash" : "eye")
                                    .font(.system(size: 12))
                                Text(showCompleted ? "Hide Done" : "Show Done")
                                    .font(BIFont.caption(13))
                            }
                            .foregroundColor(.biMidGray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    
                    if tasks.isEmpty {
                        Spacer()
                        EmptyStateView(icon: "checklist", title: "All Caught Up!", message: "No pending tasks. Add a task to get organized.",
                                       actionTitle: "Add Task", action: { showAdd = true })
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(tasks) { task in
                                    TaskRowCard(task: task)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
    }
}

struct TaskRowCard: View {
    @EnvironmentObject var dataStore: DataStore
    @State var task: InspectionTask
    @State private var showDelete = false
    
    var body: some View {
        BICard {
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        task.isCompleted.toggle()
                        dataStore.updateTask(task)
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(task.isCompleted ? Color.biLow : task.priority.color, lineWidth: 2)
                            .frame(width: 26, height: 26)
                        if task.isCompleted {
                            Circle()
                                .fill(Color.biLow)
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(BIFont.headline(14))
                        .foregroundColor(task.isCompleted ? .biMidGray : .biDark)
                        .strikethrough(task.isCompleted)
                    HStack(spacing: 8) {
                        if let due = task.dueDate {
                            Text(due.formatted())
                                .font(BIFont.caption(11))
                                .foregroundColor(due < Date() && !task.isCompleted ? .biHigh : .biMidGray)
                        }
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(BIFont.caption(11))
                                .foregroundColor(.biMidGray)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                SeverityBadge(severity: task.priority)
                
                Button(action: { showDelete = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.biLightGray)
                }
            }
        }
        .alert(isPresented: $showDelete) {
            Alert(
                title: Text("Delete Task?"),
                primaryButton: .destructive(Text("Delete")) { dataStore.deleteTask(task) },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var priority: Severity = .medium
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Task Title *")
                            BITextField(placeholder: "e.g. Inspect basement crack", text: $title, icon: "checklist")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("Priority")
                            HStack(spacing: 10) {
                                ForEach(Severity.allCases, id: \.self) { s in
                                    Button(action: { priority = s }) {
                                        Text(s.rawValue)
                                            .font(BIFont.caption(12))
                                            .foregroundColor(priority == s ? .white : s.color)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(priority == s ? s.color : s.color.opacity(0.08))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                FormLabel("Due Date")
                                Spacer()
                                Toggle("", isOn: $hasDueDate)
                                    .toggleStyle(SwitchToggleStyle(tint: .biOrange))
                            }
                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .padding(12)
                                    .background(Color.biSurface)
                                    .cornerRadius(12)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Notes")
                            BITextField(placeholder: "Additional notes...", text: $notes, icon: "note.text")
                        }
                        
                        if showError {
                            Text("Task title is required").font(BIFont.body(14)).foregroundColor(.biHigh)
                        }
                        
                        BIPrimaryButton(title: "Add Task", icon: "plus") { save() }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Task")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func save() {
        guard !title.isEmpty else { showError = true; return }
        let task = InspectionTask(title: title, notes: notes, dueDate: hasDueDate ? dueDate : nil, priority: priority)
        dataStore.addTask(task)
        presentationMode.wrappedValue.dismiss()
    }
}
