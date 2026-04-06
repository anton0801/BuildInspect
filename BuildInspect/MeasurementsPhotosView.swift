import SwiftUI

// MARK: - Measurements Section
struct MeasurementsSection: View {
    @EnvironmentObject var dataStore: DataStore
    let crackId: String
    
    var measurements: [Measurement] { dataStore.measurements(for: crackId) }
    
    var body: some View {
        VStack(spacing: 10) {
            if measurements.isEmpty {
                EmptyStateView(icon: "ruler.fill", title: "No Measurements", message: "Add measurements to track crack growth")
            } else {
                ForEach(measurements.reversed()) { m in
                    MeasurementCard(measurement: m)
                }
            }
        }
    }
}

struct MeasurementCard: View {
    @EnvironmentObject var dataStore: DataStore
    let measurement: Measurement
    @State private var showDelete = false
    
    var body: some View {
        BICard {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text(String(format: "%.1f mm", measurement.width))
                                .font(BIFont.mono(16))
                                .foregroundColor(.biDark)
                            Text("Width")
                                .font(BIFont.caption(10))
                                .foregroundColor(.biMidGray)
                        }
                        Text("×")
                            .font(BIFont.body(14))
                            .foregroundColor(.biLightGray)
                        VStack(spacing: 1) {
                            Text(String(format: "%.0f cm", measurement.length))
                                .font(BIFont.mono(16))
                                .foregroundColor(.biDark)
                            Text("Length")
                                .font(BIFont.caption(10))
                                .foregroundColor(.biMidGray)
                        }
                        if let depth = measurement.depth {
                            Text("×")
                                .font(BIFont.body(14))
                                .foregroundColor(.biLightGray)
                            VStack(spacing: 1) {
                                Text(String(format: "%.1f mm", depth))
                                    .font(BIFont.mono(16))
                                    .foregroundColor(.biDark)
                                Text("Depth")
                                    .font(BIFont.caption(10))
                                    .foregroundColor(.biMidGray)
                            }
                        }
                    }
                    Text(measurement.date, style: .date)
                        .font(BIFont.caption(12))
                        .foregroundColor(.biMidGray)
                    if !measurement.notes.isEmpty {
                        Text(measurement.notes)
                            .font(BIFont.caption(12))
                            .foregroundColor(.biMidGray)
                            .lineLimit(1)
                    }
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
                title: Text("Delete Measurement?"),
                primaryButton: .destructive(Text("Delete")) { dataStore.deleteMeasurement(measurement) },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Add Measurement
struct AddMeasurementView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    let crackId: String
    
    @State private var width = ""
    @State private var length = ""
    @State private var depth = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Width (mm) *")
                            BITextField(placeholder: "e.g. 1.5", text: $width, icon: "arrow.left.and.right", keyboardType: .decimalPad)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Length (cm) *")
                            BITextField(placeholder: "e.g. 35", text: $length, icon: "ruler.fill", keyboardType: .decimalPad)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Depth (mm, optional)")
                            BITextField(placeholder: "e.g. 2.0", text: $depth, icon: "arrow.up.and.down", keyboardType: .decimalPad)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Notes")
                            BITextField(placeholder: "Any notes...", text: $notes, icon: "doc.text")
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Date")
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(Color.biSurface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.biDivider, lineWidth: 1))
                        }
                        
                        if showError {
                            Text("Width and length are required").font(BIFont.body(14)).foregroundColor(.biHigh)
                        }
                        
                        BIPrimaryButton(title: "Save Measurement", icon: "ruler.fill") { save() }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func save() {
        guard let w = Double(width), let l = Double(length) else { showError = true; return }
        let m = Measurement(
            crackId: crackId,
            width: w,
            length: l,
            depth: Double(depth),
            date: date,
            notes: notes
        )
        dataStore.addMeasurement(m)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Photos Section
struct PhotosSection: View {
    @EnvironmentObject var dataStore: DataStore
    let crackId: String
    let buildingId: String
    
    var photos: [CrackPhoto] { dataStore.photos(for: crackId) }
    
    var body: some View {
        VStack(spacing: 10) {
            if photos.isEmpty {
                EmptyStateView(icon: "photo.on.rectangle.angled", title: "No Photos", message: "Add photos to document the crack visually")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(photos) { photo in
                        PhotoCard(photo: photo)
                    }
                }
            }
        }
    }
}

struct PhotoCard: View {
    @EnvironmentObject var dataStore: DataStore
    let photo: CrackPhoto
    @State private var showDelete = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.biBackground)
                    .frame(height: 110)
                
                if let data = photo.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.biLightGray)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Text(photo.tag.rawValue)
                            .font(BIFont.caption(9))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.biDark.opacity(0.6))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(6)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.location)
                    .font(BIFont.caption(11))
                    .foregroundColor(.biDark)
                    .lineLimit(1)
                HStack {
                    Text(photo.date, style: .date)
                        .font(BIFont.caption(10))
                        .foregroundColor(.biMidGray)
                    Spacer()
                    Button(action: { showDelete = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.biMidGray)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color.biSurface)
        .cornerRadius(10)
        .shadow(color: Color.biDark.opacity(0.05), radius: 6, y: 2)
        .alert(isPresented: $showDelete) {
            Alert(
                title: Text("Delete Photo?"),
                primaryButton: .destructive(Text("Delete")) { dataStore.deletePhoto(photo) },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Add Photo
struct AddPhotoView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    let crackId: String?
    let buildingId: String
    
    @State private var location = ""
    @State private var tag: PhotoTag = .general
    @State private var notes = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Photo placeholder / picker
                        Button(action: { showImagePicker = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.biBackground)
                                    .frame(height: 180)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.biDivider, lineWidth: 1))
                                
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.biOrange)
                                        Text("Tap to select photo")
                                            .font(BIFont.body(14))
                                            .foregroundColor(.biMidGray)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Location *")
                            BITextField(placeholder: "Where was this photo taken?", text: $location, icon: "mappin.fill")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("Photo Tag")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(PhotoTag.allCases, id: \.self) { t in
                                        FilterChip(label: t.rawValue, isSelected: tag == t) { tag = t }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            FormLabel("Notes")
                            BITextField(placeholder: "Notes about this photo...", text: $notes, icon: "note.text")
                        }
                        
                        if showError {
                            Text("Location is required").font(BIFont.body(14)).foregroundColor(.biHigh)
                        }
                        
                        BIPrimaryButton(title: "Save Photo", icon: "camera.fill") { save() }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Photo")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func save() {
        guard !location.isEmpty else { showError = true; return }
        let photo = CrackPhoto(
            crackId: crackId,
            buildingId: buildingId,
            location: location,
            imageData: selectedImage?.jpegData(compressionQuality: 0.7),
            notes: notes,
            tag: tag
        )
        dataStore.addPhoto(photo)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.selectedImage = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.selectedImage = original
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Photo Comparison
struct PhotoComparisonView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    let crackId: String
    
    @State private var sliderValue: CGFloat = 0.5
    
    var photos: [CrackPhoto] { dataStore.photos(for: crackId) }
    var beforePhoto: CrackPhoto? { photos.min(by: { $0.date < $1.date }) }
    var afterPhoto: CrackPhoto? { photos.max(by: { $0.date < $1.date }) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.biDark.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button("Close") { presentationMode.wrappedValue.dismiss() }
                            .foregroundColor(.white)
                        Spacer()
                        Text("Photo Comparison")
                            .font(BIFont.headline(16))
                            .foregroundColor(.white)
                        Spacer()
                        Spacer().frame(width: 50)
                    }
                    .padding(20)
                    
                    Spacer()
                    
                    // Comparison area
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // After (full)
                            if let after = afterPhoto, let data = after.imageData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white.opacity(0.4))
                                            Text("AFTER")
                                                .font(BIFont.headline(14))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    )
                            }
                            
                            // Before (clipped)
                            if let before = beforePhoto, let data = before.imageData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                    .mask(
                                        HStack(spacing: 0) {
                                            Rectangle().frame(width: geo.size.width * sliderValue)
                                            Spacer()
                                        }
                                    )
                            } else {
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: geo.size.width * sliderValue)
                                        .overlay(
                                            Text("BEFORE")
                                                .font(BIFont.headline(14))
                                                .foregroundColor(.white.opacity(0.6))
                                        )
                                    Spacer()
                                }
                            }
                            
                            // Divider line
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2)
                                .offset(x: geo.size.width * sliderValue - 1)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                        .shadow(radius: 4)
                                        .overlay(
                                            Image(systemName: "arrow.left.and.right")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.biDark)
                                        )
                                        .offset(x: geo.size.width * sliderValue - 1, y: 0),
                                    alignment: .leading
                                )
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    sliderValue = max(0, min(1, v.location.x / geo.size.width))
                                }
                        )
                    }
                    .frame(height: 360)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Labels
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BEFORE")
                                .font(BIFont.caption(11))
                                .foregroundColor(.white.opacity(0.5))
                            if let before = beforePhoto {
                                Text(before.date, style: .date)
                                    .font(BIFont.headline(13))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("AFTER")
                                .font(BIFont.caption(11))
                                .foregroundColor(.white.opacity(0.5))
                            if let after = afterPhoto {
                                Text(after.date, style: .date)
                                    .font(BIFont.headline(13))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Slider(value: $sliderValue, in: 0...1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .accentColor(.white)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Crack Timeline Section
struct CrackTimelineSection: View {
    @EnvironmentObject var dataStore: DataStore
    let crackId: String
    
    var measurements: [Measurement] { dataStore.measurements(for: crackId) }
    
    var body: some View {
        VStack(spacing: 10) {
            if measurements.isEmpty {
                EmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No Data Yet", message: "Add measurements to see the growth timeline")
            } else {
                // Simple chart
                BICard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Width Over Time")
                            .font(BIFont.headline(14))
                            .foregroundColor(.biDark)
                        
                        SimpleLineChart(measurements: measurements)
                            .frame(height: 120)
                    }
                }
                
                // Timeline list
                ForEach(measurements.reversed()) { m in
                    HStack(spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Color.biOrange)
                                .frame(width: 10, height: 10)
                            if m.id != measurements.first?.id {
                                Rectangle()
                                    .fill(Color.biDivider)
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.date, style: .date)
                                .font(BIFont.caption(11))
                                .foregroundColor(.biMidGray)
                            HStack {
                                Text(String(format: "%.1f mm × %.0f cm", m.width, m.length))
                                    .font(BIFont.mono(14))
                                    .foregroundColor(.biDark)
                            }
                        }
                        Spacer()
                    }
                    .frame(minHeight: 44)
                }
            }
        }
    }
}

struct SimpleLineChart: View {
    let measurements: [Measurement]
    
    var maxVal: Double { measurements.map { $0.width }.max() ?? 1 }
    var minVal: Double { measurements.map { $0.width }.min() ?? 0 }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.biDivider)
                            .frame(height: 0.5)
                    }
                }
                
                // Line path
                Path { path in
                    guard measurements.count > 1 else { return }
                    for (i, m) in measurements.enumerated() {
                        let x = CGFloat(i) / CGFloat(measurements.count - 1) * geo.size.width
                        let range = maxVal - minVal
                        let normalized = range > 0 ? (m.width - minVal) / range : 0.5
                        let y = geo.size.height - (CGFloat(normalized) * geo.size.height * 0.8) - (geo.size.height * 0.1)
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.biOrange, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
                // Data points
                ForEach(measurements.indices, id: \.self) { i in
                    let m = measurements[i]
                    let x = CGFloat(i) / CGFloat(max(measurements.count - 1, 1)) * geo.size.width
                    let range = maxVal - minVal
                    let normalized = range > 0 ? (m.width - minVal) / range : 0.5
                    let y = geo.size.height - (CGFloat(normalized) * geo.size.height * 0.8) - (geo.size.height * 0.1)
                    
                    Circle()
                        .fill(Color.biOrange)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}
