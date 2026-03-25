import SwiftUI
import WidgetKit

struct NowPlayingEntry: TimelineEntry {
  let date: Date
  let payload: NowPlayingData?

  static var placeholder: NowPlayingEntry {
    let now = Date()
    let iso = ISO8601DateFormatter().string(from: now)
    return NowPlayingEntry(
      date: now,
      payload: NowPlayingData(
        current: NowPlayingItemData(
          id: "now-1",
          title: "Reunião de alinhamento",
          type: "event",
          scheduledTime: iso,
          endScheduledTime: ISO8601DateFormatter().string(from: now.addingTimeInterval(1800)),
          subtitle: "Time de produto",
          accentColor: "#2563EB",
          isCompleted: false,
          isOverdue: false
        ),
        next: NowPlayingItemData(
          id: "next-1",
          title: "Pagar aluguel",
          type: "task",
          scheduledTime: ISO8601DateFormatter().string(from: now.addingTimeInterval(3600)),
          endScheduledTime: nil,
          subtitle: nil,
          accentColor: "#16A34A",
          isCompleted: false,
          isOverdue: false
        ),
        upcoming: [
          NowPlayingItemData(
            id: "next-1",
            title: "Pagar aluguel",
            type: "task",
            scheduledTime: ISO8601DateFormatter().string(from: now.addingTimeInterval(3600)),
            endScheduledTime: nil,
            subtitle: nil,
            accentColor: "#16A34A",
            isCompleted: false,
            isOverdue: false
          ),
          NowPlayingItemData(
            id: "next-2",
            title: "Treino funcional",
            type: "routine",
            scheduledTime: ISO8601DateFormatter().string(from: now.addingTimeInterval(7200)),
            endScheduledTime: nil,
            subtitle: nil,
            accentColor: "#0D9488",
            isCompleted: false,
            isOverdue: false
          ),
        ]
      )
    )
  }
}

struct NowPlayingProvider: TimelineProvider {
  func placeholder(in context: Context) -> NowPlayingEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
    completion(NowPlayingEntry(date: Date(), payload: OrganiqWidgetSharedStore.loadNowPlaying()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
    let entry = NowPlayingEntry(date: Date(), payload: OrganiqWidgetSharedStore.loadNowPlaying())
    let refresh = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }
}

struct NowPlayingWidgetView: View {
  var entry: NowPlayingEntry
  @Environment(\.widgetFamily) var family
  @Environment(\.self) private var env

  private var isMedium: Bool { family == .systemMedium }
  private var current: NowPlayingItemData? { resolvedCurrent }
  private var next: NowPlayingItemData? { resolvedUpcoming.first }
  private var upcomingMediumSlots: [NowPlayingItemData?] {
    let upcoming = resolvedUpcoming
    let firstTwo = Array(upcoming.prefix(2)).map { Optional($0) }
    if firstTwo.count == 2 { return firstTwo }
    if firstTwo.count == 1 { return [firstTwo[0], nil] }
    return [nil, nil]
  }

  private var resolvedCurrent: NowPlayingItemData? {
    let now = entry.date
    let activeItems = orderedTimelineItems.compactMap { item -> (item: NowPlayingItemData, start: Date, end: Date)? in
      guard let start = isoDate(item.scheduledTime) else { return nil }
      let end = isoDate(item.endScheduledTime) ?? start.addingTimeInterval(45 * 60)
      guard now >= start && now < end else { return nil }
      return (item: item, start: start, end: end)
    }

    let sorted = activeItems.sorted { lhs, rhs in
      if lhs.start != rhs.start { return lhs.start > rhs.start }
      if lhs.end != rhs.end { return lhs.end < rhs.end }
      return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
    }

    return sorted.first?.item ?? entry.payload?.current
  }

  private var resolvedUpcoming: [NowPlayingItemData] {
    let now = entry.date
    let currentKey = resolvedCurrent.map(stableKey)
    let futureItems = orderedTimelineItems.compactMap { item -> (item: NowPlayingItemData, start: Date)? in
      guard let start = isoDate(item.scheduledTime), start > now else { return nil }
      if let currentKey, stableKey(item) == currentKey { return nil }
      return (item: item, start: start)
    }

    if !futureItems.isEmpty {
      return futureItems
        .sorted { lhs, rhs in
          if lhs.start != rhs.start { return lhs.start < rhs.start }
          return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
        }
        .map { $0.item }
    }

    var fallback: [NowPlayingItemData] = []
    if let next = entry.payload?.next {
      fallback.append(next)
    }
    fallback.append(contentsOf: entry.payload?.upcoming ?? [])
    let dedupedFallback = dedupe(items: fallback)

    if let currentKey {
      return dedupedFallback.filter { stableKey($0) != currentKey }
    }
    return dedupedFallback
  }

  private var orderedTimelineItems: [NowPlayingItemData] {
    guard let payload = entry.payload else { return [] }
    let deduped = dedupe(items: [payload.current, payload.next].compactMap { $0 } + payload.upcoming)
    return deduped.sorted { lhs, rhs in
      let lhsDate = isoDate(lhs.scheduledTime)
      let rhsDate = isoDate(rhs.scheduledTime)
      switch (lhsDate, rhsDate) {
      case let (l?, r?):
        if l != r { return l < r }
      case (_?, nil):
        return true
      case (nil, _?):
        return false
      default:
        break
      }
      return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
  }

  private var isAccentedRendering: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return env.widgetRenderingMode == .accented
    }
    return false
  }

  private var widgetBackgroundColor: Color { isAccentedRendering ? .black : .organiqBackground }
  private var cardBackgroundColor: Color { isAccentedRendering ? Color.white.opacity(0.12) : .organiqSurface }
  private var cardBorderColor: Color { isAccentedRendering ? Color.white.opacity(0.22) : .organiqBorder }
  private var strokeColor: Color { isAccentedRendering ? Color.white.opacity(0.24) : .organiqBorder }

  var body: some View {
    Group {
      if isMedium {
        mediumView
      } else {
        smallView
      }
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(strokeColor, lineWidth: 1)
    )
    .organiqWidgetBackground(widgetBackgroundColor)
  }

  private var smallView: some View {
    VStack(spacing: 6) {
      smallHeader
        .padding(.horizontal, 10)
        .padding(.top, 8)

      mainCard(item: current, isCurrent: true, compact: false)
        .padding(.horizontal, 10)

      secondaryCard(item: next, compact: true)
        .padding(.horizontal, 10)
        .padding(.bottom, 9)
    }
  }

  private var mediumView: some View {
    VStack(spacing: 0) {
      header
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)

      HStack(spacing: 10) {
        mainCard(item: current, isCurrent: true, compact: false)

        VStack(spacing: 8) {
          secondaryCard(item: upcomingMediumSlots[0], compact: true)
          secondaryCard(item: upcomingMediumSlots[1], compact: true)
        }
        .frame(width: 126)
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 10)

      Spacer(minLength: 0)
    }
  }

  private var header: some View {
    HStack(spacing: 6) {
      Image(systemName: "dot.radiowaves.left.and.right")
        .font(.system(size: 10))
        .foregroundColor(.organiqPrimary600)
      Text("Acontecendo agora")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.organiqText)
      Spacer()
      Text(nowLabel)
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundColor(.organiqTextMuted)
    }
  }

  private var smallHeader: some View {
    HStack(spacing: 5) {
      Image(systemName: "dot.radiowaves.left.and.right")
        .font(.system(size: 9))
        .foregroundColor(.organiqPrimary600)
      Text("Agora")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.organiqText)
      Spacer()
      Text(nowLabel)
        .font(.system(size: 9, weight: .medium, design: .monospaced))
        .foregroundColor(.organiqTextMuted)
    }
  }

  private func mainCard(item: NowPlayingItemData?, isCurrent: Bool, compact: Bool) -> some View {
    let accent = accentColor(for: item)
    let titleSize: CGFloat = isMedium ? 16 : (compact ? 11.5 : 13.5)
    let labelSize: CGFloat = compact ? 8.5 : 10
    let timeSize: CGFloat = compact ? 7.5 : 9
    let typeSize: CGFloat = compact ? 8.5 : 10
    let cardMinHeight: CGFloat = compact ? (isMedium ? 50 : 42) : (isMedium ? 110 : 62)
    let verticalPadding: CGFloat = compact ? (isMedium ? 6 : 5) : (isMedium ? 8 : 7)

    return VStack(alignment: .leading, spacing: 5) {
      HStack(spacing: 5) {
        Text(isCurrent ? "Agora" : "Próximo")
          .font(.system(size: labelSize, weight: .semibold))
          .foregroundColor(accent)

        if !isMedium, !compact, let item {
          Image(systemName: typeIcon(item.type))
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(accent)
        }

        Spacer(minLength: 0)
        if let item {
          Text(timeLabel(for: item, isCurrent: isCurrent))
            .font(.system(size: timeSize, weight: .medium, design: .monospaced))
            .foregroundColor(.organiqTextMuted)
        }
      }

      if let item {
        Text(item.title)
          .font(.system(size: titleSize, weight: .bold))
          .foregroundColor(.organiqText)
          .lineLimit(compact ? 1 : (isMedium ? 2 : 1))
          .minimumScaleFactor(0.85)

        if !compact {
          HStack(spacing: 5) {
            Image(systemName: typeIcon(item.type))
              .font(.system(size: 9))
            Text(typeName(item.type))
              .font(.system(size: typeSize, weight: .medium))
              .lineLimit(1)
          }
          .foregroundColor(accent)
        }

        if !compact, let subtitle = normalizedSubtitle(item.subtitle) {
          Text(subtitle)
            .font(.system(size: 9))
            .foregroundColor(.organiqTextMuted)
            .lineLimit(1)
        }
      } else {
        Text("Tempo livre")
          .font(.system(size: isMedium ? 16 : 15, weight: .bold))
          .foregroundColor(.organiqPrimary700)
          .lineLimit(1)
        Text("Nada em andamento")
          .font(.system(size: 10))
          .foregroundColor(.organiqTextMuted)
      }

      if !compact {
        Spacer(minLength: 0)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, verticalPadding)
    .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(cardBackgroundColor)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .stroke(cardBorderColor, lineWidth: 0.6)
    )
    .overlay(alignment: .leading) {
      RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(accent)
        .frame(width: 4)
        .padding(.leading, 1)
        .padding(.vertical, 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
  }

  private func secondaryCard(item: NowPlayingItemData?, compact: Bool) -> some View {
    Group {
      if let item {
        mainCard(item: item, isCurrent: false, compact: compact)
      } else {
        emptyUpcomingCard()
      }
    }
    .frame(maxWidth: isMedium ? 124 : .infinity)
  }

  private func emptyUpcomingCard() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("Próximo")
          .font(.system(size: 8.5, weight: .semibold))
          .foregroundColor(.organiqTextMuted)
        Spacer(minLength: 0)
        Text("--:--")
          .font(.system(size: 7.5, weight: .medium, design: .monospaced))
          .foregroundColor(.organiqTextMuted)
      }
      Text("Sem próximo")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.organiqTextMuted)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(cardBackgroundColor)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .stroke(cardBorderColor, lineWidth: 0.6)
    )
  }

  private func accentColor(for item: NowPlayingItemData?) -> Color {
    guard let item else { return .organiqPrimary600 }
    if let byTag = Color.organiqHex(item.accentColor) {
      return byTag
    }
    return typeColor(item.type)
  }

  private func typeColor(_ type: String) -> Color {
    switch type {
    case "event": return .organiqIndigo500
    case "reminder": return .organiqAmber500
    case "routine": return .organiqPrimary600
    case "task": return .organiqSuccess600
    default: return .organiqTextMuted
    }
  }

  private func typeIcon(_ type: String) -> String {
    switch type {
    case "event": return "calendar"
    case "reminder": return "bell"
    case "routine": return "figure.run"
    case "task": return "checklist"
    default: return "circle"
    }
  }

  private func typeName(_ type: String) -> String {
    switch type {
    case "event": return "Evento"
    case "reminder": return "Lembrete"
    case "routine": return "Rotina"
    case "task": return "Tarefa"
    default: return "Item"
    }
  }

  private func timeLabel(for item: NowPlayingItemData, isCurrent: Bool) -> String {
    guard let start = isoDate(item.scheduledTime) else { return "--:--" }
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm"
    fmt.timeZone = .current

    if isCurrent {
      if let end = isoDate(item.endScheduledTime) {
        return "\(fmt.string(from: start))–\(fmt.string(from: end))"
      }
      return "desde \(fmt.string(from: start))"
    }

    return fmt.string(from: start)
  }

  private var nowLabel: String {
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm"
    fmt.timeZone = .current
    return fmt.string(from: entry.date)
  }

  private func normalizedSubtitle(_ subtitle: String?) -> String? {
    guard let subtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines), !subtitle.isEmpty else {
      return nil
    }
    return subtitle
  }

  private func dedupe(items: [NowPlayingItemData]) -> [NowPlayingItemData] {
    var result: [NowPlayingItemData] = []
    var seen = Set<String>()
    for item in items {
      let key = stableKey(item)
      if seen.contains(key) { continue }
      seen.insert(key)
      result.append(item)
    }
    return result
  }

  private func stableKey(_ item: NowPlayingItemData) -> String {
    "\(item.type)|\(item.id)"
  }

  private func isoDate(_ iso: String?) -> Date? {
    guard let iso else { return nil }
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = fmt.date(from: iso) { return d }
    fmt.formatOptions = [.withInternetDateTime]
    return fmt.date(from: iso)
  }
}

struct NowPlayingWidget: Widget {
  let kind = "NowPlayingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NowPlayingProvider()) { entry in
      NowPlayingWidgetView(entry: entry)
    }
    .containerBackgroundRemovable(false)
    .configurationDisplayName("Acontecendo agora")
    .description("Mostra o que está rolando agora e qual é o próximo item.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct NowPlayingWidget_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NowPlayingWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
      NowPlayingWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
  }
}
