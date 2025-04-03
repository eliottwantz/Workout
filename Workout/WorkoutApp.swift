//
//  WorkoutApp.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

@main
struct WorkoutApp: App {
  
  init() {
    // Print the Application Support directory path on startup
    if let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    {
      print("Application Support Path: \(appSupportDirectory.path)")
    } else {
      print("Unable to access Application Support directory")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(AppContainer.shared.modelContainer)
  }
}
