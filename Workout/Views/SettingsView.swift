//
//  SettingsView.swift
//  Workout
//
//  Created by Eliott on 2025-04-06.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage(UserAccentColorStorageKey) private var storedColor: Color = .pink
  @AppStorage(AllowMultipleWorkoutsPerDayKey) private var allowMultipleWorkoutsPerDay: Bool = false
  @AppStorage(DisplayWeightInLbsKey) private var displayWeightInLbs: Bool = false

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
    }
    .tint(storedColor)
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  SettingsView()
}
