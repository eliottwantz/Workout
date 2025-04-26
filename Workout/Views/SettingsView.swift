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

  var body: some View {
    List {
      Section("Appearance") {
        ColorPicker("Color theme", selection: $storedColor)
      }

      Section("Workouts") {
        Toggle("Allow multiple workouts per day", isOn: $allowMultipleWorkoutsPerDay)
      }

      Section("Weight Display") {
        Toggle("Display weight in lbs", isOn: $displayWeightInLbs)
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
