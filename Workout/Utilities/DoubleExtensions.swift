//
//  DoubleExtensions.swift
//  Workout
//
//  Created by Eliott on 2025-04-09.
//

import Foundation

extension Double {
  /// Converts weight between kilograms and pounds based on user preference
  /// - Parameter inLbs: Whether to display the weight in pounds
  /// - Returns: Weight value in the requested unit (kg or lbs)
  func weightValue(inLbs: Bool) -> Double {
    return inLbs ? self * 2.20462 : self
  }

  /// Formats a weight value with unit based on user preference
  /// - Parameter inLbs: Whether to display the weight in pounds
  /// - Returns: Formatted weight string with the appropriate unit
  func formattedWeight(inLbs: Bool) -> String {
    let value = weightValue(inLbs: inLbs)
    let unit = inLbs ? "lbs" : "kg"
    return String(format: "%.1f %@", value, unit)
  }
}
