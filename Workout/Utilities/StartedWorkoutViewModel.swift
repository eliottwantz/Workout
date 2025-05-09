import ActivityKit
import Combine
import SwiftData
import SwiftUI
import UserNotifications

// Extend EnvironmentValues to include the ViewModel
extension EnvironmentValues {
  @Entry var startedWorkoutViewModel = StartedWorkoutViewModel()
}

@Observable
class StartedWorkoutViewModel {
  var workout: Workout? = nil  // Make workout optional
  var liveActivity: Activity<RestTimeCountdownAttributes>?

  // Workout Progress State
  var currentSetIndex = 0
  var isResting = false
  var currentTimerId = UUID().uuidString
  var isWorkoutComplete = false
  var workoutSets: [WorkoutSet] {
    return buildWorkoutSetsList()
  }

  var currentWorkoutSet: WorkoutSet? {
    guard workout != nil, !workoutSets.isEmpty, currentSetIndex < workoutSets.count else { return nil }
    return workoutSets[currentSetIndex]
  }

  var nextWorkoutSet: WorkoutSet? {
    guard workout != nil, !workoutSets.isEmpty, currentSetIndex + 1 < workoutSets.count else { return nil }
    return workoutSets[currentSetIndex + 1]
  }

  // --- Lifecycle Methods ---

  // Call this to start a workout session
  func start(workout: Workout) {
    withAnimation {
      self.workout = workout
      self.isWorkoutComplete = false
      self.currentSetIndex = 0
      self.isResting = false
      self.currentTimerId = UUID().uuidString  // Reset timer ID
      requestNotificationPermissions()  // Ensure permissions are requested
      startLiveActivity()  // Start live activity when workout begins
    }
  }

  // Call this to end the workout session
  func stop() {
    removeAllPendingNotifications()  // Clean up notifications
    stopLiveActivity()
    removeTimerIdFromUserDefaults()
    self.workout = nil
    liveActivity = nil
  }

  // --- Workout Progression Methods ---

  func buildWorkoutSetsList() -> [WorkoutSet] {
    var sets = [WorkoutSet]()
    guard let workout = workout else {
      return sets
    }

    for (itemIndex, item) in workout.orderedItems.enumerated() {
      if let exercise = item.exercise {
        for (setIndex, set) in exercise.orderedSets.enumerated() {  // Use orderedSets
          sets.append(
            WorkoutSet(
              itemIndex: itemIndex,
              exerciseIndex: 0,  // Not applicable for regular exercise
              setIndex: setIndex,  // Use enumeration index for flattened list order
              exercise: exercise,
              set: set,
              isSuperset: false
            )
          )
        }
      } else if let superset = item.superset {
        // Superset - add first set of each exercise in the superset, then second set, etc.
        let maxNumberOfSets = (superset.orderedExercises.map { $0.orderedSets.count }.max()) ?? 0
        for setIndex in 0..<maxNumberOfSets {
          for exercise in superset.orderedExercises {
            guard setIndex < exercise.orderedSets.count else { continue }
            let set = exercise.orderedSets[setIndex]
            sets.append(
              WorkoutSet(
                itemIndex: itemIndex,
                exerciseIndex: exercise.orderWithinSuperset,
                setIndex: set.order,
                exercise: exercise,
                set: set,
                isSuperset: true
              )
            )
          }
        }
      }
    }

    if !sets.isEmpty {
      sets[sets.count - 1].isLastSetInWorkout = true
    }

    // Adjust index if the list changed (e.g., workout edited mid-session)
    if currentSetIndex >= sets.count {
      currentSetIndex = max(0, sets.count - 1)
      if sets.isEmpty { currentSetIndex = 0 }  // Handle case where workout becomes empty
    }

    return sets
  }

  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        print("Notification permission granted")
      } else if let error = error {
        print("Error requesting notification permissions: \(error.localizedDescription)")
      }
    }
  }

  private func startRestTimer() {
    guard let currentSet = currentWorkoutSet, currentSet.restTime > 0 else {
      moveToNextSet()  // Should not happen if shouldShowRest was true, but safeguard
      return
    }
    isResting = true
    currentTimerId = UUID().uuidString  // New ID for this specific timer instance
    scheduleRestFinishedNotification(timeInterval: TimeInterval(currentSet.restTime))
    updateLiveActivity()  // Update live activity when starting rest timer
  }

  private func moveToNextSet() {
    removeAllPendingNotifications()  // Cancel timer for the completed rest/set
    removeTimerIdFromUserDefaults()

    if let currentSet = currentWorkoutSet, currentSet.isLastSetInWorkout {
      // Mark workout as complete
      isWorkoutComplete = true
      print("Workout complete!")
    }
    currentSetIndex += 1
    isResting = false  // Ensure resting state is reset when moving
    updateLiveActivity()
  }

  func handleDoneSet() {
    guard !isWorkoutComplete else { return }  // Don't do anything if workout finished

    if isResting {
      // If currently resting, completing the action means skipping the rest
      isResting = false
      moveToNextSet()
    } else {
      // If not resting, check if rest is needed after this set
      if let currentSet = currentWorkoutSet, currentSet.shouldShowRest {
        startRestTimer()
      } else {
        // No rest needed, move directly to the next set
        moveToNextSet()
      }
    }
  }

  private func scheduleRestFinishedNotification(timeInterval: TimeInterval) {
    removeAllPendingNotifications()  // Clear any previous timer notification

    let content = UNMutableNotificationContent()
    if let nextSet = nextWorkoutSet, let nextDef = nextSet.exerciseDefinition {
      content.title = "Rest Time Finished!"
      content.body = "Time for \(nextDef.name) (Set \(nextSet.setIndex + 1))"
    } else {
      content.title = "Last Set Complete!"
      content.body = "Workout finished. Great job!"
    }
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
    let request = UNNotificationRequest(identifier: currentTimerId, content: content, trigger: trigger)

    print("Scheduling notification (\(currentTimerId)) for rest timer: \(timeInterval) seconds")
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error scheduling notification: \(error.localizedDescription)")
      }
    }
  }

  private func removeAllPendingNotifications() {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
    print("Removed all pending notifications")
  }

  private func stopLiveActivity() {
    guard let liveActivity = liveActivity else { return }
    Task {
      await liveActivity.end(nil, dismissalPolicy: .immediate)
    }
  }

  func updateLiveActivity() {
    guard let liveActivity = liveActivity, let currentSet = currentWorkoutSet else { return }

    Task {
      let userAccentColor =
        Color(rawValue: UserDefaults.standard.string(forKey: UserAccentColorKey) ?? "#FFFFFF") ?? .blue
      let displayWeightInLbs = UserDefaults.standard.bool(forKey: "displayWeightInLbs")
      let restTime = currentSet.restTime
      let endTime = Date().addingTimeInterval(TimeInterval(restTime))
      let timerInterval = Date.now...endTime

      await liveActivity.update(
        .init(
          state: .init(
            displayWeightInLbs: displayWeightInLbs,
            userAccentColor: userAccentColor,
            exercise: currentSet.exerciseName,
            set: currentSetIndex + 1,
            totalSets: workoutSets.count,
            setForCurrentExercise: currentSet.setIndex + 1,  // Set number for the current exercise
            setsForCurrentExercise: currentSet.exercise.orderedSets.count,  // Sets for current exercise
            reps: currentSet.set.reps,
            weight: currentSet.set.weight,
            endTime: endTime,
            restTime: restTime,
            isResting: isResting,
            timerInterval: timerInterval,
            nextExercise: nextWorkoutSet?.exerciseName,
            nextReps: nextWorkoutSet?.set.reps,
            nextWeight: nextWorkoutSet?.set.weight,
            setForNextExercise: nextWorkoutSet != nil ? nextWorkoutSet!.setIndex + 1 : nil,
            setsForNextExercise: nextWorkoutSet?.exercise.orderedSets.count
          ),
          staleDate: nil
        )
      )
    }
  }

  private func startLiveActivity() {
    stopLiveActivity()

    guard let currentSet = currentWorkoutSet else { return }

    let userAccentColor =
      Color(rawValue: UserDefaults.standard.string(forKey: UserAccentColorKey) ?? "#FFFFFF") ?? .blue
    let displayWeightInLbs = UserDefaults.standard.bool(forKey: "displayWeightInLbs")
    let restTime = currentSet.restTime
    let endTime = Date().addingTimeInterval(TimeInterval(restTime))
    let timerInterval = Date.now...endTime

    let state = RestTimeCountdownAttributes.ContentState(
      displayWeightInLbs: displayWeightInLbs,
      userAccentColor: userAccentColor,
      exercise: currentSet.exerciseName,
      set: currentSetIndex + 1,
      totalSets: workoutSets.count,
      setForCurrentExercise: currentSet.setIndex + 1,  // Set number for the current exercise
      setsForCurrentExercise: currentSet.exercise.orderedSets.count,  // Sets for current exercise
      reps: currentSet.set.reps,
      weight: currentSet.set.weight,
      endTime: endTime,
      restTime: restTime,
      isResting: isResting,
      timerInterval: timerInterval,
      nextExercise: nextWorkoutSet?.exerciseName,
      nextReps: nextWorkoutSet?.set.reps,
      nextWeight: nextWorkoutSet?.set.weight,
      setForNextExercise: nextWorkoutSet != nil ? nextWorkoutSet!.setIndex + 1 : nil,
      setsForNextExercise: nextWorkoutSet?.exercise.orderedSets.count
    )

    let attributes = RestTimeCountdownAttributes(
      timerId: currentTimerId
    )

    do {
      liveActivity = try Activity<RestTimeCountdownAttributes>.request(
        attributes: attributes,
        content: .init(state: state, staleDate: nil),
        pushType: nil
      )
    } catch {
      print("Error starting live activity: \(error)")
    }
  }

  private func removeTimerIdFromUserDefaults() {
    UserDefaults.standard.removeObject(forKey: "timer_\(currentTimerId)")
  }

  func navigateToPreviousSet() {
    if currentSetIndex > 0 {
      if isResting {
        isResting = false
        removeAllPendingNotifications()  // Cancel rest timer
      }
      currentSetIndex -= 1
    }
  }

  // Navigate to next set, potentially skipping rest if currently resting
  func navigateToNextSet() {
    if isResting {
      isResting = false
      removeAllPendingNotifications()  // Cancel rest timer
      startLiveActivity()  // Restart live activity with new set info
    }
    // Advance index only if not already at/past the end
    if currentSetIndex < workoutSets.count {
      moveToNextSet()  // Use moveToNextSet to handle logic consistently
    }
  }

  // Explicit action to skip the current rest timer
  func skipRest() {
    if isResting {
      isResting = false
      moveToNextSet()  // Move to the next set immediately
    }
  }

  // Called by the CountdownTimer when it finishes naturally
  func timerDidComplete() {
    // Check if we were actually resting for the completed timer ID? (Optional robustness)
    print("Timer \(currentTimerId) completed")
    if isResting {
      isResting = false
      moveToNextSet()
    }
  }
}

// Helper struct WorkoutSet remains the same for now, could potentially be moved too
struct WorkoutSet: Identifiable {
  let id = UUID()
  let itemIndex: Int  // Index of the WorkoutItem in the workout
  let exerciseIndex: Int  // Index of the Exercise within a superset (0 for regular exercises)
  let setIndex: Int  // Index of the SetEntry within the exercise
  let exercise: Exercise  // Reference to the actual exercise
  let set: SetEntry  // Reference to the actual set
  let isSuperset: Bool  // Whether this set is part of a superset
  var isLastSetInWorkout: Bool = false

  // Helper computed properties
  var exerciseDefinition: ExerciseDefinition? { exercise.definition }
  var exerciseName: String { exerciseDefinition?.name ?? "Unknown Exercise" }
  var restTime: Int {
    if isSuperset {
      // For supersets, use the superset's rest time
      // Check the specific exercise's rest time *within* the superset if applicable,
      // otherwise fall back to the superset's overall rest time.
      // This depends on your data model logic. Assuming superset rest time applies after *all* exercises in a round.
      return exercise.containingSuperset?.restTime ?? 0
    } else {
      // For regular exercises, use the exercise's rest time
      return exercise.restTime
    }
  }

  // Determines if rest should be shown *after* this specific set
  var shouldShowRest: Bool {
    // Rule 1: Never show rest after the very last set of the entire workout.
    if isLastSetInWorkout { return false }

    // Rule 2: Never show rest if the applicable rest time (exercise or superset) is zero.
    //         (The `restTime` computed property correctly determines this value)
    if restTime <= 0 { return false }

    // Rule 3: For supersets, rest *only* occurs after completing a set of the *last* exercise in the cycle.
    if isSuperset {
      guard let superset = exercise.containingSuperset else { return false }  // Safety check
      let isLastExerciseInCycle = exercise == superset.orderedExercises.last
      if !isLastExerciseInCycle {
        return false  // No rest between different exercises within the same superset cycle.
      }
      // If it *is* the last exercise in the cycle, proceed to the common logic below.
    }

    // Common Logic (Applies to regular exercises and the last exercise of a superset cycle):
    let isLastSetOfThisExercise = setIndex == exercise.orderedSets.count - 1

    if isLastSetOfThisExercise {
      // Rule 4: If it's the last set of this exercise (or last exercise in superset cycle),
      //         respect the user's preference setting.
      return UserDefaults.standard.bool(forKey: ShowLastSetRestTimeKey)
    } else {
      // Rule 5: If it's *not* the last set (and restTime > 0), always show rest.
      return true
    }
  }
}
