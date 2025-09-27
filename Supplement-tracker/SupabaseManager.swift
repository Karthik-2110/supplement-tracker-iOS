import Foundation
import Supabase

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
}

// MARK: - Database Model
/// Database model that matches the// Database model for Supabase
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