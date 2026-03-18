import SwiftUI

// MARK: - Shared Color Palette
// All widgets in the extension use these colors so the palette stays consistent.

extension Color {
  // Background & Surface
  static let organiqBackground = Color(red: 250/255, green: 250/255, blue: 250/255)
  static let organiqSurface    = Color(red: 255/255, green: 255/255, blue: 255/255)
  static let organiqBorder     = Color(red: 229/255, green: 231/255, blue: 235/255)

  // Text
  static let organiqText       = Color(red: 17/255,  green: 24/255,  blue: 39/255)
  static let organiqTextMuted  = Color(red: 107/255, green: 114/255, blue: 128/255)

  // Primary – Teal
  static let organiqPrimary700 = Color(red: 15/255,  green: 118/255, blue: 110/255)
  static let organiqPrimary600 = Color(red: 13/255,  green: 148/255, blue: 136/255)
  static let organiqPrimary200 = Color(red: 153/255, green: 246/255, blue: 228/255)

  // Semantic
  static let organiqSuccess600 = Color(red: 22/255,  green: 163/255, blue: 74/255)
  static let organiqAmber500   = Color(red: 245/255, green: 158/255, blue: 11/255)
  static let organiqRed500     = Color(red: 239/255, green: 68/255,  blue: 68/255)
  static let organiqIndigo500  = Color(red: 99/255,  green: 102/255, blue: 241/255)
}

// MARK: - Widget Background Helper

extension View {
  /// Applies the correct widget background depending on iOS version.
  @ViewBuilder
  func organiqWidgetBackground<Background: View>(_ background: Background) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      self.background(background)
    }
  }
}
