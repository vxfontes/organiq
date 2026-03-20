import SwiftUI
import WidgetKit

struct RemindersEntry: TimelineEntry {
  let date: Date
  let reminders: [ReminderWidgetData]

  static var placeholder: RemindersEntry {
    let now = Date()
    let cal = Calendar.current
    return RemindersEntry(date: now, reminders: [
      ReminderWidgetData(id: "1", title: "Pagar aluguel",       remindAt: ISO8601DateFormatter().string(from: cal.date(byAdding: .hour, value: 1,  to: now)!)),
      ReminderWidgetData(id: "2", title: "Ligar para dentista", remindAt: ISO8601DateFormatter().string(from: cal.date(byAdding: .hour, value: 5,  to: now)!)),
      ReminderWidgetData(id: "3", title: "Renovar seguro",      remindAt: ISO8601DateFormatter().string(from: cal.date(byAdding: .day,  value: 1,  to: now)!)),
    ])
  }
}

struct RemindersProvider: TimelineProvider {
  func placeholder(in context: Context) -> RemindersEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (RemindersEntry) -> Void) {
    completion(RemindersEntry(date: Date(), reminders: OrganiqWidgetSharedStore.loadReminders()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RemindersEntry>) -> Void) {
    let reminders = OrganiqWidgetSharedStore.loadReminders()
    let now = Date()

    var entries: [RemindersEntry] = [RemindersEntry(date: now, reminders: reminders)]
    if let in5 = Calendar.current.date(byAdding: .minute, value: 5, to: now) {
      entries.append(RemindersEntry(date: in5, reminders: reminders))
    }

    let refresh = Calendar.current.date(byAdding: .minute, value: 10, to: now) ?? now
    completion(Timeline(entries: entries, policy: .after(refresh)))
  }
}

struct RemindersWidgetView: View {
  var entry: RemindersEntry
  @Environment(\.widgetFamily) var family
  @Environment(\.self) private var env

  private let maxItems: Int = 3
  private let rowSpacing: CGFloat = 5
  private var widgetBackgroundColor: Color { isAccentedRendering ? .black : .organiqBackground }
  private var cardBackgroundColor: Color { isAccentedRendering ? Color.white.opacity(0.12) : .organiqSurface }
  private var cardBorderColor: Color { isAccentedRendering ? Color.white.opacity(0.22) : .organiqBorder }
  private var strokeColor: Color { isAccentedRendering ? Color.white.opacity(0.24) : .organiqBorder }

  private var isAccentedRendering: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return env.widgetRenderingMode == .accented
    }
    return false
  }

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular {
      accessoryView
        .organiqWidgetBackground(Color.clear)
    } else {
      mainView
        .organiqWidgetBackground(widgetBackgroundColor)
    }
  }

  private var mainView: some View {
    VStack(spacing: 0) {
      headerRow
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)

      if entry.reminders.isEmpty {
        emptyState
      } else {
        VStack(spacing: rowSpacing) {
          ForEach(entry.reminders.prefix(maxItems)) { reminder in
            reminderRow(reminder)
          }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
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
        Image(systemName: "bell.fill")
          .font(.system(size: 10))
          .foregroundColor(.organiqAmber500)
        Text("Lembretes")
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(.organiqText)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }
      Spacer()
      if let next = entry.reminders.first, let cd = countdownText(for: next) {
        HStack(spacing: 3) {
          Text("próximo")
            .font(.system(size: 10))
            .foregroundColor(.organiqTextMuted)
          Text(cd)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(urgencyColor(for: next))
        }
      }
    }
  }

  private func reminderRow(_ reminder: ReminderWidgetData) -> some View {
    let accent = urgencyColor(for: reminder)
    return HStack(spacing: 8) {
      ZStack {
        Circle().fill(accent.opacity(0.12)).frame(width: 28, height: 28)
        Image(systemName: "bell.fill")
          .font(.system(size: 11))
          .foregroundColor(accent)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(reminder.title)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.organiqText)
          .lineLimit(1)
          .minimumScaleFactor(0.9)
        if let cd = countdownText(for: reminder) {
          Text(cd)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
      }

      Spacer()

      if let diff = reminderTimeDiff(for: reminder) {
        urgencyBadge(diff: diff, color: accent)
      }
    }
    .padding(.leading, 10)
    .padding(.trailing, 10)
    .padding(.vertical, 8)
    .background(cardBackgroundColor)
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(cardBorderColor, lineWidth: 0.5)
    )
    .overlay(alignment: .leading) {
      RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(accent)
        .frame(width: 3)
        .padding(.leading, 1)
        .padding(.vertical, 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }

  private var emptyState: some View {
    VStack(spacing: 6) {
      Spacer()
      Image(systemName: "bell.slash.fill")
        .font(.system(size: 28))
        .foregroundColor(.organiqTextMuted.opacity(0.5))
      Text("Sem lembretes")
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.organiqText)
      Text("Aproveite seu dia!")
        .font(.system(size: 11))
        .foregroundColor(.organiqTextMuted)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  private func urgencyBadge(diff: TimeInterval, color: Color) -> some View {
    Group {
      if diff < 0 {
        label("atrasado", color: .organiqRed500, textColor: .white)
      } else if diff < 3600 {
        label("em breve", color: .organiqRed100, textColor: .organiqRed500)
      } else if diff < 86400 {
        let hours = Int(ceil(diff / 3600))
        label("+\(hours)h", color: color.opacity(0.12), textColor: color)
      } else {
        let days = Int(ceil(diff / 86400))
        label("+\(days)d", color: color.opacity(0.12), textColor: color)
      }
    }
  }

  private func label(_ text: String, color: Color, textColor: Color) -> some View {
    Text(text)
      .font(.system(size: 8, weight: .semibold))
      .foregroundColor(textColor)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(Capsule().fill(color))
  }

  @available(iOSApplicationExtension 16.0, *)
  @ViewBuilder
  private var accessoryView: some View {
    VStack(alignment: .leading, spacing: 2) {
      if let first = entry.reminders.first {
        Label(first.title, systemImage: "bell.fill")
          .font(.system(size: 11, weight: .medium))
          .lineLimit(1)
        if let countdown = countdownText(for: first) {
          Text(countdown)
            .font(.system(size: 9))
            .foregroundColor(.secondary)
        }
      } else {
        Label("Sem lembretes", systemImage: "bell")
          .font(.system(size: 11))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func countdownText(for reminder: ReminderWidgetData) -> String? {
    guard let iso = reminder.remindAt, let target = isoDate(iso) else { return nil }
    let diff = target.timeIntervalSince(entry.date)

    if diff < 0       { return "atrasado" }
    if diff < 60      { return "agora" }
    if diff < 3600 {
      return "em \(Int(diff / 60))min"
    }
    if diff < 86400 {
      let h = Int(diff / 3600)
      let m = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
      return m > 0 ? "em \(h)h \(m)min" : "em \(h)h"
    }
    let days = Int(diff / 86400)
    if days == 1 {
      let fmt = DateFormatter()
      fmt.dateFormat = "HH:mm"
      fmt.timeZone = .current
      return "amanhã às \(fmt.string(from: target))"
    }
    return "em \(days) dias"
  }

  private func reminderTimeDiff(for reminder: ReminderWidgetData) -> TimeInterval? {
    guard let iso = reminder.remindAt, let target = isoDate(iso) else { return nil }
    return target.timeIntervalSince(entry.date)
  }

  private func urgencyColor(for reminder: ReminderWidgetData) -> Color {
    guard let iso = reminder.remindAt, let target = isoDate(iso) else { return .organiqPrimary700 }
    let diff = target.timeIntervalSince(entry.date)
    if diff < 0      { return .organiqRed500 }
    if diff < 3600   { return .organiqRed500 }
    if diff < 86400  { return .organiqAmber500 }
    return .organiqPrimary700
  }

  private func isoDate(_ iso: String) -> Date? {
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = fmt.date(from: iso) { return d }
    fmt.formatOptions = [.withInternetDateTime]
    return fmt.date(from: iso)
  }
}

struct RemindersWidget: Widget {
  let kind = "RemindersWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RemindersProvider()) { entry in
      RemindersWidgetView(entry: entry)
    }
    .containerBackgroundRemovable(false)
    .configurationDisplayName("Lembretes")
    .description("Seus próximos lembretes com countdown.")
    .supportedFamilies(supportedFamilies)
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemMedium, .accessoryRectangular]
    }
    return [.systemMedium]
  }
}

struct RemindersWidget_Previews: PreviewProvider {
  static var previews: some View {
    RemindersWidgetView(entry: .placeholder)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
