//
//  ContentView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct ContentView: View {

  enum Tab {
    case workouts
    case exercises
  }

  @State private var selectedTab: Tab = .workouts

  var body: some View {
    TabView(selection: $selectedTab) {
      WorkoutListView()
        .tabItem {
          Label("Workouts", systemImage: "figure.run")
        }
        .tag(Tab.workouts)

      ExerciseDefinitionListView()
        .tabItem {
          Label("Exercises", systemImage: "dumbbell")
        }
        .tag(Tab.exercises)
    }
    .dismissKeyboardOnTap()
    .startedWorkoutBottomSheet()
  }
}

#Preview {
  ContentView()
    .withGeometryEnvironment()
    .modelContainer(AppContainer.preview.modelContainer)
}
