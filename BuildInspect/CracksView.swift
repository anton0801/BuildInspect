import SwiftUI

// MARK: - Cracks List View
struct CracksListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAdd = false
    @State private var filterSeverity: Severity? = nil
    @State private var showResolved = false
    
    let buildingId: String?
    let buildingName: String
    
    var allCracks: [Crack] {
        if let id = buildingId {
            return dataStore.cracks(for: id)
        }
        return dataStore.cracks
    }
    
    var filtered: [Crack] {
        allCracks
            .filter { showResolved ? true : !$0.isResolved }
            .filter { filterSeverity == nil || $0.severity == filterSeverity }
            .sorted { $0.severity.sortOrder > $1.severity.sortOrder }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    BINavBar(title: "Cracks", subtitle: buildingName,
                             trailingAction: { showAdd = true }, trailingIcon: "plus")
                    
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: filterSeverity == nil) {
                                withAnimation { filterSeverity = nil }
                            }
                            ForEach(Severity.allCases, id: \.self) { sev in
                                FilterChip(label: sev.rawValue, isSelected: filterSeverity == sev, color: sev.color) {
                                    withAnimation { filterSeverity = filterSeverity == sev ? nil : sev }
                                }
                            }
                            FilterChip(label: showResolved ? "Hide Resolved" : "Show Resolved",
                                       isSelected: showResolved, color: .biMidGray) {
                                withAnimation { showResolved.toggle() }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)
                    
                    if filtered.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "checkmark.shield.fill",
                            title: "No Cracks Found",
                            message: "All clear! No cracks match current filters.",
                            actionTitle: "Record a Crack",
                            action: { showAdd = true }
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { crack in
                                    NavigationLink(destination: CrackDetailView(crack: crack)) {
                                        CrackRowCard(crack: crack)
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
                AddCrackView(buildingId: buildingId ?? (dataStore.buildings.first?.id ?? ""))
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .biOrange
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(BIFont.caption(12))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Crack Row Card
struct CrackRowCard: View {
    @EnvironmentObject var dataStore: DataStore
    let crack: Crack
    
    var latestWidth: String {
        if let m = dataStore.latestMeasurement(for: crack.id) {
            return String(format: "%.1f mm", m.width)
        }
        return "Not measured"
    }
    
    var body: some View {
        BICard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(crack.severity.color.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: crack.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(crack.severity.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(crack.location)
                            .font(BIFont.headline(14))
                            .foregroundColor(crack.isResolved ? .biMidGray : .biDark)
                            .lineLimit(1)
                        if crack.isResolved {
                            Text("Resolved")
                                .font(BIFont.caption(10))
                                .foregroundColor(.biLow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.biLow.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(crack.type.rawValue)
                            .font(BIFont.caption(12))
                            .foregroundColor(.biMidGray)
                        Text("•")
                            .foregroundColor(.biLightGray)
                            .font(BIFont.caption(12))
                        Text(latestWidth)
                            .font(BIFont.mono(12))
                            .foregroundColor(.biMidGray)
                    }
                    Text(crack.createdAt, style: .date)
                        .font(BIFont.caption(11))
                        .foregroundColor(.biLightGray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    SeverityBadge(severity: crack.severity)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.biLightGray)
                }
            }
        }
    }
}

// MARK: - Crack Detail
struct CrackDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State var crack: Crack
    @State private var showAddMeasurement = false
    @State private var showAddPhoto = false
    @State private var showEdit = false
    @State private var showDelete = false
    @State private var showComparison = false
    @State private var selectedSegment = 0
    
    var growth: Double { dataStore.widthGrowth(for: crack.id) }
    
    var body: some View {
        ZStack {
            Color.biBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                BINavBar(
                    title: "Crack Details",
                    subtitle: crack.location,
                    onBack: { presentationMode.wrappedValue.dismiss() },
                    trailingAction: { showEdit = true },
                    trailingIcon: "pencil"
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Status card
                        BICard {
                            VStack(spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(crack.location)
                                            .font(BIFont.display(17))
                                            .foregroundColor(.biDark)
                                        HStack(spacing: 8) {
                                            SeverityBadge(severity: crack.severity)
                                            Text(crack.type.rawValue)
                                                .font(BIFont.caption(12))
                                                .foregroundColor(.biMidGray)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.biBackground)
                                                .cornerRadius(8)
                                        }
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(crack.severity.color.opacity(0.12))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: crack.severity.icon)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(crack.severity.color)
                                    }
                                }
                                
                                Divider()
                                
                                // Latest measurement
                                if let m = dataStore.latestMeasurement(for: crack.id) {
                                    HStack(spacing: 0) {
                                        MeasurementStat(value: String(format: "%.1f", m.width), unit: "mm", label: "Width")
                                        Divider().frame(height: 40)
                                        MeasurementStat(value: String(format: "%.0f", m.length), unit: "cm", label: "Length")
                                        Divider().frame(height: 40)
                                        MeasurementStat(
                                            value: growth >= 0 ? "+\(String(format: "%.1f", growth))" : String(format: "%.1f", growth),
                                            unit: "mm",
                                            label: "Growth",
                                            color: growth > 0 ? .biHigh : (growth < 0 ? .biLow : .biMidGray)
                                        )
                                    }
                                } else {
                                    Text("No measurements yet")
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                        .frame(maxWidth: .infinity)
                                }
                                
                                if !crack.description.isEmpty {
                                    Text(crack.description)
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biMidGray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 4)
                                }
                                
                                // Resolve toggle
                                HStack {
                                    Text("Mark as resolved")
                                        .font(BIFont.body(14))
                                        .foregroundColor(.biDark)
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { crack.isResolved },
                                        set: { val in
                                            crack.isResolved = val
                                            dataStore.updateCrack(crack)
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .biLow))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Action buttons
                        HStack(spacing: 10) {
                            ActionButton(icon: "ruler.fill", label: "Measure", color: .biBlue) {
                                showAddMeasurement = true
                            }
                            ActionButton(icon: "camera.fill", label: "Photo", color: .biPurple) {
                                showAddPhoto = true
                            }
                            if dataStore.photos(for: crack.id).count >= 2 {
                                ActionButton(icon: "rectangle.split.2x1.fill", label: "Compare", color: .biMedium) {
                                    showComparison = true
                                }
                            }
                            ActionButton(icon: "trash.fill", label: "Delete", color: .biHigh) {
                                showDelete = true
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Segment
                        Picker("", selection: $selectedSegment) {
                            Text("Measurements").tag(0)
                            Text("Photos").tag(1)
                            Text("Timeline").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        
                        switch selectedSegment {
                        case 0:
                            MeasurementsSection(crackId: crack.id)
                                .padding(.horizontal, 20)
                        case 1:
                            PhotosSection(crackId: crack.id, buildingId: crack.buildingId)
                                .padding(.horizontal, 20)
                        default:
                            CrackTimelineSection(crackId: crack.id)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 4)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddMeasurement) { AddMeasurementView(crackId: crack.id) }
        .sheet(isPresented: $showAddPhoto) { AddPhotoView(crackId: crack.id, buildingId: crack.buildingId) }
        .sheet(isPresented: $showEdit) { EditCrackView(crack: $crack) }
        .sheet(isPresented: $showComparison) { PhotoComparisonView(crackId: crack.id) }
        .alert(isPresented: $showDelete) {
            Alert(
                title: Text("Delete Crack?"),
                message: Text("This will also remove all measurements and photos."),
                primaryButton: .destructive(Text("Delete")) {
                    dataStore.deleteCrack(crack)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct MeasurementStat: View {
    let value: String
    let unit: String
    let label: String
    var color: Color = .biDark
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(color)
                Text(unit)
                    .font(BIFont.caption(11))
                    .foregroundColor(.biMidGray)
            }
            Text(label)
                .font(BIFont.caption(11))
                .foregroundColor(.biMidGray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionButton: View {
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
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 38, height: 38)
                    .background(color.opacity(0.12))
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

// MARK: - Add Crack
struct AddCrackView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    let buildingId: String
    
    @State private var location = ""
    @State private var type: CrackType = .structural
    @State private var severity: Severity = .medium
    @State private var description = ""
    @State private var roomId: String? = nil
    @State private var showError = false
    
    var rooms: [Room] { dataStore.rooms(for: buildingId) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Location *")
                            BITextField(placeholder: "e.g. North wall, corner", text: $location, icon: "mappin.fill")
                        }
                        
                        if !rooms.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                FormLabel("Room (optional)")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        FilterChip(label: "No Room", isSelected: roomId == nil) { roomId = nil }
                                        ForEach(rooms) { room in
                                            FilterChip(label: room.name, isSelected: roomId == room.id) { roomId = room.id }
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Crack Type")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(CrackType.allCases, id: \.self) { t in
                                    Button(action: { type = t }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: t.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(type == t ? .white : .biOrange)
                                            Text(t.rawValue)
                                                .font(BIFont.caption(11))
                                                .foregroundColor(type == t ? .white : .biDark)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(type == t ? Color.biOrange : Color.biSurface)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(type == t ? Color.clear : Color.biDivider, lineWidth: 1))
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("Severity")
                            HStack(spacing: 10) {
                                ForEach(Severity.allCases, id: \.self) { s in
                                    Button(action: { severity = s }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: s.icon)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(severity == s ? .white : s.color)
                                            Text(s.rawValue)
                                                .font(BIFont.caption(11))
                                                .foregroundColor(severity == s ? .white : .biDark)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(severity == s ? s.color : s.color.opacity(0.08))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Description (optional)")
                            BITextField(placeholder: "Describe the crack...", text: $description, icon: "doc.text.fill")
                        }
                        
                        if showError {
                            Text("Location is required").font(BIFont.body(14)).foregroundColor(.biHigh)
                        }
                        
                        BIPrimaryButton(title: "Record Crack", icon: "plus") { save() }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Crack")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func save() {
        guard !location.isEmpty else { showError = true; return }
        let crack = Crack(buildingId: buildingId, roomId: roomId, location: location, type: type, severity: severity, description: description)
        dataStore.addCrack(crack)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Crack
struct EditCrackView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Binding var crack: Crack
    
    @State private var location = ""
    @State private var type: CrackType = .structural
    @State private var severity: Severity = .medium
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Location")
                            BITextField(placeholder: "Location", text: $location, icon: "mappin.fill")
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("Severity")
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
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Description")
                            BITextField(placeholder: "Description...", text: $description, icon: "doc.text.fill")
                        }
                        BIPrimaryButton(title: "Save Changes", icon: "checkmark") { save() }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Crack")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear {
                location = crack.location
                type = crack.type
                severity = crack.severity
                description = crack.description
            }
        }
    }
    
    private func save() {
        crack.location = location
        crack.type = type
        crack.severity = severity
        crack.description = description
        dataStore.updateCrack(crack)
        presentationMode.wrappedValue.dismiss()
    }
}
