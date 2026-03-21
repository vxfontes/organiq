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
  let routinesOverdue: Int
  let remindersDone: Int
  let remindersTotal: Int
  let eventsDone: Int
  let eventsTotal: Int

  init(
    percent: Double,
    tasksDone: Int,
    tasksTotal: Int,
    routinesDone: Int,
    routinesTotal: Int,
    routinesOverdue: Int = 0,
    remindersDone: Int,
    remindersTotal: Int,
    eventsDone: Int = 0,
    eventsTotal: Int = 0
  ) {
    self.percent = percent
    self.tasksDone = tasksDone
    self.tasksTotal = tasksTotal
    self.routinesDone = routinesDone
    self.routinesTotal = routinesTotal
    self.routinesOverdue = routinesOverdue
    self.remindersDone = remindersDone
    self.remindersTotal = remindersTotal
    self.eventsDone = eventsDone
    self.eventsTotal = eventsTotal
  }

  enum CodingKeys: String, CodingKey {
    case percent, tasksDone, tasksTotal, routinesDone, routinesTotal
    case routinesOverdue, remindersDone, remindersTotal, eventsDone, eventsTotal
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    percent = try container.decodeIfPresent(Double.self, forKey: .percent) ?? 0
    tasksDone = try container.decodeIfPresent(Int.self, forKey: .tasksDone) ?? 0
    tasksTotal = try container.decodeIfPresent(Int.self, forKey: .tasksTotal) ?? 0
    routinesDone = try container.decodeIfPresent(Int.self, forKey: .routinesDone) ?? 0
    routinesTotal = try container.decodeIfPresent(Int.self, forKey: .routinesTotal) ?? 0
    routinesOverdue = try container.decodeIfPresent(Int.self, forKey: .routinesOverdue) ?? 0
    remindersDone = try container.decodeIfPresent(Int.self, forKey: .remindersDone) ?? 0
    remindersTotal = try container.decodeIfPresent(Int.self, forKey: .remindersTotal) ?? 0
    eventsDone = try container.decodeIfPresent(Int.self, forKey: .eventsDone) ?? 0
    eventsTotal = try container.decodeIfPresent(Int.self, forKey: .eventsTotal) ?? 0
  }
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

struct NowPlayingItemData: Codable {
  let id: String
  let title: String
  let type: String
  let scheduledTime: String?
  let endScheduledTime: String?
  let subtitle: String?
  let accentColor: String?
  let isCompleted: Bool
  let isOverdue: Bool
}

struct NowPlayingData: Codable {
  let current: NowPlayingItemData?
  let next: NowPlayingItemData?
  let upcoming: [NowPlayingItemData]

  init(
    current: NowPlayingItemData?,
    next: NowPlayingItemData?,
    upcoming: [NowPlayingItemData] = []
  ) {
    self.current = current
    self.next = next
    self.upcoming = upcoming
  }

  enum CodingKeys: String, CodingKey {
    case current, next, upcoming
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    current = try container.decodeIfPresent(NowPlayingItemData.self, forKey: .current)
    next = try container.decodeIfPresent(NowPlayingItemData.self, forKey: .next)
    if let upcomingDecoded = try container.decodeIfPresent([NowPlayingItemData].self, forKey: .upcoming) {
      upcoming = upcomingDecoded
    } else if let next {
      upcoming = [next]
    } else {
      upcoming = []
    }
  }
}

enum OrganiqWidgetSharedStore {
  static let appGroupID = "group.vxfontes.organiq"

  private static let tasksKey                    = "widget_tasks_v1"
  private static let pendingCompletedTaskIDsKey = "widget_pending_completed_task_ids_v1"
  private static let dayProgressKey             = "widget_day_progress_v1"
  private static let nextActionsKey             = "widget_next_actions_v1"
  private static let remindersKey               = "widget_reminders_v1"
  private static let nowPlayingKey              = "widget_now_playing_v1"

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

  static func loadNowPlaying() -> NowPlayingData? {
    guard let defaults = defaults,
          let data = defaults.data(forKey: nowPlayingKey),
          let decoded = try? JSONDecoder().decode(NowPlayingData.self, from: data)
    else { return nil }
    return decoded
  }

  static func saveNowPlaying(_ payload: NowPlayingData) {
    guard let defaults = defaults, let data = try? JSONEncoder().encode(payload) else { return }
    defaults.set(data, forKey: nowPlayingKey)
  }

  static func reloadAll() {
    WidgetCenter.shared.reloadAllTimelines()
  }
}
