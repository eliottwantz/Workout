//
//  Router.swift
//  Workout
//
//  Created by Eliott on 2025-09-19.
//

import SwiftUI

@Observable
class Router<Route: Hashable> {
  var path = [Route]()

  func navigate(path: [Route]) {
    self.path = path
  }

  func push(to route: Route) {
    path.append(route)
  }

  func back() {
    guard !path.isEmpty else { return }
    path.removeLast()
  }

  func popToRoot() {
    path = []
  }
}

@Observable
final class WorkoutsRouter: Router<WorkoutsRouter.Route> {
  enum Route: Hashable {
    case workoutList
    case workoutDetail(workout: Workout)
    case exerciseDetail(exercise: Exercise)
    case settings
    case startedWorkout(workout: Workout)
  }

  var currentRoute: Route {
    guard let last = path.last else {
      return .workoutList
    }
    return last
  }
}

@Observable
final class ExercisesRouter: Router<ExercisesRouter.Route> {
  enum Route: Hashable {
    case exerciseList
    case exerciseDefinitionDetailView(exercise: ExerciseDefinition)
    case settings
  }

  var currentRoute: Route {
    guard let last = path.last else {
      return .exerciseList
    }
    return last
  }
}

@Observable
final class AppRouter {
  var workouts = WorkoutsRouter()
  var exercises = ExercisesRouter()

  enum Tabs: Hashable {
    case workouts
    case exercises
  }

  var selectedTab: Tabs = .workouts
}

extension AppRouter {

  struct RootTabView: View {
    @Environment(\.router) private var router

    var body: some View {
      @Bindable var router = router

      TabView(selection: $router.selectedTab) {
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

extension EnvironmentValues {
  @Entry var router = AppRouter()
}

// enum Route: Hashable {
//   case workoutList
//   case workoutDetail(workout: Workout)
//   case settings
//   case exerciseList
//   case exerciseDetailView(exercise: Exercise)
// }

// @Observable
// final class Router {
//   var path = [Route]()
//   var currentRoute: Route {
//     guard let last = path.last else {
//       return .workoutList
//     }
//     return last
//   }

//   func navigate(to route: Route) {
//     path.append(route)
//   }

//   func navigateBack() {
//     guard !path.isEmpty else { return }
//     path.removeLast()
//   }

//   func navigateToRoot() {
//     path.removeLast(path.count)
//   }

// }

// extension EnvironmentValues {
//   @Entry var router = Router()
// }
