import SwiftUI
import WidgetKit
import AppIntents

struct OrganiqWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [OrganiqWidgetTask]
}

struct OrganiqWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> OrganiqWidgetEntry {
        OrganiqWidgetEntry(
            date: Date(),
            tasks: [
                OrganiqWidgetTask(id: "1", title: "Comprar pao", done: false),
                OrganiqWidgetTask(id: "2", title: "Pagar conta", done: false),
                OrganiqWidgetTask(id: "3", title: "Ligar para clinica", done: true),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (OrganiqWidgetEntry) -> Void) {
        completion(
            OrganiqWidgetEntry(
                date: Date(),
                tasks: OrganiqWidgetSharedStore.loadTasks()
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OrganiqWidgetEntry>) -> Void) {
        let tasks = OrganiqWidgetSharedStore.loadTasks()
        let entry = OrganiqWidgetEntry(date: Date(), tasks: tasks)
        let entries = [entry]
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

struct OrganiqWidgetEntryView: View {
    var entry: OrganiqWidgetTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Organiq")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.organiqText)

            Text("Seu dia em ordem")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.organiqTextMuted)

            if entry.tasks.isEmpty {
                Spacer()
                Text("Sem tarefas pendentes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.organiqPrimary700)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.organiqPrimary200)
                    )
            } else {
                ForEach(entry.tasks.prefix(4)) { task in
                    taskRow(task)
                }
            }
        }
        .padding(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.organiqBorder, lineWidth: 1)
        )
        .widgetContainerBackground(
            Color.organiqBackground
        )
    }

    @ViewBuilder
    private func taskRow(_ task: OrganiqWidgetTask) -> some View {
        HStack(spacing: 8) {
            if #available(iOS 17.0, *) {
                Button(intent: CompleteTaskIntent(taskID: task.id)) {
                    Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(task.done ? .organiqSuccess600 : .organiqPrimary700)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(task.done ? .organiqSuccess600 : .organiqPrimary700)
            }

            Text(task.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(task.done ? .organiqTextMuted : .organiqText)
                .strikethrough(task.done, color: .organiqTextMuted)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.organiqSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.organiqBorder, lineWidth: 1)
        )
    }
}

struct OrganiqWidget: Widget {
    let kind: String = "OrganiqWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrganiqWidgetTimelineProvider()) { entry in
            OrganiqWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Organiq")
        .description("Mostra um resumo rápido do seu dia.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct OrganiqWidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    var done: Bool
}

enum OrganiqWidgetSharedStore {
    private static let appGroupID = "group.com.vxfontes.organiq"
    private static let tasksStorageKey = "widget_tasks_v1"
    private static let pendingCompletedTaskIDsStorageKey = "widget_pending_completed_task_ids_v1"

    static func loadTasks() -> [OrganiqWidgetTask] {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: tasksStorageKey),
            let decoded = try? JSONDecoder().decode([OrganiqWidgetTask].self, from: data)
        else {
            return []
        }

        return decoded
    }

    static func markTaskAsDone(taskID: String) {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            !taskID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }

        tasks[index].done = true
        if let data = try? JSONEncoder().encode(tasks) {
            defaults.set(data, forKey: tasksStorageKey)
        }

        var pendingTaskIDs = defaults.stringArray(forKey: pendingCompletedTaskIDsStorageKey) ?? []
        if !pendingTaskIDs.contains(taskID) {
            pendingTaskIDs.append(taskID)
            defaults.set(pendingTaskIDs, forKey: pendingCompletedTaskIDsStorageKey)
        }
    }
}

@available(iOS 17.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Concluir tarefa"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        OrganiqWidgetSharedStore.markTaskAsDone(taskID: taskID)
        WidgetCenter.shared.reloadTimelines(ofKind: "OrganiqWidget")
        return .result()
    }
}

private extension View {
    @ViewBuilder
    func widgetContainerBackground<Background: View>(_ background: Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            self.background(background)
        }
    }
}

private extension Color {
    static let organiqBackground = Color(red: 250.0 / 255.0, green: 250.0 / 255.0, blue: 250.0 / 255.0)
    static let organiqSurface = Color(red: 1, green: 1, blue: 1)
    static let organiqBorder = Color(red: 229.0 / 255.0, green: 231.0 / 255.0, blue: 235.0 / 255.0)
    static let organiqText = Color(red: 17.0 / 255.0, green: 24.0 / 255.0, blue: 39.0 / 255.0)
    static let organiqTextMuted = Color(red: 107.0 / 255.0, green: 114.0 / 255.0, blue: 128.0 / 255.0)
    static let organiqPrimary700 = Color(red: 15.0 / 255.0, green: 118.0 / 255.0, blue: 110.0 / 255.0)
    static let organiqPrimary200 = Color(red: 153.0 / 255.0, green: 246.0 / 255.0, blue: 228.0 / 255.0)
    static let organiqSuccess600 = Color(red: 22.0 / 255.0, green: 163.0 / 255.0, blue: 74.0 / 255.0)
}

struct OrganiqWidget_Previews: PreviewProvider {
    static var previews: some View {
        OrganiqWidgetEntryView(
            entry: OrganiqWidgetEntry(
                date: Date(),
                tasks: [
                    OrganiqWidgetTask(id: "1", title: "Tarefa de exemplo", done: false),
                    OrganiqWidgetTask(id: "2", title: "Outra tarefa", done: true),
                ]
            )
        )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
