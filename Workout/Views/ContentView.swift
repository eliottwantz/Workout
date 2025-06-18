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
    Group {
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
//      .applyTabBariOS26IfAvailable()
    }
  }
}

private struct CollapsedWorkoutPaddingModifier: ViewModifier {
  @Environment(\.startedWorkoutViewModel) private var viewModel

  func body(content: Content) -> some View {
//    if #available(iOS 26, *) {
//      content
//    } else {
      content
        .padding(.bottom, (viewModel.workout != nil && viewModel.isCollapsed) ? 74 : 0)
//    }
  }
}

@available(iOS 26, *)
private struct iOS26BottomSheetCollapsedModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
//      .tabBarMinimizeBehavior(.onScrollDown)
//      .tabViewBottomAccessory {
//        iOS26CollapsedWorkoutView()
//        .padding(8)
//      }
  }
}

extension View {
  fileprivate func applyTabBariOS26IfAvailable() -> some View {
    if #available(iOS 26, *) {
      return AnyView(self.modifier(iOS26BottomSheetCollapsedModifier()))
    } else {
      return AnyView(self)
    }
  }
}

#Preview {
  ContentView()
    .withGeometryEnvironment()
    .modelContainer(AppContainer.preview.modelContainer)
}
