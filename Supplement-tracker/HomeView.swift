//
//  HomeView.swift
//  Supplement-tracker
//
//  Created by Karthik on 26/09/25.
//

import SwiftUI

// Model for tracking supplement consumption (Your existing model - unchanged)
struct SupplementConsumption: Identifiable, Codable {
    let id: UUID
    let supplementId: UUID
    let date: Date
    var isConsumed: Bool
    
    init(id: UUID = UUID(), supplementId: UUID, date: Date, isConsumed: Bool = false) {
        self.id = id
        self.supplementId = supplementId
        self.date = date
        self.isConsumed = isConsumed
    }
}

// Model for today's supplement schedule (Your existing model - unchanged)
struct TodaysSupplementItem: Identifiable {
    let id = UUID()
    let supplement: Supplement
    let scheduledTime: Date
    var isConsumed: Bool
    let consumptionId: UUID?
    
    // Computed property for formatted time display
    var timeToTake: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: scheduledTime)
    }
    
    static func == (lhs: TodaysSupplementItem, rhs: TodaysSupplementItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Updated Time period enum - removed Night period to match Figma design
enum TimePeriod: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    
    var timeRange: ClosedRange<Int> {
        switch self {
        case .morning: return 5...11
        case .afternoon: return 12...16
        case .evening: return 17...23
        }
    }
}

struct HomeView: View {
    // Mock data for preview and demonstration purposes
    @State private var todaysSupplements: [TodaysSupplementItem] = [
        // Morning supplements
        TodaysSupplementItem(supplement: Supplement(name: "Vitamin D3", quantity: "1000 IU", timesPerDay: 1, time: Date(), brand: "Nature Made"), scheduledTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(), isConsumed: true, consumptionId: UUID()),
        TodaysSupplementItem(supplement: Supplement(name: "Omega-3", quantity: "1 capsule", timesPerDay: 1, time: Date(), brand: "Nordic Naturals"), scheduledTime: Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date()) ?? Date(), isConsumed: false, consumptionId: nil),
        TodaysSupplementItem(supplement: Supplement(name: "Multivitamin", quantity: "1 tablet", timesPerDay: 1, time: Date(), brand: "Centrum"), scheduledTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(), isConsumed: false, consumptionId: nil),
        
        // Afternoon supplements
        TodaysSupplementItem(supplement: Supplement(name: "Protein Powder", quantity: "1 scoop", timesPerDay: 1, time: Date(), brand: "Optimum Nutrition"), scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date(), isConsumed: false, consumptionId: nil),
        TodaysSupplementItem(supplement: Supplement(name: "Creatine", quantity: "5g", timesPerDay: 1, time: Date(), brand: "Creapure"), scheduledTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date(), isConsumed: false, consumptionId: nil),
        
        // Evening supplements
        TodaysSupplementItem(supplement: Supplement(name: "Magnesium", quantity: "400mg", timesPerDay: 1, time: Date(), brand: "Nature's Bounty"), scheduledTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(), isConsumed: false, consumptionId: nil),
        TodaysSupplementItem(supplement: Supplement(name: "Melatonin", quantity: "3mg", timesPerDay: 1, time: Date(), brand: "Natrol"), scheduledTime: Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date()) ?? Date(), isConsumed: false, consumptionId: nil),
    ]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // MARK: - Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    // MARK: - Computed Properties for UI
    private var dynamicTitle: String {
        let now = Date()
        let dayString = dayFormatter.string(from: now)
        let hour = Calendar.current.component(.hour, from: now)
        
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<24: timeOfDay = "evening"
        default: timeOfDay = "morning"
        }
        
        return "\(dayString) \(timeOfDay)"
    }
    
    private var supplementCountText: String {
        let remainingCount = todaysSupplements.filter { !$0.isConsumed }.count
        return "\(remainingCount) Supplement\(remainingCount == 1 ? "" : "s") left"
    }
    
    // MARK: - Helper Methods
    private func supplementsForPeriod(_ period: TimePeriod) -> [TodaysSupplementItem] {
        return todaysSupplements.filter { item in
            let hour = Calendar.current.component(.hour, from: item.scheduledTime)
            return period.timeRange.contains(hour)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background color matching new Figma design
                Color(red: 243/255, green: 243/255, blue: 248/255) // #f3f3f8
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header section with new design
                        headerView
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 50)
                        } else if todaysSupplements.isEmpty {
                            emptyStateView
                        } else {
                            // Content sections
                            VStack(spacing: 16) {
                                ForEach(TimePeriod.allCases, id: \.self) { period in
                                    let supplements = supplementsForPeriod(period)
                                    if !supplements.isEmpty {
                                        SupplementSectionView(
                                            period: period.rawValue,
                                            supplements: supplements,
                                            onToggle: { item in
                                                toggleConsumption(for: item)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 34)
                    .padding(.bottom, 100) // Space for floating button
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            // Load supplements data when view appears
            await loadTodaysSupplements()
        }
        .refreshable {
            // Pull-to-refresh functionality
            await loadTodaysSupplements()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let msg = errorMessage { Text(msg) }
        }
    }
    
    // MARK: - Header View (Updated to match new Figma design)
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Main title
            Text(dynamicTitle)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)) // #333333
                .tracking(0.4)
            
            // Subtitle
            Text(supplementCountText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255)) // #999999
                .tracking(-0.25)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 100)
            Image(systemName: "pills.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No supplements for today")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("Add a new supplement to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var floatingActionButton: some View {
        Button(action: {
            // Action for adding new supplement
        }) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Business Logic
    
    /// Loads today's supplements from the database or local storage
    private func loadTodaysSupplements() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // In a real app, this would fetch from Supabase or Core Data
            // For now, we'll use the mock data but simulate loading
            await MainActor.run {
                // The mock data is already set, so we just stop loading
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load supplements: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Toggles the consumption status of a supplement
    private func toggleConsumption(for item: TodaysSupplementItem) {
        // Find the item in the array and toggle its consumption status
        if let index = todaysSupplements.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                todaysSupplements[index].isConsumed.toggle()
            }
            
            // Persist the change
            Task {
                await persistConsumptionChange(for: todaysSupplements[index])
            }
        }
    }
    
    /// Persists consumption changes to the database
    private func persistConsumptionChange(for item: TodaysSupplementItem) async {
        do {
            // In a real app, this would update Supabase or Core Data
            // For now, we'll simulate the API call
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Log the change for debugging
            print("Persisted consumption change for \(item.supplement.name): \(item.isConsumed)")
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
                
                // Revert the change on error
                if let index = todaysSupplements.firstIndex(where: { $0.id == item.id }) {
                    todaysSupplements[index].isConsumed.toggle()
                }
            }
        }
    }
    
    /// Refreshes the supplement data
    private func refreshData() {
        Task {
            await loadTodaysSupplements()
        }
    }
}

// MARK: - Section View (Updated design)
struct SupplementSectionView: View {
    let period: String
    let supplements: [TodaysSupplementItem]
    let onToggle: (TodaysSupplementItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with padding
            HStack {
                Text(period)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 140/255, green: 140/255, blue: 140/255)) // #8c8c8c
                    .tracking(-0.08)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Supplement cards
            VStack(spacing: 0) {
                ForEach(Array(supplements.enumerated()), id: \.element.id) { index, item in
                    TodaysSupplementRowView(item: item, onToggle: { onToggle(item) })
                    
                    // Divider between items (not after last item)
                    if index < supplements.count - 1 {
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color(red: 217/255, green: 217/255, blue: 217/255)) // #d9d9d9
                                .frame(height: 1)
                                .frame(width: 319)
                            Spacer()
                        }
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 26))
        }
    }
}

// MARK: - Row View (Updated design)
struct TodaysSupplementRowView: View {
    let item: TodaysSupplementItem
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Custom checkbox
                ZStack {
                    Circle()
                        .stroke(
                            item.isConsumed 
                                ? Color(red: 0/255, green: 122/255, blue: 255/255) // #007aff
                                : Color(red: 217/255, green: 217/255, blue: 217/255), // #d9d9d9
                            lineWidth: 2
                        )
                        .fill(
                            item.isConsumed 
                                ? Color(red: 0/255, green: 122/255, blue: 255/255) // #007aff
                                : Color.clear
                        )
                        .frame(width: 22, height: 22)
                    
                    if item.isConsumed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Supplement info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.supplement.name)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)) // #333333
                            .tracking(-0.41)
                            .strikethrough(item.isConsumed)
                        
                        Spacer()
                        
                        Text(item.supplement.quantity)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255)) // #999999
                            .tracking(-0.41)
                    }
                    
                    Text(item.timeToTake)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255)) // #999999
                        .tracking(-0.24)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}