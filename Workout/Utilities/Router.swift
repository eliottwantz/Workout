//
//  Router.swift
//  Workout
//
//  Created by Eliott on 2025-09-19.
//

import SwiftUI

enum Route: Hashable {
  case workoutList
  case workoutDetail(workout: Workout)
  case settings
  case exerciseList
  case exerciseDetailView(exercise: Exercise)
}

@Observable
final class Router {
  var path = [Route]()
  var currentRoute: Route {
    guard let last = path.last else {
      return .workoutList
    }
    return last
  }

  func navigate(to route: Route) {
    path.append(route)
  }

  func navigateBack() {
    guard !path.isEmpty else { return }
    path.removeLast()
  }

  func navigateToRoot() {
    path.removeLast(path.count)
  }

}

extension EnvironmentValues {
  @Entry var router = Router()
}
