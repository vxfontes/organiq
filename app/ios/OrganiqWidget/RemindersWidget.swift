import SwiftUI
import WidgetKit

// MARK: - Entry

struct RemindersEntry: TimelineEntry {
  let date: Date
  let reminders: [ReminderWidgetData]

  static var placeholder: RemindersEntry {
    RemindersEntry(date: Date(), reminders: [
      ReminderWidgetData(id: "1", title: "Pagar aluguel",       remindAt: nil),
      ReminderWidgetData(id: "2", title: "Ligar para dentista", remindAt: nil),
      ReminderWidgetData(id: "3", title: "Renovar seguro",      remindAt: nil),
    ])
  }
}

// MARK: - Provider

struct RemindersProvider: TimelineProvider {
  func placeholder(in context: Context) -> RemindersEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (RemindersEntry) -> Void) {
    completion(RemindersEntry(date: Date(), reminders: OrganiqWidgetSharedStore.loadReminders()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RemindersEntry>) -> Void) {
    let reminders = OrganiqWidgetSharedStore.loadReminders()
    let now = Date()

    // Two entries — one now, one in 5 min — so the countdown refreshes more frequently.
    var entries: [RemindersEntry] = [RemindersEntry(date: now, reminders: reminders)]
    if let in5 = Calendar.current.date(byAdding: .minute, value: 5, to: now) {
      entries.append(RemindersEntry(date: in5, reminders: reminders))
    }

    let refresh = Calendar.current.date(byAdding: .minute, value: 10, to: now) ?? now
    completion(Timeline(entries: entries, policy: .after(refresh)))
  }
}

// MARK: - Views

struct RemindersWidgetView: View {
  var entry: RemindersEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular {
      accessoryView
        .organiqWidgetBackground(Color.clear)
    } else {
      mainView
        .organiqWidgetBackground(Color.organiqBackground)
    }
  }

  // MARK: systemSmall / systemMedium

  private var maxItems: Int { family == .systemMedium ? 4 : 3 }

  private var mainView: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header
      HStack(spacing: 5) {
        Image(systemName: "bell.fill")
          .font(.system(size: 11))
          .foregroundColor(.organiqPrimary700)
        Text("Lembretes")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.organiqText)
      }

      if entry.reminders.isEmpty {
        Spacer()
        Text("Sem lembretes proximos")
          .font(.system(size: 12))
          .foregroundColor(.organiqTextMuted)
          .frame(maxWidth: .infinity, alignment: .center)
        Spacer()
      } else {
        ForEach(entry.reminders.prefix(maxItems)) { reminder in
          reminderRow(reminder)
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

  private func reminderRow(_ reminder: ReminderWidgetData) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "bell.fill")
        .font(.system(size: 12))
        .foregroundColor(urgencyColor(for: reminder))

      VStack(alignment: .leading, spacing: 2) {
        Text(reminder.title)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.organiqText)
          .lineLimit(1)
        if let countdown = countdownText(for: reminder) {
          Text(countdown)
            .font(.system(size: 10))
            .foregroundColor(urgencyColor(for: reminder))
        }
      }
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
        .stroke(Color.organiqBorder, lineWidth: 0.5)
    )
  }

  // MARK: accessoryRectangular (Lock Screen)

  @ViewBuilder
  private var accessoryView: some View {
    if #available(iOSApplicationExtension 16.0, *) {
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
  }

  // MARK: Helpers

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
      return "amanha as \(fmt.string(from: target))"
    }
    return "em \(days) dias"
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

// MARK: - Widget

struct RemindersWidget: Widget {
  let kind = "RemindersWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RemindersProvider()) { entry in
      RemindersWidgetView(entry: entry)
    }
    .configurationDisplayName("Lembretes")
    .description("Seus proximos lembretes com countdown.")
    .supportedFamilies(supportedFamilies)
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .systemMedium, .accessoryRectangular]
    }
    return [.systemSmall, .systemMedium]
  }
}

// MARK: - Preview

struct RemindersWidget_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      RemindersWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
      RemindersWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
  }
}
