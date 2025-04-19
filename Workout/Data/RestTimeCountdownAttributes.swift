//
//  RestTimeCountdownAttributes.swift
//  Workout
//
//  Created by Eliott on 2025-04-18.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RestTimeCountdownAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    // Dynamic stateful properties about your activity go here!
    var displayWeightInLbs: Bool
    var userAccentColor: Color
  }

  // Fixed non-changing properties about your activity go here!
  let nextExercise: String
  let nextSet: Int
  let totalSets: Int
  let nextReps: Int
  let nextWeight: Double
  let timerId: String
  let restTime: Int
  let startTime: Date
}
