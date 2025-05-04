//
//  SettingsView.swift
//  Workout
//
//  Created by Eliott on 2025-04-06.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage(UserAccentColorKey) private var storedColor: Color = .pink
  @AppStorage(AllowMultipleWorkoutsPerDayKey) private var allowMultipleWorkoutsPerDay: Bool = false
  @AppStorage(DisplayWeightInLbsKey) private var displayWeightInLbs: Bool = false
  @AppStorage(ShowLastSetRestTimeKey) private var showLastSetRestTime: Bool = false
  @Environment(\.startedWorkoutViewModel) private var startedWorkoutViewModel

  var body: some View {
    List {
      Section("Appearance") {
        ColorPicker("Color theme", selection: $storedColor)
          .onChange(of: storedColor) { oldValue, newValue in
            print("storedColor changed: \(oldValue) -> \(newValue)")
            guard oldValue != newValue else { return }
            startedWorkoutViewModel.updateLiveActivityColor(color: newValue)
          }
      }

      Section("Workouts") {
        Toggle("Allow multiple workouts per day", isOn: $allowMultipleWorkoutsPerDay)
      }

      Section("Weight Display") {
        Toggle("Display weight in lbs", isOn: $displayWeightInLbs)
          .onChange(of: displayWeightInLbs) { oldValue, newValue in
            print("displayWeightInLbs changed: \(oldValue) -> \(newValue)")
            guard oldValue != newValue else { return }
            startedWorkoutViewModel.updateLiveActivityWeightDisplay(displayWeightInLbs: newValue)
          }
      }

      Section("Rest Time") {
        Toggle("Show rest time for last set of exercise/superset", isOn: $showLastSetRestTime)
      }
    }
    .tint(storedColor)
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)

  }
}

#Preview {
  SettingsView()
}
