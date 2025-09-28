import SwiftUI

// Supplement consumption item for home display
struct SupplementConsumptionItem: Identifiable {
    let id: UUID
    let supplementId: UUID
    let supplementName: String
    let quantity: String
    let brand: String
    let timeToTake: String
    let isConsumed: Bool
    let date: Date
    
    init(consumption: SupplementConsumption, supplementName: String, quantity: String, brand: String, timeToTake: String, supplementId: UUID) {
        self.id = consumption.id
        self.supplementId = supplementId
        self.supplementName = supplementName
        self.quantity = quantity
        self.brand = brand
        self.timeToTake = timeToTake
        self.isConsumed = consumption.isConsumed
        self.date = consumption.date
    }
}

// Supplement consumption row view
struct SupplementConsumptionRowView: View {
    let item: SupplementConsumptionItem
    let colorScheme: ColorScheme
    
    // Dynamic colors based on color scheme
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 51/255, green: 51/255, blue: 51/255)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color(red: 153/255, green: 153/255, blue: 153/255)
    }
    
    private var backgroundAccentColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color.gray.opacity(0.2)
    }
    
    private var completedTextColor: Color {
        colorScheme == .dark ? Color.gray : Color(red: 153/255, green: 153/255, blue: 153/255)
    }

    // 12-hour time formatter
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    // Convert 24-hour time string to 12-hour format
    private func formatTime(_ timeString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        
        if let date = inputFormatter.date(from: timeString) {
            return timeFormatter.string(from: date)
        }
        return timeString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // First row: Name and Time
            HStack {
                Text(item.supplementName)
                    .font(.headline)
                    .foregroundColor(item.isConsumed ? completedTextColor : primaryTextColor)
                    .strikethrough(item.isConsumed)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    Text(formatTime(item.timeToTake))
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
            }
            
            // Second row: Quantity and Status
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "pills.fill")
                    Text(item.quantity)
                }
                .font(.subheadline)
                .foregroundColor(item.isConsumed ? completedTextColor : secondaryTextColor)
                
                Spacer()
                
                Text(item.isConsumed ? "Taken" : "Pending")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(item.isConsumed ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((item.isConsumed ? Color.green : Color.orange).opacity(0.15))
                    )
            }
        }
        .padding(.vertical, 4)
        .opacity(item.isConsumed ? 0.6 : 1.0)
    }
}

// Individual home item row view
struct HomeItemRowView: View {
    let item: HomeItem
    let colorScheme: ColorScheme
    
    // Dynamic colors based on color scheme
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 51/255, green: 51/255, blue: 51/255)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color(red: 153/255, green: 153/255, blue: 153/255)
    }
    
    private var backgroundAccentColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color.gray.opacity(0.2)
    }
    
    private var completedTextColor: Color {
        colorScheme == .dark ? Color.gray : Color(red: 153/255, green: 153/255, blue: 153/255)
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(item.isCompleted ? completedTextColor : primaryTextColor)
                    .strikethrough(item.isCompleted)
                Spacer()
                Text(item.category)
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(backgroundAccentColor)
                    .cornerRadius(4)
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "house.fill")
                    Text(item.subtitle)
                }
                .font(.subheadline)
                .foregroundColor(item.isCompleted ? completedTextColor : secondaryTextColor)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text("Today")
                }
                .font(.subheadline)
                .foregroundColor(item.isCompleted ? completedTextColor : secondaryTextColor)
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(timeFormatter.string(from: item.date))
                }
                .font(.subheadline)
                .foregroundColor(item.isCompleted ? completedTextColor : secondaryTextColor)
                
                Spacer()
                
                // Status badge
                Text(item.isCompleted ? "Completed" : "Active")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(item.isCompleted ? .green : .blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((item.isCompleted ? Color.green : Color.blue).opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 4)
        .opacity(item.isCompleted ? 0.6 : 1.0)
    }
}

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var homeItems: [HomeItem] = []
    @State private var supplementConsumptions: [SupplementConsumptionItem] = []
    @State private var showingAddItem = false
    @State private var editingItem: HomeItem?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var supplementStartDate: Date?

    private let supabaseManager = SupabaseManager.shared
    
    // Dynamic colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(red: 243/255, green: 243/255, blue: 248/255)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 51/255, green: 51/255, blue: 51/255)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color(red: 153/255, green: 153/255, blue: 153/255)
    }
    
    // Calculate dynamic day number
    private var dayNumber: Int {
        guard let startDate = supplementStartDate else { return 1 }
        let calendar = Calendar.current
        let today = Date()
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        return max(1, daysSinceStart + 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView("Loading home...")
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if homeItems.isEmpty && supplementConsumptions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "house")
                                .font(.system(size: 50))
                                .foregroundColor(secondaryTextColor)
                            Text("Welcome to your home")
                                .font(.title2)
                                .foregroundColor(secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            // Supplement Consumptions Section
                            if !supplementConsumptions.isEmpty {
                                Section(header: Text("Today's Supplements")
                                    .font(.headline)
                                    .foregroundColor(primaryTextColor)
                                    .padding(.bottom, 4)) {
                                    ForEach(supplementConsumptions) { item in
                                        SupplementConsumptionRowView(item: item, colorScheme: colorScheme)
                                            .listRowBackground(
                                                colorScheme == .dark ? Color(.systemGray6) : Color.white
                                            )
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(item.isConsumed ? "Mark Pending" : "Mark Taken") {
                                                    Task {
                                                        await toggleSupplementConsumption(item)
                                                    }
                                                }
                                                .tint(item.isConsumed ? .orange : .green)
                                            }
                                    }
                                }
                            }
                            
                            // Home Items Section
                            if !homeItems.isEmpty {
                                Section(header: Text("Home Activities")
                                    .font(.headline)
                                    .foregroundColor(primaryTextColor)
                                    .padding(.bottom, 4)) {
                                    ForEach(homeItems) { item in
                                        HomeItemRowView(item: item, colorScheme: colorScheme)
                                            .listRowBackground(
                                                colorScheme == .dark ? Color(.systemGray6) : Color.white
                                            )
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button("Delete") {
                                                    Task {
                                                        await deleteItem(item)
                                                    }
                                                }
                                                .tint(.red)
                                                
                                                Button(item.isCompleted ? "Undo" : "Mark as Done") {
                                                    Task {
                                                        await toggleItemCompletion(item)
                                                    }
                                                }
                                                .tint(item.isCompleted ? .orange : .green)
                                            }
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(backgroundColor)
                    }
                }
            }
            .navigationTitle("Day \(dayNumber)")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(nil) // Allow system to control color scheme
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                // Add Item Sheet
                NavigationStack {
                    VStack {
                        Text("Add Home Item")
                            .font(.title)
                            .foregroundColor(primaryTextColor)
                        Text("Feature coming soon...")
                            .foregroundColor(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(backgroundColor)
                    .navigationTitle("Add Item")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingAddItem = false
                            }
                        }
                    }
                }
            }
            .sheet(item: $editingItem) { item in
                // Edit Item Sheet
                NavigationStack {
                    VStack {
                        Text("Edit Home Item")
                            .font(.title)
                            .foregroundColor(primaryTextColor)
                        Text("Feature coming soon...")
                            .foregroundColor(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(backgroundColor)
                    .navigationTitle("Edit Item")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                editingItem = nil
                            }
                        }
                    }
                }
            }
            .task {
                await loadHomeItems()
                await loadSupplementConsumptions()
                await loadSupplementStartDate()
            }
            .refreshable {
                await loadHomeItems()
                await loadSupplementConsumptions()
                await loadSupplementStartDate()
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
    
    private func loadHomeItems() async {
        // Placeholder for home items loading
        // This would typically fetch from a database or API
        await MainActor.run {
            homeItems = []
        }
    }
    
    private func loadSupplementConsumptions() async {
        do {
            // Fetch today's supplements with their consumption status
            let supplementsWithConsumption = try await supabaseManager.fetchTodaysSupplementsWithConsumption()
            
            // Create supplement consumption items for all supplements
            supplementConsumptions = supplementsWithConsumption.map { (supplement, consumption) in
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: supplement.time)
                
                // If no consumption record exists, create a default one
                let effectiveConsumption = consumption ?? SupplementConsumption(
                    supplementId: supplement.id,
                    date: Date(),
                    isConsumed: false
                )
                
                return SupplementConsumptionItem(
                    consumption: effectiveConsumption,
                    supplementName: supplement.name,
                    quantity: supplement.quantity,
                    brand: supplement.brand,
                    timeToTake: timeString,
                    supplementId: supplement.id
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load supplement consumptions: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadSupplementStartDate() async {
        do {
            // Fetch all supplements to find the earliest created date
            let supplements = try await supabaseManager.fetchSupplements()
            
            // For now, we'll use today's date as the start date
            // In a real app, you'd want to store the user's start date in the database
            await MainActor.run {
                supplementStartDate = Calendar.current.startOfDay(for: Date())
            }
        } catch {
            await MainActor.run {
                supplementStartDate = Calendar.current.startOfDay(for: Date())
            }
        }
    }
    
    private func toggleItemCompletion(_ item: HomeItem) async {
        // Placeholder for toggling item completion
        // This would typically update the item in a database or API
    }
    
    private func toggleSupplementConsumption(_ item: SupplementConsumptionItem) async {
        do {
            // Use the new method to create or update consumption record
            try await supabaseManager.createOrUpdateTodaysConsumption(
                supplementId: item.supplementId,
                isConsumed: !item.isConsumed
            )
            await loadSupplementConsumptions() // Refresh the list
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update supplement consumption: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteItem(_ item: HomeItem) async {
        // Placeholder for deleting item
        // This would typically delete the item from a database or API
    }
}

#Preview {
    HomeView()
}