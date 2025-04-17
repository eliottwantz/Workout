import Combine
import SwiftData
import SwiftUI
import UserNotifications

// Define the EnvironmentKey for the ViewModel
private struct StartedWorkoutViewModelKey: EnvironmentKey {
  static let defaultValue = StartedWorkoutViewModel()
}

// Extend EnvironmentValues to include the ViewModel
extension EnvironmentValues {
  var startedWorkoutViewModel: StartedWorkoutViewModel {
    get { self[StartedWorkoutViewModelKey.self] }
    set { self[StartedWorkoutViewModelKey.self] = newValue }
  }
}

@Observable
class StartedWorkoutViewModel {
  var workout: Workout? = nil  // Make workout optional

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
    }
  }

  // Call this to end the workout session
  func stop() {
    removeAllPendingNotifications()  // Clean up notifications
    self.workout = nil
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

  private func moveToNextSet() {
    removeAllPendingNotifications()  // Cancel timer for the completed rest/set
    if let currentSet = currentWorkoutSet, currentSet.isLastSetInWorkout {
      // Mark workout as complete
      isWorkoutComplete = true
      print("Workout complete!")
    }
    currentSetIndex += 1
    isResting = false  // Ensure resting state is reset when moving
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

  private func startRestTimer() {
    guard let currentSet = currentWorkoutSet, currentSet.restTime > 0 else {
      moveToNextSet()  // Should not happen if shouldShowRest was true, but safeguard
      return
    }

    isResting = true
    currentTimerId = UUID().uuidString  // New ID for this specific timer instance
    scheduleRestFinishedNotification(timeInterval: TimeInterval(currentSet.restTime))
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

  func removeAllPendingNotifications() {
    let center = UNUserNotificationCenter.current()
    // Remove specific timer notification if ID is known, or all if needed broadly
    if !currentTimerId.isEmpty {
      center.removePendingNotificationRequests(withIdentifiers: [currentTimerId])
      print("Removed pending notification with ID: \(currentTimerId)")
    }
    // Uncomment below to remove *all* app notifications if necessary
    // center.removeAllPendingNotificationRequests()
    // print("Removed all pending notifications")
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
    // No rest after the absolute last set of the entire workout
    if isLastSetInWorkout {
      return false
    }

    // If part of a superset, rest only occurs *after* the last exercise *in that round* of the superset
    if isSuperset {
      guard let superset = exercise.containingSuperset else { return false }
      let lastExerciseInSuperset = superset.orderedExercises.last
      return exercise == lastExerciseInSuperset && (superset.restTime > 0)
    } else {
      // For regular exercises, show rest if the exercise has rest time > 0
      return exercise.restTime > 0
    }
  }
}
