//
//  SettingsView.swift
//  Workout
//
//  Created by Eliott on 2025-04-06.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage("userAccentColor") var storedColor: Color = .yellow
  @AppStorage(AllowMultipleWorkoutsPerDayKey) var allowMultipleWorkoutsPerDay: Bool = false
  @AppStorage("displayWeightInLbs") private var displayWeightInLbs: Bool = false

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
