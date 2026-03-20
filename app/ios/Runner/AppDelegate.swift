import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let widgetChannelName = "organiq.widget"
  private let appGroupID = "group.vxfontes.organiq"

  // UserDefaults keys (must match OrganiqWidgetSharedStore.swift)
  private let tasksKey                   = "widget_tasks_v1"
  private let pendingCompletedTaskIdsKey = "widget_pending_completed_task_ids_v1"
  private let dayProgressKey             = "widget_day_progress_v1"
  private let nextActionsKey             = "widget_next_actions_v1"
  private let remindersKey               = "widget_reminders_v1"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let registrar = registrar(forPlugin: "WidgetBridgePlugin") {
      setupWidgetBridgeChannel(messenger: registrar.messenger())
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Channel Setup

  private func setupWidgetBridgeChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: widgetChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "APP_DEALLOCATED", message: nil, details: nil))
        return
      }

      switch call.method {
      case "syncTasks":
        result(self.syncWidgetTasks(arguments: call.arguments))

      case "consumeCompletedTaskIds":
        result(self.consumeCompletedTaskIDs())

      case "syncDayProgress":
        result(self.syncWidgetDayProgress(arguments: call.arguments))

      case "syncNextActions":
        result(self.syncWidgetNextActions(arguments: call.arguments))

      case "syncReminders":
        result(self.syncWidgetReminders(arguments: call.arguments))

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Tasks

  private func syncWidgetTasks(arguments: Any?) -> Bool {
    guard
      let arguments = arguments as? [String: Any],
      let rawTasks = arguments["tasks"] as? [[String: Any]],
      let defaults = UserDefaults(suiteName: appGroupID)
    else { return false }

    let tasks = rawTasks.compactMap { item -> [String: Any]? in
      guard
        let id = item["id"] as? String, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let title = item["title"] as? String, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else { return nil }

      var mapped: [String: Any] = [
        "id": id,
        "title": title,
        "done": item["done"] as? Bool ?? false,
      ]
      if let dueAt = item["dueAt"] as? String { mapped["dueAt"] = dueAt }
      if let flagName = item["flagName"] as? String { mapped["flagName"] = flagName }
      if let flagColor = item["flagColor"] as? String { mapped["flagColor"] = flagColor }
      return mapped
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: tasks)
      defaults.set(data, forKey: tasksKey)
      reloadAllWidgetTimelines()
      return true
    } catch {
      print("WidgetBridge.syncTasks serialization failed: \(error)")
      return false
    }
  }

  private func consumeCompletedTaskIDs() -> [String] {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
    let ids = (defaults.stringArray(forKey: pendingCompletedTaskIdsKey) ?? [])
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    defaults.removeObject(forKey: pendingCompletedTaskIdsKey)
    return ids
  }

  // MARK: - Day Progress

  private func syncWidgetDayProgress(arguments: Any?) -> Bool {
    guard
      let arguments = arguments as? [String: Any],
      let defaults = UserDefaults(suiteName: appGroupID)
    else { return false }

    let payload: [String: Any] = [
      "percent":       arguments["percent"]       as? Double ?? 0.0,
      "tasksDone":     arguments["tasksDone"]     as? Int    ?? 0,
      "tasksTotal":    arguments["tasksTotal"]    as? Int    ?? 0,
      "routinesDone":  arguments["routinesDone"]  as? Int    ?? 0,
      "routinesTotal": arguments["routinesTotal"] as? Int    ?? 0,
      "remindersDone": arguments["remindersDone"] as? Int    ?? 0,
      "remindersTotal":arguments["remindersTotal"]as? Int    ?? 0,
    ]

    do {
      let data = try JSONSerialization.data(withJSONObject: payload)
      defaults.set(data, forKey: dayProgressKey)
      reloadAllWidgetTimelines()
      return true
    } catch {
      print("WidgetBridge.syncDayProgress serialization failed: \(error)")
      return false
    }
  }

  // MARK: - Next Actions

  private func syncWidgetNextActions(arguments: Any?) -> Bool {
    guard
      let arguments = arguments as? [String: Any],
      let rawItems = arguments["items"] as? [[String: Any]],
      let defaults = UserDefaults(suiteName: appGroupID)
    else { return false }

    let items = rawItems.compactMap { item -> [String: Any]? in
      guard
        let id    = item["id"]    as? String, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let title = item["title"] as? String, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let type  = item["type"]  as? String
      else { return nil }

      var mapped: [String: Any] = [
        "id":          id,
        "title":       title,
        "type":        type,
        "isCompleted": item["isCompleted"] as? Bool ?? false,
        "isOverdue":   item["isOverdue"]   as? Bool ?? false,
      ]
      if let t = item["scheduledTime"]    as? String { mapped["scheduledTime"]    = t }
      if let t = item["endScheduledTime"] as? String { mapped["endScheduledTime"] = t }
      if let subtitle = item["subtitle"] as? String { mapped["subtitle"] = subtitle }
      if let accentColor = item["accentColor"] as? String { mapped["accentColor"] = accentColor }
      return mapped
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: items)
      defaults.set(data, forKey: nextActionsKey)
      reloadAllWidgetTimelines()
      return true
    } catch {
      print("WidgetBridge.syncNextActions serialization failed: \(error)")
      return false
    }
  }

  // MARK: - Reminders

  private func syncWidgetReminders(arguments: Any?) -> Bool {
    guard
      let arguments = arguments as? [String: Any],
      let rawReminders = arguments["reminders"] as? [[String: Any]],
      let defaults = UserDefaults(suiteName: appGroupID)
    else { return false }

    let reminders = rawReminders.compactMap { item -> [String: Any]? in
      guard
        let id    = item["id"]    as? String, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let title = item["title"] as? String, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else { return nil }

      var mapped: [String: Any] = ["id": id, "title": title]
      if let t = item["remindAt"] as? String { mapped["remindAt"] = t }
      return mapped
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: reminders)
      defaults.set(data, forKey: remindersKey)
      reloadAllWidgetTimelines()
      return true
    } catch {
      print("WidgetBridge.syncReminders serialization failed: \(error)")
      return false
    }
  }

  // MARK: - Helpers

  private func reloadAllWidgetTimelines() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}
