//
//  WorkoutApp.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import Combine
import SwiftData
import SwiftUI

@main
struct WorkoutApp: App {
  @State private var keyboardIsShown = false
  @State private var keyboardHideMonitor: AnyCancellable? = nil
  @State private var keyboardShownMonitor: AnyCancellable? = nil
  @State var startedWorkoutViewModel = StartedWorkoutViewModel()
  @AppStorage(UserAccentColorStorageKey) private var userAccentColor: Color = .pink

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
        .environment(\.userAccentColor, userAccentColor)
        .environment(\.keyboardIsShown, keyboardIsShown)
        .environment(\.startedWorkoutViewModel, startedWorkoutViewModel)
        .onAppear { setupKeyboardMonitors() }
        .onDisappear { dismantleKeyboarMonitors() }
        .tint(userAccentColor)
        .withGeometryEnvironment()
    }
    .modelContainer(AppContainer.shared.modelContainer)
  }

  func setupKeyboardMonitors() {
    keyboardShownMonitor = NotificationCenter.default
      .publisher(for: UIWindow.keyboardWillShowNotification)
      .sink { _ in if !keyboardIsShown { keyboardIsShown = true } }

    keyboardHideMonitor = NotificationCenter.default
      .publisher(for: UIWindow.keyboardWillHideNotification)
      .sink { _ in if keyboardIsShown { keyboardIsShown = false } }
  }

  func dismantleKeyboarMonitors() {
    keyboardHideMonitor?.cancel()
    keyboardShownMonitor?.cancel()
  }
}
