import Foundation
import Combine
import EventKit
import SwiftUI

@MainActor
class CalendarService: ObservableObject {
    @Published var upcomingEvents: [CalendarEvent] = []
    
    private let store = EKEventStore()
    private var timer: Timer?
    
    init() {
        requestAccess()
    }
    
    func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, error in
                if granted {
                    DispatchQueue.main.async { self?.startPolling() }
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, error in
                if granted {
                    DispatchQueue.main.async { self?.startPolling() }
                }
            }
        }
    }
    
    private func startPolling() {
        fetchEvents()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.fetchEvents()
            }
        }
    }
    
    private func fetchEvents() {
        let calendars = store.calendars(for: .event)
        
        let now = Date()
        guard let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now) else { return }
        
        let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: calendars)
        let events = store.events(matching: predicate)
            .filter { $0.endDate > now } // Geçmiş eventleri gösterme
            .sorted { $0.startDate < $1.startDate }
        
        self.upcomingEvents = events.prefix(3).map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier,
                title: ekEvent.title,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                isAllDay: ekEvent.isAllDay,
                color: Color(nsColor: ekEvent.calendar.color)
            )
        }
    }
}
