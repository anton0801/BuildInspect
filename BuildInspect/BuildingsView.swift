import SwiftUI

// MARK: - Buildings List
struct BuildingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAdd = false
    @State private var searchText = ""
    @State private var appeared = false
    
    var filtered: [Building] {
        if searchText.isEmpty { return dataStore.buildings }
        return dataStore.buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    BINavBar(title: "Buildings", trailingAction: { showAdd = true }, trailingIcon: "plus")
                    
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.biMidGray)
                            .font(.system(size: 15))
                        TextField("Search buildings...", text: $searchText)
                            .font(BIFont.body(15))
                            .foregroundColor(.biDark)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.biSurface)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    if filtered.isEmpty {
                        VStack {
                            Spacer()
                            EmptyStateView(
                                icon: "building.2.crop.circle",
                                title: searchText.isEmpty ? "No Buildings Yet" : "No Results",
                                message: searchText.isEmpty ? "Add your first building to begin structural monitoring" : "Try a different search term",
                                actionTitle: searchText.isEmpty ? "Add Building" : nil,
                                action: searchText.isEmpty ? { showAdd = true } : nil
                            )
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { building in
                                    NavigationLink(destination: BuildingDetailView(building: building)) {
                                        BuildingRowCard(building: building)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 20)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(dataStore.buildings.firstIndex(where: { $0.id == building.id }) ?? 0) * 0.05), value: appeared)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddBuildingView() }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true } }
    }
}

struct BuildingRowCard: View {
    @EnvironmentObject var dataStore: DataStore
    let building: Building
    
    var crackCount: Int { dataStore.cracks(for: building.id).filter({ !$0.isResolved }).count }
    
    var body: some View {
        BICard {
            HStack(spacing: 14) {
                // Condition score ring
                ZStack {
                    Circle()
                        .stroke(Color.biDivider, lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: CGFloat(building.conditionScore) / 100)
                        .stroke(building.conditionColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(building.conditionScore)")
                        .font(BIFont.mono(13))
                        .foregroundColor(.biDark)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(BIFont.headline(16))
                        .foregroundColor(.biDark)
                    Text(building.address)
                        .font(BIFont.body(13))
                        .foregroundColor(.biMidGray)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Label("\(crackCount) cracks", systemImage: "exclamationmark.triangle.fill")
                            .font(BIFont.caption(11))
                            .foregroundColor(crackCount > 0 ? .biHigh : .biLow)
                        
                        Text("•")
                            .foregroundColor(.biLightGray)
                            .font(BIFont.caption(11))
                        
                        Text(building.conditionLabel)
                            .font(BIFont.caption(11))
                            .foregroundColor(building.conditionColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.biLightGray)
            }
        }
    }
}

// MARK: - Building Detail
struct BuildingDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State var building: Building
    @State private var showEdit = false
    @State private var showAddRoom = false
    @State private var showAddCrack = false
    @State private var showAddInspection = false
    @State private var showDeleteAlert = false
    @State private var selectedSegment = 0
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                BINavBar(
                    title: building.name,
                    subtitle: "Building",
                    onBack: { presentationMode.wrappedValue.dismiss() },
                    trailingAction: { showEdit = true },
                    trailingIcon: "pencil"
                )
                
                // Condition header card
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(building.address)
                                .font(BIFont.body(14))
                                .foregroundColor(.biMidGray)
                            HStack(spacing: 8) {
                                Text("Condition:")
                                    .font(BIFont.caption(13))
                                    .foregroundColor(.biMidGray)
                                Text(building.conditionLabel)
                                    .font(BIFont.headline(13))
                                    .foregroundColor(building.conditionColor)
                            }
                        }
                        
                        Spacer()
                        
                        // Score gauge
                        ZStack {
                            Circle()
                                .stroke(Color.biDivider, lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: CGFloat(building.conditionScore) / 100)
                                .stroke(building.conditionColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 0) {
                                Text("\(building.conditionScore)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(.biDark)
                                Text("/ 100")
                                    .font(BIFont.caption(9))
                                    .foregroundColor(.biMidGray)
                            }
                        }
                        .frame(width: 64, height: 64)
                    }
                    
                    // Quick action buttons
                    HStack(spacing: 10) {
                        QuickActionButton(icon: "plus.circle.fill", label: "Add Crack", color: .biHigh) {
                            showAddCrack = true
                        }
                        QuickActionButton(icon: "shield.fill", label: "Inspect", color: .biBlue) {
                            showAddInspection = true
                        }
                        QuickActionButton(icon: "door.left.hand.open", label: "Add Room", color: .biOrange) {
                            showAddRoom = true
                        }
                        QuickActionButton(icon: "trash", label: "Delete", color: .biMidGray) {
                            showDeleteAlert = true
                        }
                    }
                }
                .padding(16)
                .background(Color.biSurface)
                .cornerRadius(16)
                .shadow(color: Color.biDark.opacity(0.06), radius: 10, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Segment control
                Picker("", selection: $selectedSegment) {
                    Text("Rooms").tag(0)
                    Text("Cracks").tag(1)
                    Text("Inspections").tag(2)
                    Text("Repairs").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(spacing: 12) {
                        switch selectedSegment {
                        case 0:
                            RoomsTabView(buildingId: building.id)
                        case 1:
                            CracksTabView(buildingId: building.id)
                        case 2:
                            InspectionsTabView(buildingId: building.id)
                        default:
                            RepairsTabView(buildingId: building.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEdit) { EditBuildingView(building: $building) }
        .sheet(isPresented: $showAddRoom) { AddRoomView(buildingId: building.id) }
        .sheet(isPresented: $showAddCrack) { AddCrackView(buildingId: building.id) }
        .sheet(isPresented: $showAddInspection) { AddInspectionView(buildingId: building.id) }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Building?"),
                message: Text("This will also delete all rooms, cracks, and data for \"\(building.name)\". This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    dataStore.deleteBuilding(building)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)
                Text(label)
                    .font(BIFont.caption(10))
                    .foregroundColor(.biMidGray)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(pressed ? 0.92 : 1.0)
    }
}

// MARK: - Rooms Tab
struct RoomsTabView: View {
    @EnvironmentObject var dataStore: DataStore
    let buildingId: String
    
    var body: some View {
        VStack(spacing: 10) {
            if dataStore.rooms(for: buildingId).isEmpty {
                EmptyStateView(icon: "door.left.hand.closed", title: "No Rooms", message: "Add rooms to organize cracks by location")
            } else {
                ForEach(dataStore.rooms(for: buildingId)) { room in
                    RoomRowCard(room: room)
                }
            }
        }
    }
}

struct RoomRowCard: View {
    @EnvironmentObject var dataStore: DataStore
    let room: Room
    @State private var showDelete = false
    
    var body: some View {
        BICard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.biOrange.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 16))
                        .foregroundColor(.biOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name)
                        .font(BIFont.headline(15))
                        .foregroundColor(.biDark)
                    Text(String(format: "%.0f m²", room.area))
                        .font(BIFont.caption(12))
                        .foregroundColor(.biMidGray)
                }
                Spacer()
                Button(action: { showDelete = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.biMidGray)
                }
            }
        }
        .alert(isPresented: $showDelete) {
            Alert(
                title: Text("Delete Room?"),
                message: Text("Remove \"\(room.name)\"?"),
                primaryButton: .destructive(Text("Delete")) { dataStore.deleteRoom(room) },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Cracks Tab (compact)
struct CracksTabView: View {
    @EnvironmentObject var dataStore: DataStore
    let buildingId: String
    
    var body: some View {
        let cracks = dataStore.cracks(for: buildingId)
        VStack(spacing: 10) {
            if cracks.isEmpty {
                EmptyStateView(icon: "checkmark.shield", title: "No Cracks Recorded", message: "No defects found for this building")
            } else {
                ForEach(cracks) { crack in
                    NavigationLink(destination: CrackDetailView(crack: crack)) {
                        CrackRowCard(crack: crack)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Inspections Tab (compact)
struct InspectionsTabView: View {
    @EnvironmentObject var dataStore: DataStore
    let buildingId: String
    
    var body: some View {
        let insp = dataStore.inspections(for: buildingId)
        VStack(spacing: 10) {
            if insp.isEmpty {
                EmptyStateView(icon: "shield.slash", title: "No Inspections", message: "Schedule the first inspection")
            } else {
                ForEach(insp) { inspection in
                    NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                        InspectionRowCard(inspection: inspection)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Repairs Tab (compact)
struct RepairsTabView: View {
    @EnvironmentObject var dataStore: DataStore
    let buildingId: String
    
    var body: some View {
        let reps = dataStore.repairs.filter { $0.buildingId == buildingId }
        VStack(spacing: 10) {
            if reps.isEmpty {
                EmptyStateView(icon: "wrench.and.screwdriver", title: "No Repairs", message: "Schedule repairs for this building")
            } else {
                ForEach(reps) { repair in
                    NavigationLink(destination: RepairDetailView(repair: repair)) {
                        RepairRowCard(repair: repair)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Add Building
struct AddBuildingView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var address = ""
    @State private var conditionScore = 80
    @State private var notes = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Building Name *")
                            BITextField(placeholder: "e.g. Main Residence", text: $name, icon: "building.2.fill")
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Address *")
                            BITextField(placeholder: "e.g. 123 Oak Street", text: $address, icon: "mappin.circle.fill")
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                FormLabel("Condition Score")
                                Spacer()
                                Text("\(conditionScore)%")
                                    .font(BIFont.mono(14))
                                    .foregroundColor(.biOrange)
                            }
                            Slider(value: Binding(
                                get: { Double(conditionScore) },
                                set: { conditionScore = Int($0) }
                            ), in: 0...100, step: 1)
                            .accentColor(.biOrange)
                            
                            HStack {
                                Text("Critical")
                                    .font(BIFont.caption(11))
                                    .foregroundColor(.biCritical)
                                Spacer()
                                Text("Excellent")
                                    .font(BIFont.caption(11))
                                    .foregroundColor(.biLow)
                            }
                        }
                        .padding(16)
                        .background(Color.biSurface)
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Notes (optional)")
                            BITextField(placeholder: "Additional notes...", text: $notes, icon: "note.text")
                        }
                        
                        if showError {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.biHigh)
                                Text("Please fill in all required fields")
                                    .font(BIFont.body(14))
                                    .foregroundColor(.biHigh)
                            }
                        }
                        
                        BIPrimaryButton(title: "Add Building", icon: "plus") {
                            save()
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Building")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func save() {
        guard !name.isEmpty, !address.isEmpty else { showError = true; return }
        let building = Building(name: name, address: address, conditionScore: conditionScore, notes: notes)
        dataStore.addBuilding(building)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Building
struct EditBuildingView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Binding var building: Building
    
    @State private var name = ""
    @State private var address = ""
    @State private var conditionScore = 80
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Building Name")
                            BITextField(placeholder: "Building name", text: $name, icon: "building.2.fill")
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Address")
                            BITextField(placeholder: "Address", text: $address, icon: "mappin.circle.fill")
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                FormLabel("Condition Score")
                                Spacer()
                                Text("\(conditionScore)%")
                                    .font(BIFont.mono(14))
                                    .foregroundColor(.biOrange)
                            }
                            Slider(value: Binding(
                                get: { Double(conditionScore) },
                                set: { conditionScore = Int($0) }
                            ), in: 0...100, step: 1)
                            .accentColor(.biOrange)
                        }
                        .padding(16)
                        .background(Color.biSurface)
                        .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Notes")
                            BITextField(placeholder: "Notes", text: $notes, icon: "note.text")
                        }
                        BIPrimaryButton(title: "Save Changes", icon: "checkmark") { save() }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Building")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                name = building.name
                address = building.address
                conditionScore = building.conditionScore
                notes = building.notes
            }
        }
    }
    
    private func save() {
        building.name = name
        building.address = address
        building.conditionScore = conditionScore
        building.notes = notes
        dataStore.updateBuilding(building)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add Room
struct AddRoomView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    let buildingId: String
    
    @State private var name = ""
    @State private var area = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        FormLabel("Room Name *")
                        BITextField(placeholder: "e.g. Living Room", text: $name, icon: "door.left.hand.open")
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        FormLabel("Area (m²)")
                        BITextField(placeholder: "e.g. 25", text: $area, icon: "ruler.fill", keyboardType: .decimalPad)
                    }
                    if showError {
                        Text("Room name is required").font(BIFont.body(14)).foregroundColor(.biHigh)
                    }
                    BIPrimaryButton(title: "Add Room", icon: "plus") { save() }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Room")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func save() {
        guard !name.isEmpty else { showError = true; return }
        let room = Room(buildingId: buildingId, name: name, area: Double(area) ?? 0)
        dataStore.addRoom(room)
        presentationMode.wrappedValue.dismiss()
    }
}

struct FormLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(BIFont.headline(13))
            .foregroundColor(.biMidGray)
    }
}
