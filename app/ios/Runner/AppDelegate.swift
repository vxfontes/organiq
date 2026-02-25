import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let widgetChannelName = "inbota.widget"
  private let widgetKind = "InbotaWidget"
  private let appGroupID = "group.com.vxfontes.inbota"
  private let tasksStorageKey = "widget_tasks_v1"
  private let pendingCompletedTaskIdsStorageKey = "widget_pending_completed_task_ids_v1"

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
        let didSync = self.syncWidgetTasks(arguments: call.arguments)
        result(didSync)
      case "consumeCompletedTaskIds":
        result(self.consumeCompletedTaskIDs())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func syncWidgetTasks(arguments: Any?) -> Bool {
    guard
      let arguments = arguments as? [String: Any],
      let rawTasks = arguments["tasks"] as? [[String: Any]],
      let defaults = UserDefaults(suiteName: appGroupID)
    else {
      return false
    }

    let tasks = rawTasks.compactMap { item -> [String: Any]? in
      guard
        let id = item["id"] as? String,
        !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let title = item["title"] as? String,
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        return nil
      }

      let done = item["done"] as? Bool ?? false

      return [
        "id": id,
        "title": title,
        "done": done,
      ]
    }

    guard let data = try? JSONSerialization.data(withJSONObject: tasks, options: []) else {
      return false
    }

    defaults.set(data, forKey: tasksStorageKey)
    reloadWidgetTimeline()
    return true
  }

  private func consumeCompletedTaskIDs() -> [String] {
    guard let defaults = UserDefaults(suiteName: appGroupID) else {
      return []
    }

    let ids = (defaults.stringArray(forKey: pendingCompletedTaskIdsStorageKey) ?? [])
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    defaults.removeObject(forKey: pendingCompletedTaskIdsStorageKey)
    return ids
  }

  private func reloadWidgetTimeline() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
  }
}
