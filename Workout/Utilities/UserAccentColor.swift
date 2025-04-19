//
//  UserAccentColorKey.swift
//  Workout
//
//  Created by Eliott on 2025-04-04.
//

import Foundation
import SwiftUI
import UIKit

extension Color: @retroactive RawRepresentable, @retroactive Decodable & Encodable {

  public init?(rawValue: String) {

    guard let data = Data(base64Encoded: rawValue) else {
      self = .black
      return
    }

    do {
      if let color = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: UIColor.self, from: data)
      {
        self = Color(color)
      } else {
        self = .black
      }
    } catch {
      self = .black
    }

  }

  public var rawValue: String {
    do {
      let data =
        try NSKeyedArchiver.archivedData(
          withRootObject: UIColor(self), requiringSecureCoding: false
        ) as Data
      return data.base64EncodedString()
    } catch {
      return ""
    }
  }

  // Check if the color is light or dark using luminance
  var isDark: Bool {
    let uiColor = UIColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    // Calculate luminance
    let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
    return luminance < 0.5
  }

  // Return either black or white for better contrast
  var contrastColor: Color {
    isDark ? .white : .black
  }

  var foregroundColor: Color {
    let uiColor = UIColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    if isDark {
      // Lighten the color by blending with white
      let lighten: CGFloat = 0.5
      return Color(
        red: min(red + (1 - red) * lighten, 1.0),
        green: min(green + (1 - green) * lighten, 1.0),
        blue: min(blue + (1 - blue) * lighten, 1.0),
        opacity: Double(alpha)
      )
    } else {
      // Darken the color by blending with black
      let darken: CGFloat = 0.5
      return Color(
        red: max(red * (1 - darken), 0.0),
        green: max(green * (1 - darken), 0.0),
        blue: max(blue * (1 - darken), 0.0),
        opacity: Double(alpha)
      )
    }
  }
}

// Custom environment key for user accent color
private struct UserAccentColorKey: EnvironmentKey {
  static let defaultValue: Color = .pink
}

// Extend EnvironmentValues to include userColor
extension EnvironmentValues {
  var userAccentColor: Color {
    get { self[UserAccentColorKey.self] }
    set { self[UserAccentColorKey.self] = newValue }
  }
}
