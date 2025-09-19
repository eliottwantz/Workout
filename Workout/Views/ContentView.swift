//
//  ContentView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct ContentView: View {

  enum Tabs {
    case workouts
    case exercises
  }

  @State private var selectedTab: Tabs = .workouts

  var body: some View {
    Group {
      TabView(selection: $selectedTab) {
        Tab("Workouts", systemImage: "dumbbell.fill", value: .workouts) {
          WorkoutListView()
        }

        Tab("Exercises", systemImage: "figure.strengthtraining.traditional", value: .exercises) {
          ExerciseDefinitionListView()
        }
      }
      .dismissKeyboardOnTap()
      .startedWorkoutBottomSheet()
    }
  }
}

#Preview {
  ContentView()
    .withGeometryEnvironment()
    .modelContainer(AppContainer.preview.modelContainer)
}
