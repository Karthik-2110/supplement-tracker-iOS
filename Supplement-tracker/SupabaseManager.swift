import Foundation
import Supabase

// MARK: - Data Models

// Supplement consumption tracking model
struct SupplementConsumption: Identifiable, Codable {
    let id: UUID
    var supplementId: UUID
    var date: Date
    var isConsumed: Bool
    
    init(id: UUID = UUID(), supplementId: UUID, date: Date, isConsumed: Bool = false) {
        self.id = id
        self.supplementId = supplementId
        self.date = date
        self.isConsumed = isConsumed
    }
}

// Home item model for tracking various home activities
struct HomeItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var subtitle: String
    var category: String
    var date: Date
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, subtitle: String, category: String, date: Date = Date(), isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.date = date
        self.isCompleted = isCompleted
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    
    // Date formatter for time conversion
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private init() {
        let url = URL(string: "https://uhbunrlcsrwxzzhpimkn.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoYnVucmxjc3J3eHp6aHBpbWtuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDEwOTYsImV4cCI6MjA3NDUxNzA5Nn0.SMzPC6sKczM13-qh3yEw-TokaiDIp1ppMSbyUfvo8sI"
        
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
    
    // MARK: - Supplement CRUD Operations
    
    /// Fetch all supplements from the database
    func fetchSupplements() async throws -> [Supplement] {
        let response: [SupplementDB] = try await client
            .from("supplements")
            .select()
            .execute()
            .value
        
        return response.map { dbSupplement in
            // Parse interval
            let interval = SupplementInterval(rawValue: dbSupplement.interval) ?? .daily
            
            // Parse weekly schedule if available
            var weeklySchedule = WeeklySchedule()
            if let scheduleString = dbSupplement.weekly_schedule,
               let scheduleData = scheduleString.data(using: .utf8) {
                do {
                    weeklySchedule = try JSONDecoder().decode(WeeklySchedule.self, from: scheduleData)
                } catch {
                    // If parsing fails, use default empty schedule
                    weeklySchedule = WeeklySchedule()
                }
            }
            
            return Supplement(
                id: dbSupplement.id,
                name: dbSupplement.name,
                quantity: dbSupplement.quantity,
                timesPerDay: dbSupplement.times_per_day,
                time: timeFormatter.date(from: dbSupplement.time_to_take) ?? Date(),
                brand: dbSupplement.brand,
                interval: interval,
                weeklySchedule: weeklySchedule
            )
        }
    }
    
    /// Add a new supplement to the database
    func addSupplement(_ supplement: Supplement) async throws {
        // Encode weekly schedule to JSON string if needed
        var weeklyScheduleString: String? = nil
        if supplement.interval == .weekly {
            do {
                let scheduleData = try JSONEncoder().encode(supplement.weeklySchedule)
                weeklyScheduleString = String(data: scheduleData, encoding: .utf8)
            } catch {
                // If encoding fails, set to nil
                weeklyScheduleString = nil
            }
        }
        
        let dbSupplement = SupplementDB(
            id: supplement.id,
            name: supplement.name,
            quantity: supplement.quantity,
            times_per_day: supplement.timesPerDay,
            time_to_take: timeFormatter.string(from: supplement.time),
            brand: supplement.brand,
            interval: supplement.interval.rawValue,
            weekly_schedule: weeklyScheduleString,
            created_at: Date(),
            updated_at: Date()
        )
        
        try await client
            .from("supplements")
            .insert(dbSupplement)
            .execute()
    }
    
    /// Update an existing supplement in the database
    func updateSupplement(_ supplement: Supplement) async throws {
        // Encode weekly schedule to JSON string if needed
        var weeklyScheduleString: String? = nil
        if supplement.interval == .weekly {
            do {
                let scheduleData = try JSONEncoder().encode(supplement.weeklySchedule)
                weeklyScheduleString = String(data: scheduleData, encoding: .utf8)
            } catch {
                // If encoding fails, set to nil
                weeklyScheduleString = nil
            }
        }
        
        let dbSupplement = SupplementDB(
            id: supplement.id,
            name: supplement.name,
            quantity: supplement.quantity,
            times_per_day: supplement.timesPerDay,
            time_to_take: timeFormatter.string(from: supplement.time),
            brand: supplement.brand,
            interval: supplement.interval.rawValue,
            weekly_schedule: weeklyScheduleString,
            created_at: nil, // Don't update created_at
            updated_at: Date()
        )
        
        try await client
            .from("supplements")
            .update(dbSupplement)
            .eq("id", value: supplement.id)
            .execute()
    }
    
    /// Delete a supplement from the database
    func deleteSupplement(id: UUID) async throws {
        try await client
            .from("supplements")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Consumption Tracking Operations
    
    /// Fetch today's consumption records
    func fetchTodaysConsumptions() async throws -> [SupplementConsumption] {
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        
        // Format date as YYYY-MM-DD for the date column
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        
        let response: [ConsumptionDB] = try await client
            .from("supplement_consumption")
            .select()
            .eq("date", value: todayString)
            .execute()
            .value
        
        return response.map { dbConsumption in
            SupplementConsumption(
                id: dbConsumption.id,
                supplementId: dbConsumption.supplement_id,
                date: dateFormatter.date(from: dbConsumption.date) ?? Date(),
                isConsumed: dbConsumption.is_consumed
            )
        }
    }
    
    /// Fetch today's supplements with their consumption status
    func fetchTodaysSupplementsWithConsumption() async throws -> [(supplement: Supplement, consumption: SupplementConsumption?)] {
        let supplements = try await fetchSupplements()
        let consumptions = try await fetchTodaysConsumptions()
        
        return supplements.map { supplement in
            let consumption = consumptions.first { $0.supplementId == supplement.id }
            return (supplement: supplement, consumption: consumption)
        }
    }
    
    /// Save a new consumption record
    func saveConsumption(_ consumption: SupplementConsumption) async throws {
        // Format date as YYYY-MM-DD for the date column
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dbConsumption = ConsumptionDB(
            id: consumption.id,
            supplement_id: consumption.supplementId,
            date: dateFormatter.string(from: consumption.date),
            is_consumed: consumption.isConsumed,
            created_at: Date(),
            updated_at: Date()
        )
        
        try await client
            .from("supplement_consumption")
            .insert(dbConsumption)
            .execute()
    }
    
    /// Update an existing consumption record
    func updateConsumption(id: UUID, isConsumed: Bool) async throws {
        struct UpdateData: Codable {
            let is_consumed: Bool
            let updated_at: String
        }
        
        let updateData = UpdateData(
            is_consumed: isConsumed,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("supplement_consumption")
            .update(updateData)
            .eq("id", value: id)
            .execute()
    }
    
    /// Delete a consumption record
    func deleteConsumption(id: UUID) async throws {
        try await client
            .from("supplement_consumption")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    /// Create or update today's consumption record for a supplement
    func createOrUpdateTodaysConsumption(supplementId: UUID, isConsumed: Bool) async throws {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        
        // Check if consumption record exists for today
        let existingConsumptions: [ConsumptionDB] = try await client
            .from("supplement_consumption")
            .select()
            .eq("supplement_id", value: supplementId)
            .eq("date", value: todayString)
            .execute()
            .value
        
        if let existingConsumption = existingConsumptions.first {
            // Update existing record
            try await updateConsumption(id: existingConsumption.id, isConsumed: isConsumed)
        } else {
            // Create new record
            let newConsumption = SupplementConsumption(
                supplementId: supplementId,
                date: today,
                isConsumed: isConsumed
            )
            try await saveConsumption(newConsumption)
        }
    }
    
    // MARK: - Home Items CRUD Operations

    /// Fetch all home items from the database
    func fetchHomeItems() async throws -> [HomeItem] {
        let response: [HomeItemDB] = try await client
            .from("home_items")
            .select()
            .execute()
            .value
        
        return response.map { dbItem in
            HomeItem(
                id: dbItem.id,
                title: dbItem.title,
                subtitle: dbItem.subtitle,
                category: dbItem.category,
                date: ISO8601DateFormatter().date(from: dbItem.date) ?? Date(),
                isCompleted: dbItem.is_completed
            )
        }
    }

    /// Add a new home item to the database
    func addHomeItem(_ item: HomeItem) async throws {
        let dbItem = HomeItemDB(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            category: item.category,
            date: ISO8601DateFormatter().string(from: item.date),
            is_completed: item.isCompleted,
            created_at: nil,
            updated_at: nil
        )
        
        try await client
            .from("home_items")
            .insert(dbItem)
            .execute()
    }

    /// Update a home item's completion status
    func updateHomeItemCompletion(id: UUID, isCompleted: Bool) async throws {
        struct UpdateData: Codable {
            let is_completed: Bool
            let updated_at: String
        }
        
        let updateData = UpdateData(
            is_completed: isCompleted,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("home_items")
            .update(updateData)
            .eq("id", value: id)
            .execute()
    }

    /// Delete a home item
    func deleteHomeItem(id: UUID) async throws {
        try await client
            .from("home_items")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Database Model

// Database model for home items
struct HomeItemDB: Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let category: String
    let date: String // ISO8601 formatted date string
    let is_completed: Bool
    let created_at: Date?
    let updated_at: Date?
}

// Database model for supplement consumption
struct ConsumptionDB: Codable {
    let id: UUID
    let supplement_id: UUID
    let date: String // ISO8601 formatted date string
    let is_consumed: Bool
    let created_at: Date?
    let updated_at: Date?
}

// Database model for supplements
struct SupplementDB: Codable {
    let id: UUID
    let name: String
    let quantity: String
    let times_per_day: Int
    let time_to_take: String
    let brand: String
    let interval: String // "daily" or "weekly"
    let weekly_schedule: String? // JSON string for weekly schedule
    let created_at: Date?
    let updated_at: Date?
}