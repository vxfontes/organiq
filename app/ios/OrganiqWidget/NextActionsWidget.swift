import SwiftUI
import WidgetKit

// MARK: - Entry

struct NextActionsEntry: TimelineEntry {
  let date: Date
  let items: [NextActionData]

  static var placeholder: NextActionsEntry {
    NextActionsEntry(date: Date(), items: [
      NextActionData(id: "1", title: "Reuniao time", type: "event",
                     scheduledTime: nil, endScheduledTime: nil, isCompleted: false, isOverdue: false),
      NextActionData(id: "2", title: "Pagar aluguel", type: "reminder",
                     scheduledTime: nil, endScheduledTime: nil, isCompleted: false, isOverdue: false),
      NextActionData(id: "3", title: "Exercicio 30min", type: "routine",
                     scheduledTime: nil, endScheduledTime: nil, isCompleted: false, isOverdue: false),
      NextActionData(id: "4", title: "Deploy v0.3", type: "task",
                     scheduledTime: nil, endScheduledTime: nil, isCompleted: false, isOverdue: false),
    ])
  }
}

// MARK: - Provider

struct NextActionsProvider: TimelineProvider {
  func placeholder(in context: Context) -> NextActionsEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (NextActionsEntry) -> Void) {
    completion(NextActionsEntry(date: Date(), items: OrganiqWidgetSharedStore.loadNextActions()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NextActionsEntry>) -> Void) {
    let entry = NextActionsEntry(date: Date(), items: OrganiqWidgetSharedStore.loadNextActions())
    let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }
}

// MARK: - Main View

struct NextActionsWidgetView: View {
  var entry: NextActionsEntry
  @Environment(\.widgetFamily) var family

  private var maxItems: Int { family == .systemLarge ? 7 : 4 }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header
      HStack {
        Text("A seguir")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.organiqText)
        Spacer()
        Text(todayLabel)
          .font(.system(size: 11))
          .foregroundColor(.organiqTextMuted)
      }

      if entry.items.isEmpty {
        Spacer()
        Text("Nenhuma acao proxima")
          .font(.system(size: 12))
          .foregroundColor(.organiqTextMuted)
          .frame(maxWidth: .infinity, alignment: .center)
        Spacer()
      } else {
        ForEach(entry.items.prefix(maxItems)) { item in
          actionRow(item)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(14)
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.organiqBorder, lineWidth: 1)
    )
    .organiqWidgetBackground(Color.organiqBackground)
  }

  // MARK: Row

  private func actionRow(_ item: NextActionData) -> some View {
    HStack(spacing: 8) {
      // Time
      Text(timeLabel(for: item))
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundColor(item.isOverdue ? .organiqRed500 : .organiqTextMuted)
        .frame(width: 36, alignment: .trailing)

      // Color stripe by type
      RoundedRectangle(cornerRadius: 2)
        .fill(typeColor(item.type))
        .frame(width: 3, height: 30)

      // Content
      VStack(alignment: .leading, spacing: 2) {
        Text(item.title)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(item.isCompleted ? .organiqTextMuted : .organiqText)
          .strikethrough(item.isCompleted, color: .organiqTextMuted)
          .lineLimit(1)
        Text(typeName(item.type))
          .font(.system(size: 9))
          .foregroundColor(.organiqTextMuted)
      }

      Spacer(minLength: 0)

      if item.isCompleted {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 12))
          .foregroundColor(.organiqSuccess600)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.organiqSurface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color.organiqBorder, lineWidth: 0.5)
    )
  }

  // MARK: Helpers

  private func timeLabel(for item: NextActionData) -> String {
    guard let iso = item.scheduledTime, let date = isoDate(iso) else { return "--:--" }
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm"
    fmt.timeZone = .current
    return fmt.string(from: date)
  }

  private func typeColor(_ type: String) -> Color {
    switch type {
    case "event":    return .organiqIndigo500
    case "reminder": return .organiqAmber500
    case "routine":  return .organiqPrimary600
    default:         return .organiqTextMuted
    }
  }

  private func typeName(_ type: String) -> String {
    switch type {
    case "event":    return "Evento"
    case "reminder": return "Lembrete"
    case "routine":  return "Rotina"
    case "task":     return "Tarefa"
    default:         return type
    }
  }

  private var todayLabel: String {
    let fmt = DateFormatter()
    fmt.dateFormat = "d MMM"
    fmt.locale = Locale(identifier: "pt_BR")
    return fmt.string(from: entry.date)
  }

  private func isoDate(_ iso: String) -> Date? {
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = fmt.date(from: iso) { return d }
    fmt.formatOptions = [.withInternetDateTime]
    return fmt.date(from: iso)
  }
}

// MARK: - Widget

struct NextActionsWidget: Widget {
  let kind = "NextActionsWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NextActionsProvider()) { entry in
      NextActionsWidgetView(entry: entry)
    }
    .configurationDisplayName("Proximas Acoes")
    .description("Sua timeline de acoes de hoje.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - Preview

struct NextActionsWidget_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NextActionsWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
      NextActionsWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
  }
}
