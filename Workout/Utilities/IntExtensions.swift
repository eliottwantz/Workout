//
//  IntExtensions.swift
//  Workout
//
//  Created by Eliott on 2025-04-04.
//

import Foundation

extension Int {
  var formattedRestTime: String {
    let minutes = self / 60
    let remainingSeconds = self % 60

    if minutes > 0 {
      return "\(minutes)m \(remainingSeconds)s"
    } else {
      return "\(self)s"
    }
  }
}
