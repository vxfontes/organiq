import SwiftUI
import WidgetKit

struct NextActionsEntry: TimelineEntry {
  let date: Date
  let items: [NextActionData]

  static var placeholder: NextActionsEntry {
    NextActionsEntry(date: Date(), items: [
      NextActionData(id: "1", title: "Reuniao com time", type: "event",
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

struct NextActionsWidgetView: View {
  var entry: NextActionsEntry
  @Environment(\.widgetFamily) var family
  @Environment(\.self) private var env

  private var isLarge: Bool { family == .systemLarge }
  private var maxItems: Int { isLarge ? 6 : 4 }
  private var rowSpacing: CGFloat { isLarge ? 5 : 4 }
  private var displayedItems: ArraySlice<NextActionData> { orderedItems.prefix(maxItems) }
  private var hiddenCount: Int { max(orderedItems.count - maxItems, 0) }
  private var widgetBackgroundColor: Color { isAccentedRendering ? .black : .organiqBackground }
  private var cardBackgroundColor: Color { isAccentedRendering ? Color.white.opacity(0.12) : .organiqSurface }
  private var doneCardBackgroundColor: Color { isAccentedRendering ? Color.white.opacity(0.08) : Color.organiqSurface.opacity(0.6) }
  private var cardBorderColor: Color { isAccentedRendering ? Color.white.opacity(0.22) : .organiqBorder }
  private var strokeColor: Color { isAccentedRendering ? Color.white.opacity(0.24) : .organiqBorder }
  private var orderedItems: [NextActionData] { sortItems(entry.items) }

  private var isAccentedRendering: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return env.widgetRenderingMode == .accented
    }
    return false
  }

  var body: some View {
    VStack(spacing: 0) {
      headerRow
        .padding(.horizontal, isLarge ? 14 : 12)
        .padding(.top, isLarge ? 12 : 10)
        .padding(.bottom, isLarge ? 8 : 6)

      if entry.items.isEmpty {
        emptyState
      } else {
        VStack(spacing: rowSpacing) {
          ForEach(displayedItems) { item in
            actionRow(item)
          }
          footerRow
        }
        .padding(.horizontal, isLarge ? 12 : 10)
        .padding(.bottom, isLarge ? 8 : 6)
      }
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(strokeColor, lineWidth: 1)
    )
    .organiqWidgetBackground(widgetBackgroundColor)
  }

  private var headerRow: some View {
    HStack {
      HStack(spacing: 5) {
        Image(systemName: "clock.fill")
          .font(.system(size: 10))
          .foregroundColor(.organiqPrimary600)
        Text("A seguir")
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(.organiqText)
      }
      Spacer()
      if isLarge {
        HStack(spacing: 4) {
          Text("\(entry.items.count)")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.organiqPrimary700)
          Text("itens")
            .font(.system(size: 11))
            .foregroundColor(.organiqTextMuted)
        }
        Text("·")
          .foregroundColor(.organiqTextMuted)
        Text(todayLabel)
          .font(.system(size: 11))
          .foregroundColor(.organiqTextMuted)
      } else {
        Text("\(entry.items.count)")
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.organiqPrimary700)
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 6) {
      Spacer()
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: isLarge ? 28 : 24))
        .foregroundColor(.organiqSuccess600.opacity(0.6))
      Text("Tudo certo!")
        .font(.system(size: isLarge ? 13 : 12, weight: .semibold))
        .foregroundColor(.organiqText)
      Text("Nenhuma acao pendente")
        .font(.system(size: isLarge ? 11 : 10))
        .foregroundColor(.organiqTextMuted)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  private var footerRow: some View {
    HStack(spacing: 6) {
      if let first = displayedItems.first, let end = timeLabel(for: first.endScheduledTime) {
        Text("termina as \(end)")
          .font(.system(size: 9, weight: .medium))
          .foregroundColor(.organiqTextMuted)
      }
      Spacer()
      if hiddenCount > 0 {
        Text("+\(hiddenCount) depois")
          .font(.system(size: 9, weight: .medium))
          .foregroundColor(.organiqTextMuted)
      }
    }
    .padding(.horizontal, 2)
    .padding(.top, 2)
  }

  private func actionRow(_ item: NextActionData) -> some View {
    let accent = accentColor(for: item)
    return HStack(spacing: 0) {
      if item.isCompleted {
        completedRow(item, accent: accent)
      } else {
        activeRow(item, accent: accent)
      }
    }
  }

  private func activeRow(_ item: NextActionData, accent: Color) -> some View {
    HStack(spacing: 0) {
      RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(accent)
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(timeRangeLabel(for: item))
            .font(.system(size: isLarge ? 10 : 9, weight: .medium, design: .monospaced))
            .foregroundColor(item.isOverdue ? .organiqRed500 : .organiqTextMuted)
          if item.isOverdue {
            Text("atrasado")
              .font(.system(size: 8, weight: .semibold))
              .foregroundColor(.white)
              .padding(.horizontal, 5)
              .padding(.vertical, 2)
              .background(Capsule().fill(Color.organiqRed500))
          }
          Spacer(minLength: 0)
          HStack(spacing: 3) {
            Image(systemName: typeIcon(item.type))
              .font(.system(size: 8))
            Text(typeName(item.type))
              .font(.system(size: 9))
          }
          .foregroundColor(accent)
        }

        HStack(spacing: 0) {
          Text(item.title)
            .font(.system(size: isLarge ? 12 : 11, weight: .medium))
            .foregroundColor(.organiqText)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
          Spacer(minLength: 0)
        }

        if let subtitle = normalizedSubtitle(for: item) {
          Text(subtitle)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.organiqTextMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
      }
      .padding(.leading, 8)
      .padding(.trailing, isLarge ? 10 : 8)
      .padding(.vertical, isLarge ? 7 : 6)
      .background(cardBackgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: isLarge ? 10 : 8, style: .continuous)
          .stroke(cardBorderColor, lineWidth: 0.5)
      )
    }
  }

  private func completedRow(_ item: NextActionData, accent: Color) -> some View {
    HStack(spacing: 0) {
      RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(accent.opacity(0.3))
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(timeRangeLabel(for: item))
            .font(.system(size: isLarge ? 10 : 9, weight: .medium, design: .monospaced))
            .foregroundColor(.organiqTextMuted)
          Spacer(minLength: 0)
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 13))
            .foregroundColor(.organiqSuccess600)
        }

        HStack(spacing: 0) {
          Text(item.title)
            .font(.system(size: isLarge ? 12 : 11, weight: .medium))
            .foregroundColor(.organiqTextMuted)
            .strikethrough(true, color: .organiqTextMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
          Spacer(minLength: 0)
        }

        if let subtitle = normalizedSubtitle(for: item) {
          Text(subtitle)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.organiqTextMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
      }
      .padding(.leading, 8)
      .padding(.trailing, isLarge ? 10 : 8)
      .padding(.vertical, isLarge ? 7 : 6)
      .background(doneCardBackgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: isLarge ? 10 : 8, style: .continuous)
          .stroke(cardBorderColor.opacity(0.8), lineWidth: 0.5)
      )
    }
  }

  private func sortItems(_ items: [NextActionData]) -> [NextActionData] {
    items.sorted { a, b in
      let aDate = a.scheduledTime.flatMap(isoDate)
      let bDate = b.scheduledTime.flatMap(isoDate)
      switch (aDate, bDate) {
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

  private func accentColor(for item: NextActionData) -> Color {
    if let byTag = Color.organiqHex(item.accentColor) {
      return byTag
    }
    return typeColor(item.type)
  }

  private func timeLabel(for isoString: String?) -> String? {
    guard let isoString, let date = isoDate(isoString) else { return nil }
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm"
    fmt.timeZone = .current
    return fmt.string(from: date)
  }

  private func timeRangeLabel(for item: NextActionData) -> String {
    let start = timeLabel(for: item.scheduledTime) ?? "--:--"
    guard let end = timeLabel(for: item.endScheduledTime) else { return start }
    return "\(start) - \(end)"
  }

  private func normalizedSubtitle(for item: NextActionData) -> String? {
    if let subtitle = item.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines), !subtitle.isEmpty {
      return subtitle
    }
    if let end = timeLabel(for: item.endScheduledTime) {
      return "Termino: \(end)"
    }
    return nil
  }

  private func typeColor(_ type: String) -> Color {
    switch type {
    case "event":    return .organiqIndigo500
    case "reminder": return .organiqAmber500
    case "routine":  return .organiqPrimary600
    case "task":     return .organiqSuccess600
    default:         return .organiqTextMuted
    }
  }

  private func typeIcon(_ type: String) -> String {
    switch type {
    case "event":    return "calendar"
    case "reminder": return "bell"
    case "routine":  return "figure.run"
    case "task":     return "checklist"
    default:         return "circle"
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

struct NextActionsWidget: Widget {
  let kind = "NextActionsWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NextActionsProvider()) { entry in
      NextActionsWidgetView(entry: entry)
    }
    .containerBackgroundRemovable(false)
    .configurationDisplayName("Proximas Acoes")
    .description("Sua timeline de acoes de hoje.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

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
