import WidgetKit
import SwiftUI

@main
struct OrganiqWidgetBundle: WidgetBundle {
  var body: some Widget {
    // P0 — Onda 1
    OrganiqWidget()       // Tasks com checkbox (small, medium, large, lock screen rect)
    DayProgressWidget()   // Anel de progresso (small, lock screen circular)
    NextActionsWidget()   // Timeline do dia (medium, large)
    RemindersWidget()     // Lembretes com countdown (medium, lock screen rect)
    NowPlayingWidget()    // Acontecendo agora (small, medium)
  }
}
