//
//  HabitViewModel.swift
//  Hapit Tracker
//
//  Created by Omar Abdulrahman on 25/10/2022.
//

import SwiftUI
import CoreData
import UserNotifications

class HabitViewModel: ObservableObject {
    
    @Published var addNewHabit: Bool = false
    
    @Published var title: String = ""
    @Published var habitColor: String = "card-1"
    @Published var weekDays: [String] = []
    @Published var isReminderOn: Bool = false
    @Published var reminderText: String = ""
    @Published var reminderDate: Date = Date()
    
    @Published var showTimePicker: Bool = false
    
    @Published var editHabit: Habit?
    
    @Published var notificationStatus: Bool = false
    
    init() {
        requestNotificationAccess()
    }
    
    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { status, _ in
            DispatchQueue.main.async {
                self.notificationStatus = status
            }
        }
    }
    
    func addHabitToDB(context: NSManagedObjectContext) async -> Bool {
        let habit = Habit(context: context)
        
        habit.title = title
        habit.color = habitColor
        habit.weekDays = weekDays
        habit.isReminderOn = isReminderOn
        habit.reminderText = reminderText
        habit.notificationDate = reminderDate
        habit.notificationsIDs = []
        
        if isReminderOn {
            if let ids = try? await scheduleNotifications() {
                habit.notificationsIDs = ids
                
                if let _ = try? context.save() {
                    return true
                }
            }
        } else {
            if let _ = try? context.save() {
                return true
            }
        }
        
        return false
    }
    
    func deleteHabitFromDB(context: NSManagedObjectContext) -> Bool {
        if let editHabit = editHabit {
            context.delete(editHabit)
            if let _ = try? context.save() {
                return true
            }
        }
        
        return false
    }
    
    func scheduleNotifications() async throws -> [String] {
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.subtitle = reminderText
        content.attachments = [try .init(identifier: "hello", url: URL(fileURLWithPath: "google.com"))]
        content.sound = UNNotificationSound.default
        
        var notificationsIDs: [String] = []
        let calender = Calendar.current

        let weekDaySymbles: [String] = calender.weekdaySymbols
        
        for weekDay in weekDays {
            let id = UUID().uuidString
            let hour = calender.component(.hour, from: reminderDate)
            let min = calender.component(.minute, from: reminderDate)
            let day = weekDaySymbles.firstIndex { currentDay in
                return currentDay == weekDay
            } ?? -1

            if day != -1 {
                var components = DateComponents()
                components.hour = hour
                components.minute = min
                components.weekday = day + 1
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                try await UNUserNotificationCenter.current().add(request)
                
                notificationsIDs.append(id)
            }
        }
        
        return notificationsIDs
    }
    
    func resetData() {
        title = ""
        habitColor = "card-1"
        weekDays = []
        isReminderOn = false
        reminderDate = Date()
        reminderText = ""
    }
    
    func restoreEditData() {
        if let editHabit = editHabit {
            title = editHabit.title ?? ""
            habitColor = editHabit.color ?? "card-1"
            weekDays = editHabit.weekDays ?? []
            isReminderOn = editHabit.isReminderOn
            reminderDate = editHabit.notificationDate ?? Date()
            reminderText =  editHabit.reminderText ?? ""
        }
    }
    
    func doneStatus() -> Bool {
        let reminderStatus = isReminderOn ? reminderText == "" : false
        
        if title == "" || weekDays.isEmpty || reminderStatus {
            return false
        }
        
        return true
    }
}
