import SwiftUI
import WidgetKit

struct DayProgressEntry: TimelineEntry {
  let date: Date
  let progress: DayProgressData?

  static var placeholder: DayProgressEntry {
    DayProgressEntry(
      date: Date(),
      progress: DayProgressData(
        percent: 0.72,
        tasksDone: 5, tasksTotal: 8,
        routinesDone: 3, routinesTotal: 5,
        routinesOverdue: 1,
        remindersDone: 2, remindersTotal: 4,
        eventsDone: 1, eventsTotal: 2
      )
    )
  }
}

struct DayProgressProvider: TimelineProvider {
  func placeholder(in context: Context) -> DayProgressEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (DayProgressEntry) -> Void) {
    completion(DayProgressEntry(date: Date(), progress: OrganiqWidgetSharedStore.loadDayProgress()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DayProgressEntry>) -> Void) {
    let entry = DayProgressEntry(date: Date(), progress: OrganiqWidgetSharedStore.loadDayProgress())
    let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }
}

struct DayProgressWidgetView: View {
  var entry: DayProgressEntry
  @Environment(\.widgetFamily) var family
  @Environment(\.self) private var env

  private var percent: Double { (entry.progress?.percent ?? 0).clamped(to: 0...1) }
  private var ringSize: CGFloat { 74 }
  private var widgetBackgroundColor: Color { isAccentedRendering ? .black : .organiqBackground }
  private var strokeColor: Color { isAccentedRendering ? Color.white.opacity(0.24) : .organiqBorder }
  private var ringTrackColor: Color { isAccentedRendering ? Color.white.opacity(0.2) : .organiqBorder }
  private var chipBackgroundColor: Color { isAccentedRendering ? Color.white.opacity(0.12) : .organiqSurface }
  private var chipBorderColor: Color { isAccentedRendering ? Color.white.opacity(0.2) : .organiqBorder.opacity(0.65) }

  private var isAccentedRendering: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return env.widgetRenderingMode == .accented
    }
    return false
  }

  private var tasksDone: Int { entry.progress?.tasksDone ?? 0 }
  private var tasksTotal: Int { entry.progress?.tasksTotal ?? 0 }
  private var routinesDone: Int { entry.progress?.routinesDone ?? 0 }
  private var routinesTotal: Int { entry.progress?.routinesTotal ?? 0 }
  private var remindersDone: Int { entry.progress?.remindersDone ?? 0 }
  private var remindersTotal: Int { entry.progress?.remindersTotal ?? 0 }
  private var eventsDone: Int { entry.progress?.eventsDone ?? 0 }
  private var eventsTotal: Int { entry.progress?.eventsTotal ?? 0 }
  private var routinesOverdue: Int { entry.progress?.routinesOverdue ?? 0 }

  private var totalDone: Int { tasksDone + routinesDone + remindersDone + eventsDone }
  private var totalItems: Int { tasksTotal + routinesTotal + remindersTotal + eventsTotal }
  private var totalRemaining: Int { max(totalItems - totalDone, 0) }

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *), family == .accessoryCircular {
      accessoryCircularView
        .organiqWidgetBackground(Color.clear)
    } else if family == .systemMedium {
      mediumView
        .organiqWidgetBackground(widgetBackgroundColor)
    } else {
      smallView
        .organiqWidgetBackground(widgetBackgroundColor)
    }
  }

  private var smallView: some View {
    VStack(spacing: 8) {
      headerRow
        .padding(.top, 10)
        .padding(.horizontal, 12)

      progressRingView(size: ringSize, lineWidth: 9, percentFont: 19, captionFont: 9)

      statsGrid
        .padding(.horizontal, 10)
        .padding(.bottom, 10)

      Spacer(minLength: 0)
    }
    .overlay {
      if !isAccentedRendering {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(strokeColor.opacity(0.55), lineWidth: 0.6)
      }
    }
  }

  private var mediumView: some View {
    VStack(spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        HStack(spacing: 6) {
          Image(systemName: "leaf.fill")
            .font(.system(size: 11))
            .foregroundColor(.organiqPrimary600)
          Text("Progresso do dia")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.organiqText)
        }
        Spacer()
        Text(mediumSummary)
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(ringColor)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      .padding(.horizontal, 14)
      .padding(.top, 12)
      .padding(.bottom, 8)

      HStack(spacing: 12) {
        progressRingView(size: 92, lineWidth: 10, percentFont: 24, captionFont: 10)
          .frame(width: 96, height: 96)

        VStack(spacing: 7) {
          mediumBreakdownRow(
            icon: "checkmark.circle.fill",
            title: "Tarefas",
            done: tasksDone,
            total: tasksTotal,
            color: .organiqSuccess600,
            bg: .organiqSuccess100
          )
          mediumBreakdownRow(
            icon: "figure.run",
            title: "Rotinas",
            done: routinesDone,
            total: routinesTotal,
            overdue: routinesOverdue,
            color: .organiqIndigo500,
            bg: .organiqIndigo100
          )
          mediumBreakdownRow(
            icon: "bell.fill",
            title: "Lembretes",
            done: remindersDone,
            total: remindersTotal,
            color: .organiqAmber500,
            bg: .organiqAmber100
          )
        }
      }
      .padding(.horizontal, 14)
      .padding(.bottom, 12)
      Spacer(minLength: 0)
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(strokeColor.opacity(0.75), lineWidth: 0.8)
    )
  }

  private var headerRow: some View {
    HStack {
      Image(systemName: "leaf.fill")
        .font(.system(size: 10))
        .foregroundColor(.organiqPrimary600)
      Text("OrganiQ")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.organiqTextMuted)
      Spacer()
      Text(progressSummaryCompact)
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(ringColor)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
  }

  private func progressRingView(size: CGFloat, lineWidth: CGFloat, percentFont: CGFloat, captionFont: CGFloat) -> some View {
    ZStack {
      Circle()
        .stroke(ringTrackColor, lineWidth: lineWidth)

      Circle()
        .trim(from: 0, to: percent)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [ringColor.opacity(0.5), ringColor]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
          ),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))

      VStack(spacing: 2) {
        Text("\(Int(percent * 100))%")
          .font(.system(size: percentFont, weight: .bold, design: .rounded))
          .foregroundColor(.organiqText)
        Text("do dia")
          .font(.system(size: captionFont, weight: .medium))
          .foregroundColor(.organiqTextMuted)
      }
    }
    .frame(width: size, height: size)
  }

  private var statsGrid: some View {
    HStack(spacing: 6) {
      statChip(
        icon: "checkmark.circle.fill",
        label: "Tarefas",
        progress: "\(entry.progress?.tasksDone ?? 0)/\(entry.progress?.tasksTotal ?? 0)",
        color: .organiqSuccess600,
        bg: .organiqSuccess100
      )
      statChip(
        icon: "figure.run",
        label: "Rotinas",
        progress: routinesOverdue > 0
            ? "\(entry.progress?.routinesDone ?? 0)/\(entry.progress?.routinesTotal ?? 0) · \(routinesOverdue) atras."
            : "\(entry.progress?.routinesDone ?? 0)/\(entry.progress?.routinesTotal ?? 0)",
        color: .organiqIndigo500,
        bg: .organiqIndigo100
      )
      statChip(
        icon: "bell.fill",
        label: "Lembretes",
        progress: "\(entry.progress?.remindersDone ?? 0)/\(entry.progress?.remindersTotal ?? 0)",
        color: .organiqAmber500,
        bg: .organiqAmber100
      )
    }
  }

  private func statChip(icon: String, label: String, progress: String, color: Color, bg: Color) -> some View {
    VStack(spacing: 1) {
      HStack(spacing: 4) {
        ZStack {
          Circle().fill(bg).frame(width: 18, height: 18)
          Image(systemName: icon)
            .font(.system(size: 8))
            .foregroundColor(color)
        }
        Text(label)
          .font(.system(size: 7, weight: .medium))
          .foregroundColor(.organiqTextMuted)
          .lineLimit(1)
      }
      Text(progress)
        .font(.system(size: 9, weight: .semibold, design: .rounded))
        .foregroundColor(.organiqText)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
    .frame(maxWidth: .infinity, alignment: .center)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(chipBackgroundColor)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(chipBorderColor, lineWidth: 0.6)
    )
  }

  private func mediumBreakdownRow(
    icon: String,
    title: String,
    done: Int,
    total: Int,
    overdue: Int = 0,
    color: Color,
    bg: Color
  ) -> some View {
    let remaining = max(total - done, 0)
    let hasOverdue = overdue > 0 && remaining > 0
    return HStack(spacing: 6) {
      ZStack {
        Circle().fill(bg).frame(width: 20, height: 20)
        Image(systemName: icon)
          .font(.system(size: 9))
          .foregroundColor(color)
      }

      VStack(alignment: .leading, spacing: 0) {
        Text(title)
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(.organiqText)
        Text(
          hasOverdue
              ? "\(overdue) atrasadas"
              : (remaining == 0 ? "concluído" : "faltam \(remaining)")
        )
          .font(.system(size: 9))
          .foregroundColor(hasOverdue ? .organiqRed500 : .organiqTextMuted)
      }

      Spacer()

      Text("\(done)/\(total)")
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .foregroundColor(.organiqText)
        .lineLimit(1)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(chipBackgroundColor)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(chipBorderColor, lineWidth: 0.6)
    )
  }

  @available(iOSApplicationExtension 16.0, *)
  private var accessoryCircularView: some View {
    ZStack {
      AccessoryWidgetBackground()
      ProgressView(value: percent)
        .progressViewStyle(.circular)
        .tint(.organiqPrimary600)
      VStack(spacing: 0) {
        Text("\(Int(percent * 100))%")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(.primary)
      }
    }
  }

  private var ringColor: Color {
    if percent >= 0.7 { return .organiqSuccess600 }
    if percent >= 0.3 { return .organiqAmber500 }
    return .organiqRed500
  }

  private var progressSummary: String {
    let remaining = totalRemaining
    if remaining <= 0 { return "completo!" }
    return "\(remaining) restantes"
  }

  private var progressSummaryCompact: String {
    let remaining = totalRemaining
    if remaining <= 0 { return "feito" }
    return "\(remaining) faltam"
  }

  private var mediumSummary: String {
    if totalRemaining == 0 { return "completo" }
    return "\(totalDone) feitos • \(totalRemaining) faltam"
  }
}

struct DayProgressWidget: Widget {
  let kind = "DayProgressWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DayProgressProvider()) { entry in
      DayProgressWidgetView(entry: entry)
    }
    .containerBackgroundRemovable(false)
    .configurationDisplayName("Progresso do Dia")
    .description("Anel de progresso com tarefas, rotinas, lembretes e eventos.")
    .supportedFamilies(supportedFamilies)
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .systemMedium, .accessoryCircular]
    }
    return [.systemSmall, .systemMedium]
  }
}

struct DayProgressWidget_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      DayProgressWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
      DayProgressWidgetView(entry: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
  }
}
