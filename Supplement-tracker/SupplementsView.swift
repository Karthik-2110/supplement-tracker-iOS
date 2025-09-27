import SwiftUI

// Interval type for supplement reminders
enum SupplementInterval: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        }
    }
}

// Weekday selection for weekly intervals
struct WeeklySchedule: Codable {
    var sunday: Bool = false
    var monday: Bool = false
    var tuesday: Bool = false
    var wednesday: Bool = false
    var thursday: Bool = false
    var friday: Bool = false
    var saturday: Bool = false
    
    var selectedDays: [String] {
        var days: [String] = []
        if sunday { days.append("Su") }
        if monday { days.append("Mo") }
        if tuesday { days.append("Tu") }
        if wednesday { days.append("We") }
        if thursday { days.append("Th") }
        if friday { days.append("Fr") }
        if saturday { days.append("Sa") }
        return days
    }
    
    var hasSelectedDays: Bool {
        return sunday || monday || tuesday || wednesday || thursday || friday || saturday
    }
}

// Enhanced Supplement data model with all required fields
struct Supplement: Identifiable, Codable {
    let id: UUID
    var name: String
    var quantity: String // e.g., "1 scoop", "2 tablets"
    var timesPerDay: Int
    var time: Date
    var brand: String
    var interval: SupplementInterval
    var weeklySchedule: WeeklySchedule
    
    init(id: UUID = UUID(), name: String, quantity: String, timesPerDay: Int, time: Date, brand: String, interval: SupplementInterval = .daily, weeklySchedule: WeeklySchedule = WeeklySchedule()) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.timesPerDay = timesPerDay
        self.time = time
        self.brand = brand
        self.interval = interval
        self.weeklySchedule = weeklySchedule
    }
}

// Interval Selection View with weekday circles
struct IntervalSelectionView: View {
    @Binding var interval: SupplementInterval
    @Binding var weeklySchedule: WeeklySchedule
    
    private let weekdays = [
        ("Su", "Sunday", \WeeklySchedule.sunday),
        ("Mo", "Monday", \WeeklySchedule.monday),
        ("Tu", "Tuesday", \WeeklySchedule.tuesday),
        ("We", "Wednesday", \WeeklySchedule.wednesday),
        ("Th", "Thursday", \WeeklySchedule.thursday),
        ("Fr", "Friday", \WeeklySchedule.friday),
        ("Sa", "Saturday", \WeeklySchedule.saturday)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Interval Type Picker
            Picker("Interval", selection: $interval) {
                ForEach(SupplementInterval.allCases, id: \.self) { intervalType in
                    Text(intervalType.displayName).tag(intervalType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Daily information section
            if interval == .daily {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminder")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("This confirms that this supplement is taken by you on daily basis.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Weekly Schedule Selection (only shown when weekly is selected)
            if interval == .weekly {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(weekdays, id: \.0) { day in
                            WeekdayCircle(
                                abbreviation: day.0,
                                fullName: day.1,
                                isSelected: weeklySchedule[keyPath: day.2],
                                onTap: {
                                    weeklySchedule[keyPath: day.2].toggle()
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
        }
    }
}

// Individual weekday circle component
struct WeekdayCircle: View {
    let abbreviation: String
    let fullName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(abbreviation)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(fullName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// Add Supplement View for input form
struct AddSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    @State private var name = ""
    @State private var quantity = ""
    @State private var timesPerDay = 1
    @State private var time = Date()
    @State private var brand = ""
    @State private var interval: SupplementInterval = .daily
    @State private var weeklySchedule = WeeklySchedule()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var retryAttempt = 0
    
    let onSupplementAdded: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement Details") {
                    TextField("Supplement Name", text: $name)
                    TextField("Quantity (e.g., 1 scoop, 2 tablets)", text: $quantity)
                    TextField("Brand Name", text: $brand)
                }
                
                Section("Dosage Information") {
                    Stepper("Times per day: \(timesPerDay)", value: $timesPerDay, in: 1...10)
                    DatePicker("Time to take", selection: $time, displayedComponents: .hourAndMinute)
                }
                
                Section("Reminder Schedule") {
                    IntervalSelectionView(interval: $interval, weeklySchedule: $weeklySchedule)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isLoading)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveSupplement()
                        }
                    }
                    .disabled(name.isEmpty || quantity.isEmpty || brand.isEmpty || isLoading || (interval == .weekly && !weeklySchedule.hasSelectedDays))
                }
            }
            
            if isLoading && retryAttempt > 0 {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Retrying... (Attempt \(retryAttempt + 1))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func saveSupplement() async {
        isLoading = true
        errorMessage = nil
        retryAttempt = 0
        
        do {
            let supplement = Supplement(
                name: name,
                quantity: quantity,
                timesPerDay: timesPerDay,
                time: time,
                brand: brand,
                interval: interval,
                weeklySchedule: weeklySchedule
            )
            
            try await RetryUtility.withRetry(
                maxAttempts: 3,
                delay: 1.0,
                onRetry: { attempt in
                    Task { @MainActor in
                        retryAttempt = attempt
                    }
                }
            ) {
                try await supabaseManager.addSupplement(supplement)
            }
            
            await MainActor.run {
                onSupplementAdded()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save supplement: \(error.localizedDescription)"
                isLoading = false
                retryAttempt = 0
            }
        }
    }
}

// Edit Supplement View for modifying existing supplements
struct EditSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseManager = SupabaseManager.shared
    let supplement: Supplement
    let onSupplementUpdated: () -> Void
    
    @State private var name: String
    @State private var quantity: String
    @State private var timesPerDay: Int
    @State private var time: Date
    @State private var brand: String
    @State private var interval: SupplementInterval
    @State private var weeklySchedule: WeeklySchedule
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var retryAttempt = 0
    
    init(supplement: Supplement, onSupplementUpdated: @escaping () -> Void) {
        self.supplement = supplement
        self.onSupplementUpdated = onSupplementUpdated
        self._name = State(initialValue: supplement.name)
        self._quantity = State(initialValue: supplement.quantity)
        self._timesPerDay = State(initialValue: supplement.timesPerDay)
        self._time = State(initialValue: supplement.time)
        self._brand = State(initialValue: supplement.brand)
        self._interval = State(initialValue: supplement.interval)
        self._weeklySchedule = State(initialValue: supplement.weeklySchedule)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement Details") {
                    TextField("Supplement Name", text: $name)
                    TextField("Quantity (e.g., 1 scoop, 2 tablets)", text: $quantity)
                    TextField("Brand Name", text: $brand)
                }
                
                Section("Dosage Information") {
                    Stepper("Times per day: \(timesPerDay)", value: $timesPerDay, in: 1...10)
                    DatePicker("Time to take", selection: $time, displayedComponents: .hourAndMinute)
                }
                
                Section("Reminder Schedule") {
                    IntervalSelectionView(interval: $interval, weeklySchedule: $weeklySchedule)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isLoading)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await updateSupplement()
                        }
                    }
                    .disabled(name.isEmpty || quantity.isEmpty || brand.isEmpty || isLoading || (interval == .weekly && !weeklySchedule.hasSelectedDays))
                }
            }
            
            if isLoading && retryAttempt > 0 {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Retrying... (Attempt \(retryAttempt + 1))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func updateSupplement() async {
        isLoading = true
        errorMessage = nil
        retryAttempt = 0
        
        do {
            let updatedSupplement = Supplement(
                id: supplement.id,
                name: name,
                quantity: quantity,
                timesPerDay: timesPerDay,
                time: time,
                brand: brand,
                interval: interval,
                weeklySchedule: weeklySchedule
            )
            
            try await RetryUtility.withRetry(maxAttempts: 3, delay: 1.0, onRetry: { attempt in
                await MainActor.run {
                    retryAttempt = attempt
                }
            }) {
                try await supabaseManager.updateSupplement(updatedSupplement)
            }
            
            await MainActor.run {
                retryAttempt = 0
                onSupplementUpdated()
                dismiss()
            }
        } catch {
            await MainActor.run {
                retryAttempt = 0
                errorMessage = "Failed to update supplement: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct SupplementsView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var supplements: [Supplement] = []
    @State private var showingAddSupplement = false
    @State private var editingSupplement: Supplement?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading supplements...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if supplements.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "pills")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Add your first supplement")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(supplements) { supplement in
                            SupplementRowView(supplement: supplement)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete") {
                                        Task {
                                            await deleteSupplement(supplement)
                                        }
                                    }
                                    .tint(.red)
                                    
                                    Button("Edit") {
                                        editingSupplement = supplement
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .navigationTitle("My Supplements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSupplement = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSupplement) {
                AddSupplementView {
                    Task {
                        await loadSupplements()
                    }
                }
            }
            .sheet(item: $editingSupplement) { supplement in
                EditSupplementView(supplement: supplement) {
                    Task {
                        await loadSupplements()
                    }
                }
            }
            .task {
                await loadSupplements()
            }
            .refreshable {
                await loadSupplements()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func loadSupplements() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedSupplements = try await supabaseManager.fetchSupplements()
            await MainActor.run {
                supplements = fetchedSupplements
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load supplements: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func deleteSupplement(_ supplement: Supplement) async {
        do {
            try await supabaseManager.deleteSupplement(id: supplement.id)
            await MainActor.run {
                supplements.removeAll { $0.id == supplement.id }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete supplement: \(error.localizedDescription)"
            }
        }
    }
}

// Individual supplement row view
struct SupplementRowView: View {
    let supplement: Supplement
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var scheduleText: String {
        switch supplement.interval {
        case .daily:
            return "\(supplement.timesPerDay)x daily"
        case .weekly:
            if supplement.weeklySchedule.hasSelectedDays {
                let days = supplement.weeklySchedule.selectedDays.joined(separator: ", ")
                return "\(supplement.timesPerDay)x on \(days)"
            } else {
                return "\(supplement.timesPerDay)x weekly"
            }
        }
    }
    
    private var scheduleIcon: String {
        switch supplement.interval {
        case .daily:
            return "repeat"
        case .weekly:
            return "calendar.badge.clock"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(supplement.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(supplement.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack {
                Label(supplement.quantity, systemImage: "pills.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(scheduleText, systemImage: scheduleIcon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(timeFormatter.string(from: supplement.time), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Show interval type badge
                Text(supplement.interval.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(supplement.interval == .daily ? .blue : .green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(supplement.interval == .daily ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 4)
    }
}

// Extension to make Int conform to Identifiable for sheet presentation
extension Int: Identifiable {
    public var id: Int { self }
}

#Preview {
    SupplementsView()
}


// MARK: - Retry Utility
struct RetryUtility {
    static func withRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        onRetry: ((Int) async -> Void)? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on the last attempt
                if attempt == maxAttempts {
                    break
                }
                
                // Notify about retry attempt
                await onRetry?(attempt)
                
                // Exponential backoff: delay increases with each attempt
                let backoffDelay = delay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NSError(domain: "RetryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"])
    }
}