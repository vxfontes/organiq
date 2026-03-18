import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Models

struct OrganiqWidgetEntry: TimelineEntry {
  let date: Date
  let tasks: [OrganiqWidgetTask]
}

struct OrganiqWidgetTask: Codable, Identifiable {
  let id: String
  let title: String
  var done: Bool
}

// MARK: - Provider

struct OrganiqWidgetTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> OrganiqWidgetEntry {
    OrganiqWidgetEntry(date: Date(), tasks: [
      OrganiqWidgetTask(id: "1", title: "Comprar pao",        done: false),
      OrganiqWidgetTask(id: "2", title: "Pagar conta",         done: false),
      OrganiqWidgetTask(id: "3", title: "Ligar para clinica",  done: true),
    ])
  }

  func getSnapshot(in context: Context, completion: @escaping (OrganiqWidgetEntry) -> Void) {
    completion(OrganiqWidgetEntry(date: Date(), tasks: OrganiqWidgetSharedStore.loadTasks()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<OrganiqWidgetEntry>) -> Void) {
    let entry = OrganiqWidgetEntry(date: Date(), tasks: OrganiqWidgetSharedStore.loadTasks())
    let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }
}

// MARK: - Views

struct OrganiqWidgetEntryView: View {
  var entry: OrganiqWidgetEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .systemLarge:
      tasksView(maxTasks: 8)
        .organiqWidgetBackground(Color.organiqBackground)

    default:
      if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular {
        accessoryRectangularView
          .organiqWidgetBackground(Color.clear)
      } else {
        // systemSmall + systemMedium
        tasksView(maxTasks: family == .systemMedium ? 6 : 4)
          .organiqWidgetBackground(Color.organiqBackground)
      }
    }
  }

  // MARK: Standard list (small / medium / large)

  private func tasksView(maxTasks: Int) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Organiq")
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(.organiqText)
        Spacer()
        Text("tasks")
          .font(.system(size: 10))
          .foregroundColor(.organiqTextMuted)
      }

      if entry.tasks.isEmpty {
        Spacer()
        Text("Sem tarefas pendentes")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.organiqPrimary700)
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color.organiqPrimary200)
          )
        Spacer()
      } else {
        ForEach(entry.tasks.prefix(maxTasks)) { task in
          taskRow(task)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(14)
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.organiqBorder, lineWidth: 1)
    )
  }

  // MARK: accessoryRectangular (Lock Screen)

  @ViewBuilder
  private var accessoryRectangularView: some View {
    if #available(iOSApplicationExtension 16.0, *) {
      VStack(alignment: .leading, spacing: 3) {
        if entry.tasks.isEmpty {
          Label("Sem tarefas", systemImage: "checkmark.circle")
            .font(.system(size: 11))
        } else {
          ForEach(entry.tasks.prefix(2)) { task in
            HStack(spacing: 4) {
              Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10))
                .foregroundColor(task.done ? .organiqSuccess600 : .organiqPrimary700)
              Text(task.title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
            }
          }
          if entry.tasks.count > 2 {
            Text("+ \(entry.tasks.count - 2) tarefas")
              .font(.system(size: 9))
              .foregroundColor(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: Task row (interactive on iOS 17+)

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
    .padding(.vertical, 7)
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

// MARK: - Widget

struct OrganiqWidget: Widget {
  let kind: String = "OrganiqWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OrganiqWidgetTimelineProvider()) { entry in
      OrganiqWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Tasks")
    .description("Suas tarefas pendentes com checkbox interativo.")
    .supportedFamilies(supportedFamilies)
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular]
    }
    return [.systemSmall, .systemMedium, .systemLarge]
  }
}

// MARK: - Intent (iOS 17+)

@available(iOS 17.0, *)
struct CompleteTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Concluir tarefa"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Task ID")
  var taskID: String

  init() {}
  init(taskID: String) { self.taskID = taskID }

  func perform() async throws -> some IntentResult {
    OrganiqWidgetSharedStore.markTaskAsDone(taskID: taskID)
    WidgetCenter.shared.reloadTimelines(ofKind: "OrganiqWidget")
    return .result()
  }
}

// MARK: - Preview

struct OrganiqWidget_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      OrganiqWidgetEntryView(entry: OrganiqWidgetEntry(
        date: Date(),
        tasks: [
          OrganiqWidgetTask(id: "1", title: "Tarefa de exemplo", done: false),
          OrganiqWidgetTask(id: "2", title: "Outra tarefa",       done: true),
        ]
      ))
      .previewContext(WidgetPreviewContext(family: .systemSmall))

      OrganiqWidgetEntryView(entry: OrganiqWidgetEntry(
        date: Date(),
        tasks: [
          OrganiqWidgetTask(id: "1", title: "Deploy v0.3",         done: false),
          OrganiqWidgetTask(id: "2", title: "Revisar PR #42",      done: false),
          OrganiqWidgetTask(id: "3", title: "Enviar relatorio",    done: true),
          OrganiqWidgetTask(id: "4", title: "Pagar aluguel",       done: false),
          OrganiqWidgetTask(id: "5", title: "Comprar presente",    done: false),
        ]
      ))
      .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
  }
}
