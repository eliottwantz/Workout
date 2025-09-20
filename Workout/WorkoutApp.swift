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
  @State private var startedWorkoutViewModel = StartedWorkoutViewModel()
  @State private var router = Router()
  @AppStorage(UserAccentColorKey) private var userAccentColor: Color = .pink
  @Environment(\.scenePhase) private var scenePhase

  init() {
    // Print the Application Support directory path on startup
    if let appSupportDirectory = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first {
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
        .environment(\.router, router)
        .onAppear {
          setupKeyboardMonitors()
          ensureUserDefaultsAreSetUp()
          setupViewModelWithModelContext()
          startedWorkoutViewModel.restoreStateIfNeeded()
          startedWorkoutViewModel.cleanUpExistingLiveActivities()
        }
        .onDisappear { dismantleKeyboarMonitors() }
        .onChange(of: scenePhase) { oldPhase, newPhase in
          handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
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
    ensureUserDefaults(forKey: ShowLastSetRestTimeKey, false)
  }

  private func ensureUserDefaults(forKey: String, _ value: Any?) {
    if UserDefaults.standard.string(forKey: forKey) == nil {
      UserDefaults.standard.set(value, forKey: forKey)
    }
  }

  private func handleScenePhaseChange(from oldPhase: ScenePhase?, to newPhase: ScenePhase) {
    switch newPhase {
    case .background, .inactive:
      // Save state when app goes to background or becomes inactive
      startedWorkoutViewModel.saveStateToUserDefaults()
    case .active:
      // Restore state when app becomes active (if needed)
      startedWorkoutViewModel.restoreStateIfNeeded()
      // Clean up any duplicate live activities
      startedWorkoutViewModel.cleanUpExistingLiveActivities()
    @unknown default:
      break
    }
  }

  private func setupViewModelWithModelContext() {
    startedWorkoutViewModel.setModelContext(AppContainer.shared.modelContainer.mainContext)
  }
}
