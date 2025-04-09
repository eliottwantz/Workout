//
//  CountdownTimer.swift
//  Workout
//
//  Created by Eliott on 2025-04-05.
//

import SwiftUI

@Observable
class CountdownTimerModel {
  // Total duration in seconds
  private let totalSeconds: Int
  // Fixed end time - doesn't change when app goes to background
  private var endTime: Date
  // Key identifier for this timer instance
  private let timerKey: String

  private var timer: Timer?
  private var isActive = false

  // Current seconds remaining
  var secondsRemaining: Int = 0

  var onComplete: (() -> Void)?

  var progress: Double {
    guard totalSeconds > 0 else { return 0 }
    return 1.0 - (Double(secondsRemaining) / Double(totalSeconds))
  }

  init(seconds: Int, id: String = UUID().uuidString, onComplete: (() -> Void)?) {
    self.totalSeconds = seconds
    self.secondsRemaining = seconds
    self.onComplete = onComplete
    self.timerKey = "timer_\(id)"

    // Check if we already have a stored end time for this timer
    if let storedEndTime = UserDefaults.standard.object(forKey: timerKey) as? Date {
      // Calculate current time remaining based on the stored end time
      endTime = storedEndTime
      updateRemainingTime()
    } else {
      // Set initial end time
      endTime = Date().addingTimeInterval(TimeInterval(seconds))
      UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(seconds)), forKey: timerKey)
    }
  }

  func start() {
    guard !isActive else { return }

    isActive = true
    startTimer()
  }

  func stop() {
    isActive = false
    timer?.invalidate()
    timer = nil

    // Clear stored end time
    UserDefaults.standard.removeObject(forKey: timerKey)
  }

  // Update timer when app comes to foreground
  func updateOnForeground() {
    if isActive {
      updateRemainingTime()
      startTimer()
    }
  }

  private func startTimer() {
    timer?.invalidate()

    // First update immediately
    updateRemainingTime()

    // Create a repeating timer that fires every second
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      self.updateRemainingTime()
    }
  }

  private func updateRemainingTime() {
    let now = Date()
    if now >= endTime {
      // Timer has completed
      secondsRemaining = 0
      stop()
      onComplete?()
    } else {
      // Calculate seconds remaining
      secondsRemaining = Int(endTime.timeIntervalSince(now))
    }
  }
}

struct CountdownTimer: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.userAccentColor) private var userAccentColor
  let time: Int
  @State private var timerModel: CountdownTimerModel
  private var lineWidth: CGFloat = 20
  // Optional completion handler
  var onComplete: (() -> Void)?

  init(time: Int, id: String = UUID().uuidString, onComplete: (() -> Void)? = nil) {
    self.time = time
    self._timerModel = State(initialValue: CountdownTimerModel(seconds: time, id: id, onComplete: onComplete))
    self.onComplete = onComplete
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(lineWidth: lineWidth)
        .foregroundStyle(userAccentColor.opacity(0.3))

      Circle()
        .trim(from: 0.0, to: min(1.0 - timerModel.progress, 1.0))
        .stroke(
          userAccentColor,
          style: StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round
          )
        )
        .rotationEffect(.degrees(-90))
        .shadow(radius: 2)

      Text(displayTime(timerModel.secondsRemaining))
        .font(.system(size: 50, weight: .bold, design: .rounded))
        .monospacedDigit()
        .contentTransition(.numericText())
        .foregroundStyle(.primary)
        .animation(.linear, value: timerModel.secondsRemaining)
    }
    .frame(width: 200, height: 200)
    .animation(.easeInOut, value: timerModel.secondsRemaining)
    .onChange(of: scenePhase) { oldPhase, newPhase in
      if newPhase == .active && oldPhase == .background {
        // App came back to foreground
        timerModel.updateOnForeground()
      }
    }
    .onAppear {
      timerModel.start()
    }
    .sensoryFeedback(
      trigger: timerModel.secondsRemaining
    ) { oldValue, newValue in
      if oldValue == 1 && newValue == 0 {
        return .error
      } else if newValue <= 5 {
        return .impact
      } else {
        return nil
      }
    }
  }

  func displayTime(_ totalSeconds: Int) -> String {
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%01d:%02d", minutes, seconds)
  }
}

#Preview {
  CountdownTimer(time: 10)
}
