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
        .modifier(CollapsedWorkoutPaddingModifier())
        .tabItem {
          Label("Workouts", systemImage: "figure.run")
        }
        .tag(Tab.workouts)

      ExerciseDefinitionListView()
        .modifier(CollapsedWorkoutPaddingModifier())
        .tabItem {
          Label("Exercises", systemImage: "dumbbell")
        }
        .tag(Tab.exercises)
    }
    .dismissKeyboardOnTap()
    .startedWorkoutBottomSheet()
  }
}

private struct CollapsedWorkoutPaddingModifier: ViewModifier {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  
  func body(content: Content) -> some View {
    content
      .padding(.bottom, (viewModel.workout != nil && viewModel.isCollapsed) ? 66 : 0)
  }
}

#Preview {
  ContentView()
    .withGeometryEnvironment()
    .modelContainer(AppContainer.preview.modelContainer)
}
