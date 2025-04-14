//
//  StringExtensions.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import Foundation

extension String {
  /// Capitalizes the first letter of each word in a string
  /// Example: "incline bench press" -> "Incline Bench Press"
  func capitalizingFirstLetterOfEachWord() -> String {
    guard !self.isEmpty else { return self }

    let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.split(separator: " ")
      .map { $0.prefix(1).uppercased() + $0.dropFirst() }
      .joined(separator: " ")
  }
}
