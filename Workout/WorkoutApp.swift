//
//  WorkoutApp.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import BackgroundTasks
import Combine
import SwiftData
import SwiftUI

@main
struct WorkoutApp: App {
  @State private var keyboardIsShown = false
  @State private var keyboardHideMonitor: AnyCancellable? = nil
  @State private var keyboardShownMonitor: AnyCancellable? = nil
  @AppStorage("userAccentColor") private var userAccentColor: Color = .yellow
  private var taskId = "\(Bundle.main.bundleIdentifier ?? "com.develiott.Workout").refresh"

  init() {
    // Print the Application Support directory path on startup
    if let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    {
      print("Application Support Path: \(appSupportDirectory.path)")
    } else {
      print("Unable to access Application Support directory")
    }

    // Register for background processing
    registerBackgroundTasks()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.userAccentColor, userAccentColor)
        .environment(\.keyboardIsShown, keyboardIsShown)
        .onAppear { setupKeyboardMonitors() }
        .onDisappear { dismantleKeyboarMonitors() }
        .tint(userAccentColor)
    }
    .modelContainer(AppContainer.shared.modelContainer)
    .backgroundTask(.appRefresh(taskId)) {
      // This task will be called periodically by the system when the app is in the background
      // The app should check for any pending timers and update their state
      print("Background refresh task executed")
    }
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

  private func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: taskId, using: nil
    ) { task in
      // Handle background task
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }
  }

  private func handleAppRefresh(task: BGAppRefreshTask) {
    // Schedule a new background task
    scheduleAppRefresh()

    // Complete the task
    task.setTaskCompleted(success: true)
  }

  private func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: taskId)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15 minutes from now

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
}
