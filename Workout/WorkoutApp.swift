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
  @AppStorage(UserAccentColorKey) private var userAccentColor: Color = .pink

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
        .onAppear {
          setupKeyboardMonitors()
          ensureUserDefaultsAreSetUp()
        }
        .onDisappear { dismantleKeyboarMonitors() }
        .tint(userAccentColor)
        .withGeometryEnvironment()
    }
    .modelContainer(AppContainer.shared.modelContainer)
  }

  private func setupKeyboardMonitors() {
    keyboardShownMonitor = NotificationCenter.default
      .publisher(for: UIWindow.keyboardWillShowNotification)
      .sink { _ in if !keyboardIsShown { keyboardIsShown = true } }

    keyboardHideMonitor = NotificationCenter.default
      .publisher(for: UIWindow.keyboardWillHideNotification)
      .sink { _ in if keyboardIsShown { keyboardIsShown = false } }
  }

  private func dismantleKeyboarMonitors() {
    keyboardHideMonitor?.cancel()
    keyboardShownMonitor?.cancel()
  }

  private func ensureUserDefaultsAreSetUp() {
    ensureUserDefaults(forKey: UserAccentColorKey, Color.pink.rawValue)
    ensureUserDefaults(forKey: DisplayWeightInLbsKey, false)
    ensureUserDefaults(forKey: AllowMultipleWorkoutsPerDayKey, false)
  }

  private func ensureUserDefaults(forKey: String, _ value: Any?) {
    if UserDefaults.standard.string(forKey: forKey) == nil {
      UserDefaults.standard.set(value, forKey: forKey)
    }
  }
}
