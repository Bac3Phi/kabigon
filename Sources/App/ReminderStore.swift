import Foundation
import UserNotifications
import KabigonCore

enum ReminderMode: String, Codable, CaseIterable, Identifiable {
    case interval
    case scheduled

    var id: String { rawValue }
}

struct ReminderItem: Codable, Identifiable, Equatable {
    let id: UUID
    var messages: [String]
    var mode: ReminderMode
    var minutes: Int
    var scheduledAt: Date
    var createdAt: Date

    var notificationIdentifier: String { "kabigon.reminder.\(id.uuidString)" }
    var displayMessage: String { messages.first ?? "" }

    init(id: UUID, messages: [String], mode: ReminderMode, minutes: Int, scheduledAt: Date, createdAt: Date) {
        self.id = id
        self.messages = messages
        self.mode = mode
        self.minutes = minutes
        self.scheduledAt = scheduledAt
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case message
        case messages
        case mode
        case minutes
        case scheduledAt
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        if let decodedMessages = try container.decodeIfPresent([String].self, forKey: .messages) {
            messages = decodedMessages
        } else if let legacyMessage = try container.decodeIfPresent(String.self, forKey: .message) {
            messages = [legacyMessage]
        } else {
            messages = []
        }
        mode = try container.decode(ReminderMode.self, forKey: .mode)
        minutes = try container.decode(Int.self, forKey: .minutes)
        scheduledAt = try container.decode(Date.self, forKey: .scheduledAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(mode, forKey: .mode)
        try container.encode(minutes, forKey: .minutes)
        try container.encode(scheduledAt, forKey: .scheduledAt)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

@MainActor
final class ReminderStore: ObservableObject {
    static let shared = ReminderStore()

    @Published private(set) var reminders: [ReminderItem] = []

    private let defaultsKey = "kabigon.reminders"
    private var timers: [UUID: Timer] = [:]

    private init() {
        load()
    }

    func start() {
        DispatchQueue.main.async { [weak self] in
            self?.scheduleAll()
        }
    }

    func add(messages text: String, mode: ReminderMode, minutes: Int, scheduledAt: Date) {
        let messages = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !messages.isEmpty else { return }
        let resolvedScheduledAt = mode == .scheduled && scheduledAt <= Date()
            ? Date().addingTimeInterval(60)
            : scheduledAt
        let reminder = ReminderItem(
            id: UUID(),
            messages: messages,
            mode: mode,
            minutes: max(1, minutes),
            scheduledAt: resolvedScheduledAt,
            createdAt: Date()
        )
        reminders.append(reminder)
        save()
        schedule(reminder)
    }

    func remove(_ reminder: ReminderItem) {
        timers[reminder.id]?.invalidate()
        timers[reminder.id] = nil
        reminders.removeAll { $0.id == reminder.id }
        save()
        guard NotificationManager.shared.isAvailable else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminder.notificationIdentifier]
        )
    }

    func scheduleAll() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()

        removePendingNotifications(for: reminders)
        reminders.forEach { schedule($0) }
    }

    private func schedule(_ reminder: ReminderItem) {
        schedulePetReminder(reminder)
        scheduleNotification(reminder)
    }

    private func schedulePetReminder(_ reminder: ReminderItem) {
        let delay: TimeInterval
        let repeats: Bool

        switch reminder.mode {
        case .interval:
            delay = TimeInterval(max(1, reminder.minutes)) * 60
            repeats = true
        case .scheduled:
            delay = reminder.scheduledAt.timeIntervalSinceNow
            repeats = false
        }

        guard delay > 0 else { return }

        let timer = Timer(timeInterval: delay, repeats: repeats) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fire(reminder)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timers[reminder.id] = timer
    }

    private func fire(_ reminder: ReminderItem) {
        guard reminders.contains(where: { $0.id == reminder.id }) else {
            timers[reminder.id]?.invalidate()
            timers[reminder.id] = nil
            return
        }

        let message = reminder.messages.randomElement() ?? reminder.displayMessage
        PetController.shared.reactToReminder(message: message)

        if reminder.mode == .scheduled {
            timers[reminder.id]?.invalidate()
            timers[reminder.id] = nil
            reminders.removeAll { $0.id == reminder.id }
            save()
        }
    }

    private func removePendingNotifications(for reminders: [ReminderItem]) {
        guard NotificationManager.shared.isAvailable else { return }
        let ids = reminders.map(\.notificationIdentifier)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func scheduleNotification(_ reminder: ReminderItem) {
        guard NotificationManager.shared.isAvailable else { return }

        let content = UNMutableNotificationContent()
        content.title = "Kabigon Reminder"
        content.body = reminder.messages.randomElement() ?? reminder.displayMessage

        let trigger: UNNotificationTrigger
        switch reminder.mode {
        case .interval:
            let interval = max(61, TimeInterval(max(1, reminder.minutes)) * 60)
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: true
            )
        case .scheduled:
            guard reminder.scheduledAt > Date() else { return }
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.scheduledAt
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: reminder.notificationIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(
            request,
            withCompletionHandler: Self.notificationScheduleCompleted
        )
    }

    nonisolated private static func notificationScheduleCompleted(_ error: Error?) {
        if let error {
            print("Failed to schedule Kabigon reminder: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? EventCoding.decoder.decode([ReminderItem].self, from: data)
        else { return }
        reminders = decoded
    }

    private func save() {
        guard let data = try? EventCoding.encoder.encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
