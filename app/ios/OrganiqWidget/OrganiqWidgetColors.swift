import SwiftUI

extension Color {
  static let organiqBackground = Color(red: 250/255, green: 250/255, blue: 250/255)
  static let organiqSurface    = Color(red: 255/255, green: 255/255, blue: 255/255)
  static let organiqBorder     = Color(red: 229/255, green: 231/255, blue: 235/255)

  static let organiqText       = Color(red: 17/255,  green: 24/255,  blue: 39/255)
  static let organiqTextMuted  = Color(red: 107/255, green: 114/255, blue: 128/255)

  static let organiqPrimary700 = Color(red: 15/255,  green: 118/255, blue: 110/255)
  static let organiqPrimary600 = Color(red: 13/255,  green: 148/255, blue: 136/255)
  static let organiqPrimary200 = Color(red: 153/255, green: 246/255, blue: 228/255)
  static let organiqPrimary100 = Color(red: 204/255, green: 251/255, blue: 241/255)

  static let organiqSuccess600 = Color(red: 22/255,  green: 163/255, blue: 74/255)
  static let organiqSuccess100 = Color(red: 220/255, green: 252/255, blue: 231/255)
  static let organiqAmber500   = Color(red: 245/255, green: 158/255, blue: 11/255)
  static let organiqAmber100   = Color(red: 254/255, green: 243/255, blue: 199/255)
  static let organiqRed500     = Color(red: 239/255, green: 68/255,  blue: 68/255)
  static let organiqRed100     = Color(red: 254/255, green: 226/255, blue: 226/255)
  static let organiqIndigo500  = Color(red: 99/255,  green: 102/255, blue: 241/255)
  static let organiqIndigo100  = Color(red: 238/255, green: 242/255, blue: 255/255)

  static let organiqCardShadow = Color.black.opacity(0.04)

  static func organiqHex(_ value: String?) -> Color? {
    guard var hex = value?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else {
      return nil
    }

    if hex.hasPrefix("#") {
      hex.removeFirst()
    }

    if hex.count == 3 {
      hex = hex.map { "\($0)\($0)" }.joined()
    }

    guard hex.count == 6, let rgb = UInt64(hex, radix: 16) else {
      return nil
    }

    let r = Double((rgb & 0xFF0000) >> 16) / 255
    let g = Double((rgb & 0x00FF00) >> 8) / 255
    let b = Double(rgb & 0x0000FF) / 255
    return Color(red: r, green: g, blue: b)
  }
}

extension View {
  @ViewBuilder
  func organiqWidgetBackground<Background: View>(_ background: Background) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) { background }
    } else {
      self.background(background)
    }
  }
}

extension View {
  func organiqCard() -> some View {
    self
      .background(Color.organiqSurface)
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(Color.organiqBorder, lineWidth: 0.75)
      )
      .shadow(color: .organiqCardShadow, radius: 4, x: 0, y: 2)
  }
}

extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    min(max(self, range.lowerBound), range.upperBound)
  }
}
