import SwiftUI
import WidgetKit
import AppIntents

struct OrganiqWidgetEntry: TimelineEntry {
  let date: Date
  let tasks: [OrganiqWidgetTask]
}

struct OrganiqWidgetTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> OrganiqWidgetEntry {
    OrganiqWidgetEntry(date: Date(), tasks: [
      OrganiqWidgetTask(id: "1", title: "Comprar pão",        done: false),
      OrganiqWidgetTask(id: "2", title: "Pagar conta",         done: false),
      OrganiqWidgetTask(id: "3", title: "Ligar para clínica",  done: true),
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

struct OrganiqWidgetEntryView: View {
  var entry: OrganiqWidgetEntry
  @Environment(\.widgetFamily) var family
  @Environment(\.self) private var env

  private var maxTasks: Int {
    switch family {
    case .systemLarge: return 4
    case .systemMedium: return 2
    default: return 2
    }
  }

  private var isSmall: Bool { family == .systemSmall }
  private var rowSpacing: CGFloat { isSmall ? 4 : 5 }
  private var rowVerticalPadding: CGFloat { isSmall ? 6 : 7 }

  private var pendingCount: Int { entry.tasks.filter { !$0.done }.count }
  private var prioritizedTasks: [OrganiqWidgetTask] { sortTasks(entry.tasks.filter { !$0.done }) }
  private var overduePendingCount: Int { prioritizedTasks.filter { urgencyRank(for: $0) == 1 }.count }
  private var todayPendingCount: Int { prioritizedTasks.filter { urgencyRank(for: $0) == 0 }.count }
  private var visibleTasks: ArraySlice<OrganiqWidgetTask> { prioritizedTasks.prefix(maxTasks) }
  private var hiddenCount: Int { max(prioritizedTasks.count - maxTasks, 0) }
  private var widgetBackgroundColor: Color { isAccentedRendering ? .black : .organiqBackground }
  private var cardBackgroundColor: Color { isAccentedRendering ? Color.white.opacity(0.12) : .organiqSurface }
  private var doneCardBackgroundColor: Color { isAccentedRendering ? Color.white.opacity(0.08) : Color.organiqSurface.opacity(0.6) }
  private var cardBorderColor: Color { isAccentedRendering ? Color.white.opacity(0.22) : .organiqBorder }
  private var strokeColor: Color { isAccentedRendering ? Color.white.opacity(0.24) : .organiqBorder }

  private var isAccentedRendering: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return env.widgetRenderingMode == .accented
    }
    return false
  }

  var body: some View {
    switch family {
    case .systemLarge:
      largeView
        .organiqWidgetBackground(widgetBackgroundColor)
    default:
      if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular {
        accessoryRectangularView
          .organiqWidgetBackground(Color.clear)
      } else {
        standardView
          .organiqWidgetBackground(widgetBackgroundColor)
      }
    }
  }

  private var standardView: some View {
    VStack(spacing: 0) {
      headerRow
        .padding(.horizontal, isSmall ? 10 : 14)
        .padding(.top, isSmall ? 10 : 12)
        .padding(.bottom, isSmall ? 6 : 8)

      if entry.tasks.isEmpty {
        emptyState
      } else {
        VStack(spacing: rowSpacing) {
          ForEach(visibleTasks) { task in
            taskRow(task)
          }
          if hiddenCount > 0, !isSmall {
            Text("+\(hiddenCount) tarefas")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(.organiqTextMuted)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 2)
          }
        }
        .padding(.horizontal, isSmall ? 8 : 12)
        .padding(.bottom, isSmall ? 6 : 8)
        if !isSmall {
          Spacer(minLength: 0)
        }
      }
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(strokeColor, lineWidth: 1)
    )
  }

  private var largeView: some View {
    VStack(spacing: 0) {
      headerRow
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)

      if entry.tasks.isEmpty {
        emptyState
      } else {
        VStack(spacing: 6) {
          ForEach(visibleTasks) { task in
            taskRow(task)
          }
          if hiddenCount > 0 {
            Text("+\(hiddenCount) tarefas")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(.organiqTextMuted)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 2)
          }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        Spacer(minLength: 0)
      }
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(strokeColor, lineWidth: 1)
    )
  }

  private var headerRow: some View {
    HStack {
      HStack(spacing: 5) {
        Image(systemName: "checklist")
          .font(.system(size: 10))
          .foregroundColor(.organiqPrimary600)
        Text("Tasks")
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(.organiqText)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }
      Spacer()
      if !entry.tasks.isEmpty {
        if isSmall {
          if pendingCount > 0 {
            Text(smallHeaderBadgeText)
              .font(.system(size: 9, weight: .semibold))
              .foregroundColor(smallHeaderBadgeTextColor)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
              .padding(.horizontal, 7)
              .padding(.vertical, 3)
              .background(
                Capsule()
                  .fill(smallHeaderBadgeBackgroundColor)
              )
          } else {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 12))
              .foregroundColor(.organiqSuccess600)
          }
        } else {
          HStack(spacing: 4) {
            if pendingCount > 0 {
              Text("\(pendingCount)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.organiqPrimary700)
              Text("pendentes")
                .font(.system(size: 11))
                .foregroundColor(.organiqTextMuted)
            } else {
              Text("todas concluídas")
                .font(.system(size: 11))
                .foregroundColor(.organiqSuccess600)
            }
          }
        }
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 6) {
      Spacer()
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: isSmall ? 24 : 28))
        .foregroundColor(.organiqSuccess600.opacity(0.6))
      Text("Sem tarefas pendentes")
        .font(.system(size: isSmall ? 12 : 13, weight: .semibold))
        .foregroundColor(.organiqText)
        .padding(.horizontal, isSmall ? 8 : 10)
        .padding(.vertical, isSmall ? 5 : 6)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.organiqSuccess100)
        )
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func taskRow(_ task: OrganiqWidgetTask) -> some View {
    HStack(spacing: 0) {
      if #available(iOS 17.0, *) {
        Button(intent: CompleteTaskIntent(taskID: task.id)) {
          checkboxView(task)
        }
        .buttonStyle(.plain)
      } else {
        checkboxView(task)
      }
    }
  }

  private func checkboxView(_ task: OrganiqWidgetTask) -> some View {
    VStack(alignment: .leading, spacing: isSmall ? 3 : 4) {
      HStack(spacing: 8) {
        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
          .font(.system(size: isSmall ? 16 : 18, weight: .semibold))
          .foregroundColor(task.done ? .organiqSuccess600 : .organiqPrimary600)

        Text(task.title)
          .font(.system(size: isSmall ? 12 : 13, weight: .medium))
          .foregroundColor(task.done ? .organiqTextMuted : .organiqText)
          .strikethrough(task.done, color: .organiqTextMuted)
          .lineLimit(1)
          .minimumScaleFactor(0.9)

        Spacer(minLength: 0)
      }

      if isSmall {
        HStack(spacing: 6) {
          Text(urgencyShortDetailText(for: task))
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(urgencyBadgeColor(for: task))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Spacer(minLength: 0)
        }
      } else {
        HStack(spacing: 6) {
          if let flagName = task.flagName, !flagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(spacing: 4) {
              Circle()
                .fill(Color.organiqHex(task.flagColor) ?? .organiqPrimary600)
                .frame(width: 6, height: 6)
              Text(flagName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.organiqTextMuted)
                .lineLimit(1)
            }
          }
          Text(urgencyDetailText(for: task))
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(urgencyBadgeColor(for: task))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Spacer(minLength: 0)
        }
      }
    }
    .padding(.horizontal, isSmall ? 8 : 10)
    .padding(.vertical, rowVerticalPadding)
    .background(
      RoundedRectangle(cornerRadius: isSmall ? 8 : 10, style: .continuous)
        .fill(task.done ? doneCardBackgroundColor : cardBackgroundColor)
    )
    .overlay(
      RoundedRectangle(cornerRadius: isSmall ? 8 : 10, style: .continuous)
        .stroke(task.done ? cardBorderColor.opacity(0.8) : cardBorderColor, lineWidth: 1)
    )
  }

  private var smallHeaderBadgeText: String {
    if overduePendingCount > 0 { return "\(overduePendingCount) atras." }
    if todayPendingCount > 0 { return "\(todayPendingCount) hoje" }
    return "\(pendingCount) pend."
  }

  private var smallHeaderBadgeTextColor: Color {
    if overduePendingCount > 0 { return .organiqRed500 }
    if todayPendingCount > 0 { return .organiqAmber500 }
    return .organiqPrimary700
  }

  private var smallHeaderBadgeBackgroundColor: Color {
    if overduePendingCount > 0 { return .organiqRed100 }
    if todayPendingCount > 0 { return .organiqAmber100 }
    return .organiqPrimary100
  }

  private func sortTasks(_ tasks: [OrganiqWidgetTask]) -> [OrganiqWidgetTask] {
    tasks.sorted { a, b in
      let rankA = urgencyRank(for: a)
      let rankB = urgencyRank(for: b)
      if rankA != rankB { return rankA < rankB }

      let dueA = taskDate(a)
      let dueB = taskDate(b)
      switch (dueA, dueB) {
      case let (lhs?, rhs?):
        if lhs != rhs { return lhs < rhs }
      case (_?, nil):
        return true
      case (nil, _?):
        return false
      default:
        break
      }
      return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
    }
  }

  private func urgencyRank(for task: OrganiqWidgetTask) -> Int {
    guard let due = taskDate(task) else { return 2 } // sem data
    let todayStart = Calendar.current.startOfDay(for: Date())
    if Calendar.current.isDate(due, inSameDayAs: todayStart) { return 0 } // hoje
    if due < todayStart { return 1 } // atrasada
    return 3 // futura
  }

  private func urgencyBadgeText(for task: OrganiqWidgetTask) -> String {
    guard let due = taskDate(task) else { return "sem data" }
    let todayStart = Calendar.current.startOfDay(for: Date())
    if Calendar.current.isDate(due, inSameDayAs: todayStart) { return "hoje" }
    if due < todayStart {
      let days = max(todayStart.timeIntervalSince(Calendar.current.startOfDay(for: due)) / 86400, 1)
      return "atras. \(Int(days))d"
    }
    let fmt = DateFormatter()
    fmt.dateFormat = "dd/MM"
    fmt.timeZone = .current
    return fmt.string(from: due)
  }

  private func urgencyDetailText(for task: OrganiqWidgetTask) -> String {
    guard let due = taskDate(task) else { return "Sem data definida" }
    let now = Date()
    let todayStart = Calendar.current.startOfDay(for: now)
    if Calendar.current.isDate(due, inSameDayAs: todayStart) { return "Hoje" }
    if due < todayStart {
      let days = max(todayStart.timeIntervalSince(Calendar.current.startOfDay(for: due)) / 86400, 1)
      if Int(days) <= 1 { return "Venceu há 1 dia" }
      return "Venceu há \(Int(days)) dias"
    }
    let fmt = DateFormatter()
    fmt.dateFormat = "dd/MM"
    fmt.timeZone = .current
    return "Prazo: \(fmt.string(from: due))"
  }

  private func urgencyShortDetailText(for task: OrganiqWidgetTask) -> String {
    guard let due = taskDate(task) else { return "Sem data" }
    let now = Date()
    let todayStart = Calendar.current.startOfDay(for: now)

    if Calendar.current.isDate(due, inSameDayAs: todayStart) {
      return "Hoje"
    }
    if due < todayStart {
      let days = max(todayStart.timeIntervalSince(Calendar.current.startOfDay(for: due)) / 86400, 1)
      return Int(days) <= 1 ? "Atrasada 1d" : "Atrasada \(Int(days))d"
    }
    let fmt = DateFormatter()
    fmt.dateFormat = "dd/MM"
    fmt.timeZone = .current
    return "Prazo \(fmt.string(from: due))"
  }

  private func urgencyBadgeColor(for task: OrganiqWidgetTask) -> Color {
    guard let due = taskDate(task) else { return .organiqTextMuted }
    let todayStart = Calendar.current.startOfDay(for: Date())
    if Calendar.current.isDate(due, inSameDayAs: todayStart) { return .organiqAmber500 }
    if due < todayStart { return .organiqRed500 }
    return .organiqPrimary700
  }

  private func taskDate(_ task: OrganiqWidgetTask) -> Date? {
    guard let iso = task.dueAt else { return nil }
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fmt.date(from: iso) { return date }
    fmt.formatOptions = [.withInternetDateTime]
    return fmt.date(from: iso)
  }

  @ViewBuilder
  private var accessoryRectangularView: some View {
    if #available(iOSApplicationExtension 16.0, *) {
      VStack(alignment: .leading, spacing: 3) {
        if entry.tasks.isEmpty {
          Label("Sem tarefas", systemImage: "checkmark.circle")
            .font(.system(size: 11))
        } else {
          ForEach(entry.tasks.prefix(3)) { task in
            HStack(spacing: 4) {
              Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10))
                .foregroundColor(task.done ? .organiqSuccess600 : .organiqPrimary700)
              Text(task.title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
            }
          }
          if entry.tasks.count > 3 {
            Text("+ \(entry.tasks.count - 3) tarefas")
              .font(.system(size: 9))
              .foregroundColor(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct OrganiqWidget: Widget {
  let kind: String = "OrganiqWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OrganiqWidgetTimelineProvider()) { entry in
      OrganiqWidgetEntryView(entry: entry)
    }
    .containerBackgroundRemovable(false)
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
          OrganiqWidgetTask(id: "3", title: "Enviar relatório",    done: true),
          OrganiqWidgetTask(id: "4", title: "Pagar aluguel",       done: false),
          OrganiqWidgetTask(id: "5", title: "Comprar presente",    done: false),
        ]
      ))
      .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
  }
}
