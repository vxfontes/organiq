import SwiftUI
import WidgetKit

// MARK: - Entry

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
        remindersDone: 2, remindersTotal: 4
      )
    )
  }
}

// MARK: - Provider

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

// MARK: - Views

struct DayProgressWidgetView: View {
  var entry: DayProgressEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *), family == .accessoryCircular {
      accessoryCircularView
        .organiqWidgetBackground(Color.clear)
    } else {
      smallView
        .organiqWidgetBackground(Color.organiqBackground)
    }
  }

  private var percent: Double {
    (entry.progress?.percent ?? 0).clamped(to: 0...1)
  }

  // MARK: systemSmall

  private var smallView: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Organiq")
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.organiqText)

      Spacer()

      // Progress ring
      HStack {
        Spacer()
        ZStack {
          Circle()
            .stroke(Color.organiqBorder, lineWidth: 9)
          Circle()
            .trim(from: 0, to: percent)
            .stroke(ringColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
            .rotationEffect(.degrees(-90))
          VStack(spacing: 1) {
            Text("\(Int(percent * 100))%")
              .font(.system(size: 17, weight: .bold))
              .foregroundColor(.organiqText)
            Text("do dia")
              .font(.system(size: 9, weight: .medium))
              .foregroundColor(.organiqTextMuted)
          }
        }
        .frame(width: 70, height: 70)
        Spacer()
      }

      Spacer()

      // Stat row
      HStack(spacing: 0) {
        statColumn(
          value: "\(entry.progress?.tasksDone ?? 0)/\(entry.progress?.tasksTotal ?? 0)",
          label: "tasks"
        )
        Spacer()
        statColumn(
          value: "\(entry.progress?.routinesDone ?? 0)/\(entry.progress?.routinesTotal ?? 0)",
          label: "rotinas"
        )
      }
    }
    .padding(14)
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.organiqBorder, lineWidth: 1)
    )
  }

  private func statColumn(value: String, label: String) -> some View {
    VStack(spacing: 1) {
      Text(value)
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(.organiqText)
      Text(label)
        .font(.system(size: 9))
        .foregroundColor(.organiqTextMuted)
    }
  }

  // MARK: accessoryCircular (Lock Screen)

  @available(iOSApplicationExtension 16.0, *)
  private var accessoryCircularView: some View {
    ZStack {
      AccessoryWidgetBackground()
      ProgressView(value: percent)
        .progressViewStyle(.circular)
        .tint(.organiqPrimary600)
      Text("\(Int(percent * 100))%")
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.primary)
    }
  }

  // MARK: Helpers

  private var ringColor: Color {
    if percent >= 0.7 { return .organiqSuccess600 }
    if percent >= 0.3 { return .organiqAmber500 }
    return .organiqRed500
  }
}

// MARK: - Widget

struct DayProgressWidget: Widget {
  let kind = "DayProgressWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DayProgressProvider()) { entry in
      DayProgressWidgetView(entry: entry)
    }
    .configurationDisplayName("Progresso do Dia")
    .description("Anel de progresso com tasks, rotinas e lembretes.")
    .supportedFamilies(supportedFamilies)
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .accessoryCircular]
    }
    return [.systemSmall]
  }
}

// MARK: - Clamp helper

private extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    min(max(self, range.lowerBound), range.upperBound)
  }
}

// MARK: - Preview

struct DayProgressWidget_Previews: PreviewProvider {
  static var previews: some View {
    DayProgressWidgetView(entry: .placeholder)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
