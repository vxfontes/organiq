import Foundation
import WidgetKit

struct OrganiqWidgetTask: Codable, Identifiable {
  let id: String
  let title: String
  var done: Bool
  let dueAt: String?
  let flagName: String?
  let flagColor: String?

  init(
    id: String,
    title: String,
    done: Bool,
    dueAt: String? = nil,
    flagName: String? = nil,
    flagColor: String? = nil
  ) {
    self.id = id
    self.title = title
    self.done = done
    self.dueAt = dueAt
    self.flagName = flagName
    self.flagColor = flagColor
  }
}

struct DayProgressData: Codable {
  let percent: Double
  let tasksDone: Int
  let tasksTotal: Int
  let routinesDone: Int
  let routinesTotal: Int
  let remindersDone: Int
  let remindersTotal: Int
}

struct NextActionData: Codable, Identifiable {
  let id: String
  let title: String
  let type: String
  let scheduledTime: String?
  let endScheduledTime: String?
  let subtitle: String?
  let accentColor: String?
  let isCompleted: Bool
  let isOverdue: Bool

  init(
    id: String,
    title: String,
    type: String,
    scheduledTime: String?,
    endScheduledTime: String?,
    subtitle: String? = nil,
    accentColor: String? = nil,
    isCompleted: Bool,
    isOverdue: Bool
  ) {
    self.id = id
    self.title = title
    self.type = type
    self.scheduledTime = scheduledTime
    self.endScheduledTime = endScheduledTime
    self.subtitle = subtitle
    self.accentColor = accentColor
    self.isCompleted = isCompleted
    self.isOverdue = isOverdue
  }
}

struct ReminderWidgetData: Codable, Identifiable {
  let id: String
  let title: String
  let remindAt: String?
}

enum OrganiqWidgetSharedStore {
  static let appGroupID = "group.vxfontes.organiq"

  private static let tasksKey                    = "widget_tasks_v1"
  private static let pendingCompletedTaskIDsKey = "widget_pending_completed_task_ids_v1"
  private static let dayProgressKey             = "widget_day_progress_v1"
  private static let nextActionsKey             = "widget_next_actions_v1"
  private static let remindersKey               = "widget_reminders_v1"

  static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

  static func loadTasks() -> [OrganiqWidgetTask] {
    guard let defaults = defaults,
          let data = defaults.data(forKey: tasksKey),
          let decoded = try? JSONDecoder().decode([OrganiqWidgetTask].self, from: data)
    else { return [] }
    return decoded
  }

  static func saveTasks(_ tasks: [OrganiqWidgetTask]) {
    guard let defaults = defaults, let data = try? JSONEncoder().encode(tasks) else { return }
    defaults.set(data, forKey: tasksKey)
  }

  static func markTaskAsDone(taskID: String) {
    let clean = taskID.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let defaults = defaults, !clean.isEmpty else { return }

    var tasks = loadTasks()
    guard let index = tasks.firstIndex(where: { $0.id == clean }) else { return }
    tasks[index].done = true
    saveTasks(tasks)

    var pendingIDs = defaults.stringArray(forKey: pendingCompletedTaskIDsKey) ?? []
    if !pendingIDs.contains(clean) {
      pendingIDs.append(clean)
      defaults.set(pendingIDs, forKey: pendingCompletedTaskIDsKey)
    }
  }

  static func consumeCompletedTaskIDs() -> [String] {
    guard let defaults = defaults else { return [] }
    let ids = (defaults.stringArray(forKey: pendingCompletedTaskIDsKey) ?? [])
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    defaults.removeObject(forKey: pendingCompletedTaskIDsKey)
    return ids
  }

  static func loadDayProgress() -> DayProgressData? {
    guard let defaults = defaults,
          let data = defaults.data(forKey: dayProgressKey),
          let decoded = try? JSONDecoder().decode(DayProgressData.self, from: data)
    else { return nil }
    return decoded
  }

  static func saveDayProgress(_ progress: DayProgressData) {
    guard let defaults = defaults, let data = try? JSONEncoder().encode(progress) else { return }
    defaults.set(data, forKey: dayProgressKey)
  }

  static func loadNextActions() -> [NextActionData] {
    guard let defaults = defaults,
          let data = defaults.data(forKey: nextActionsKey),
          let decoded = try? JSONDecoder().decode([NextActionData].self, from: data)
    else { return [] }
    return decoded
  }

  static func saveNextActions(_ items: [NextActionData]) {
    guard let defaults = defaults, let data = try? JSONEncoder().encode(items) else { return }
    defaults.set(data, forKey: nextActionsKey)
  }

  static func loadReminders() -> [ReminderWidgetData] {
    guard let defaults = defaults,
          let data = defaults.data(forKey: remindersKey),
          let decoded = try? JSONDecoder().decode([ReminderWidgetData].self, from: data)
    else { return [] }
    return decoded
  }

  static func saveReminders(_ items: [ReminderWidgetData]) {
    guard let defaults = defaults, let data = try? JSONEncoder().encode(items) else { return }
    defaults.set(data, forKey: remindersKey)
  }

  static func reloadAll() {
    WidgetCenter.shared.reloadAllTimelines()
  }
}
