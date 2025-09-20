import ActivityKit
import Combine
import SwiftData
import SwiftUI
import UserNotifications

// MARK: - Workout State Persistence

/// Codable structure to persist workout state across app backgrounds/foregrounds
struct WorkoutStateSnapshot: Codable {
  let workoutID: UUID
  let workoutDate: Date
  let isCollapsed: Bool
  let isPresented: Bool
  let currentSetIndex: Int
  let isResting: Bool
  let currentTimerId: String
  let isWorkoutComplete: Bool
  let restTimeStartDate: Date?
  let hasLiveActivity: Bool
  let liveActivityId: String?

  init(from workout: Workout, viewModel: StartedWorkoutViewModel) {
    self.workoutID = workout.id
    self.workoutDate = workout.date
    self.isCollapsed = viewModel.isCollapsed
    self.isPresented = viewModel.isPresented
    self.currentSetIndex = viewModel.currentSetIndex
    self.isResting = viewModel.isResting
    self.currentTimerId = viewModel.currentTimerId
    self.isWorkoutComplete = viewModel.isWorkoutComplete
    self.restTimeStartDate = viewModel.restTimeStartDate
    self.hasLiveActivity = viewModel.liveActivity != nil
    self.liveActivityId = viewModel.liveActivity?.id
  }
}

// Extend EnvironmentValues to include the ViewModel
extension EnvironmentValues {
  @Entry var startedWorkoutViewModel = StartedWorkoutViewModel()
}

@Observable
class StartedWorkoutViewModel {
  var isCollapsed: Bool { !isPresented }
  var isPresented: Bool = false
  var workout: Workout? = nil  // Make workout optional
  var liveActivity: Activity<RestTimeCountdownAttributes>?
  var restTimeStartDate: Date?

  // Workout Progress State
  var currentSetIndex = 0
  var isResting = false
  var currentTimerId = UUID().uuidString
  var isWorkoutComplete = false

  // Key for UserDefaults persistence
  private static let workoutStateKey = "savedWorkoutState"

  // Model context for data access
  private var modelContext: ModelContext?

  var workoutSets: [WorkoutSet] {
    return buildWorkoutSetsList()
  }

  var currentWorkoutSet: WorkoutSet? {
    guard workout != nil, !workoutSets.isEmpty, currentSetIndex < workoutSets.count else {
      return nil
    }
    return workoutSets[currentSetIndex]
  }

  var previousWorkoutSet: WorkoutSet? {
    guard workout != nil, !workoutSets.isEmpty, currentSetIndex > 0 else { return nil }
    return workoutSets[currentSetIndex - 1]
  }

  var nextWorkoutSet: WorkoutSet? {
    guard workout != nil, !workoutSets.isEmpty, currentSetIndex + 1 < workoutSets.count else {
      return nil
    }
    return workoutSets[currentSetIndex + 1]
  }

  var nextOfNextWorkoutSet: WorkoutSet? {
    guard workout != nil, !workoutSets.isEmpty, currentSetIndex + 2 < workoutSets.count else {
      return nil
    }
    return workoutSets[currentSetIndex + 2]
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
      expand()
    }
  }

  // Call this to end the workout session
  func stop() {
    removeAllPendingNotifications()  // Clean up notifications
    stopLiveActivity()
    removeTimerIdFromUserDefaults()
    clearSavedState()  // Clear persisted state when workout ends
    self.workout = nil
    liveActivity = nil
    isPresented = false
    //    isCollapsed = false
  }

  func expand() {
    //    isCollapsed = false
    isPresented = true
  }

  func collapse() {
    //    isCollapsed = true
    isPresented = false
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
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
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
    restTimeStartDate = .now
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
    let request = UNNotificationRequest(
      identifier: currentTimerId, content: content, trigger: trigger)

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

  private func findActivity(by id: String) -> Activity<RestTimeCountdownAttributes>? {
    return Activity<RestTimeCountdownAttributes>.activities.first(where: { $0.id == id })
  }

  // MARK: - Live Activity Recovery from Snapshot

  private func getSavedLiveActivityId() -> String? {
    guard let data = UserDefaults.standard.data(forKey: Self.workoutStateKey) else { return nil }

    do {
      let snapshot = try JSONDecoder().decode(WorkoutStateSnapshot.self, from: data)
      return snapshot.liveActivityId
    } catch {
      print("Failed to decode workout snapshot for live activity ID: \(error)")
      return nil
    }
  }

  private func stopLiveActivity() {
    // If liveActivity is nil, try to recover it from snapshot ID
    if liveActivity == nil, let savedId = getSavedLiveActivityId() {
      if let existingActivity = findActivity(by: savedId) {
        liveActivity = existingActivity
        print("Recovered live activity for stopping from snapshot ID: \(savedId)")
      } else {
        // Stored ID doesn't match any existing activity
        print("No live activity found for snapshot ID: \(savedId)")
        return
      }
    }

    guard let liveActivity = liveActivity else {
      print("No live activity to stop")
      return
    }

    print(
      "Stopping live activity with ID: \(liveActivity.id) and timer ID: \(liveActivity.attributes.timerId)"
    )

    Task {
      await liveActivity.end(nil, dismissalPolicy: .immediate)
      print("Live activity stopped")
    }

    // Clear the reference
    self.liveActivity = nil
  }

  private func startLiveActivityInternal() {
    guard let currentSet = currentWorkoutSet else { return }

    let userAccentColor =
      Color(rawValue: UserDefaults.standard.string(forKey: UserAccentColorKey) ?? "#FFFFFF")
      ?? .blue
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
      setForCurrentExercise: currentSet.setIndex + 1,
      setsForCurrentExercise: currentSet.exercise.orderedSets.count,
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

      if let activityId = liveActivity?.id {
        print("Started new live activity with ID: \(activityId) and timer ID: \(currentTimerId)")
      }
    } catch {
      print("Error starting live activity: \(error)")
    }
  }

  func updateLiveActivity() {
    // If liveActivity is nil, try to recover it from snapshot ID
    if liveActivity == nil, let savedId = getSavedLiveActivityId() {
      if let existingActivity = findActivity(by: savedId) {
        liveActivity = existingActivity
        print("Recovered live activity for update from snapshot ID: \(savedId)")
      } else {
        // Stored ID doesn't match any existing activity
        print("No live activity found for snapshot ID: \(savedId)")
        return
      }
    }

    guard let liveActivity = liveActivity, let currentSet = currentWorkoutSet else { return }

    Task {
      let userAccentColor =
        Color(rawValue: UserDefaults.standard.string(forKey: UserAccentColorKey) ?? "#FFFFFF")
        ?? .blue
      let displayWeightInLbs = UserDefaults.standard.bool(forKey: "displayWeightInLbs")
      let restTime = currentSet.restTime
      let endTime = (restTimeStartDate ?? Date()).addingTimeInterval(TimeInterval(restTime))
      let timerInterval = (restTimeStartDate ?? Date.now)...endTime

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
    // Check if we already have a live activity from a stored ID in snapshot
    if liveActivity == nil, let savedId = getSavedLiveActivityId() {
      if let existingActivity = findActivity(by: savedId) {
        liveActivity = existingActivity
        print("Recovered live activity from snapshot ID: \(savedId)")
        updateLiveActivity()  // Update it with current state
        return
      } else {
        // Stored ID doesn't match any existing activity
        print("No live activity found for snapshot ID: \(savedId)")
      }
    }

    // If we already have a live activity, don't create a new one
    if liveActivity != nil {
      print("Live activity already exists, updating instead of creating new one")
      updateLiveActivity()
      return
    }

    startLiveActivityInternal()
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

      // Ensure currentSetIndex is properly clamped
      currentSetIndex = max(0, min(currentSetIndex, workoutSets.count - 1))

      updateLiveActivity()  // Update live activity when going back to a previous set
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
    updateLiveActivity()  // Update live activity when going to the next set
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

  // MARK: - State Persistence

  /// Set the model context for data access
  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
  }

  /// Clean up any existing live activities that don't match our current state
  func cleanUpExistingLiveActivities() {
    Task {
      // Get all current live activities for our app
      let activities = Activity<RestTimeCountdownAttributes>.activities

      print("Found \(activities.count) existing live activitiy")

      for activity in activities {
        // If we have an active workout and this activity matches our current timer ID, keep it
        if workout != nil,
          isPresented || isCollapsed
        {
          print(
            "Keeping live activity ID \(activity.id) with timer ID: \(activity.attributes.timerId)")
          self.liveActivity = activity
        } else {
          // This is an old/duplicate activity, remove it
          print(
            "Removing stale live activity ID \(activity.id) with timer ID: \(activity.attributes.timerId)"
          )
          await activity.end(nil, dismissalPolicy: .immediate)
        }
      }

      // If we should have a live activity but don't have one, create it
      if (workout != nil) && (isPresented || isCollapsed) && (liveActivity == nil) {
        print("Creating missing live activity")
        await MainActor.run {
          startLiveActivityInternal()
        }
      }
    }
  }

  /// Save the current workout state to UserDefaults
  func saveStateToUserDefaults() {
    guard let workout = workout else {
      // No active workout, clear any saved state
      clearSavedState()
      return
    }

    print(
      "Saving workout state: \(workout.name ?? "Untitled"), set \(currentSetIndex + 1), presented: \(isPresented), collapsed: \(isCollapsed), resting: \(isResting)"
    )

    let snapshot = WorkoutStateSnapshot(from: workout, viewModel: self)
    do {
      let data = try JSONEncoder().encode(snapshot)
      UserDefaults.standard.set(data, forKey: Self.workoutStateKey)
      print("Successfully saved workout state to UserDefaults")
    } catch {
      print("Failed to save workout state: \(error)")
    }
  }

  /// Restore workout state from UserDefaults if available and valid
  func restoreStateIfNeeded() {
    // Only restore if we don't already have an active workout
    guard workout == nil else { return }

    guard let data = UserDefaults.standard.data(forKey: Self.workoutStateKey) else {
      print("No saved workout state found")
      return
    }

    do {
      let snapshot = try JSONDecoder().decode(WorkoutStateSnapshot.self, from: data)

      // Try to find the workout in the current context
      // Note: This requires access to the model context, which we'll need to provide
      if let restoredWorkout = findWorkout(id: snapshot.workoutID, date: snapshot.workoutDate) {
        print("Restoring workout state for workout: \(restoredWorkout.name ?? "Untitled")")

        // Restore the workout and state
        self.workout = restoredWorkout
        //        self.isCollapsed = snapshot.isCollapsed
        self.isPresented = snapshot.isPresented
        self.currentSetIndex = snapshot.currentSetIndex
        self.isResting = snapshot.isResting
        self.currentTimerId = snapshot.currentTimerId
        self.isWorkoutComplete = snapshot.isWorkoutComplete
        self.restTimeStartDate = snapshot.restTimeStartDate

        // Validate that the restored state is still valid
        let workoutSets = buildWorkoutSetsList()
        if currentSetIndex >= workoutSets.count {
          print(
            "Restored set index (\(currentSetIndex)) is out of bounds, resetting to last valid set")
          currentSetIndex = max(0, workoutSets.count - 1)
        }

        // If we were resting and it's been too long, stop resting
        if isResting, let restStartDate = restTimeStartDate {
          let currentSet =
            workoutSets.indices.contains(currentSetIndex) ? workoutSets[currentSetIndex] : nil
          let restDuration = currentSet?.restTime ?? 0
          let timeElapsed = Date().timeIntervalSince(restStartDate)

          if timeElapsed >= Double(restDuration) {
            print("Rest time has already elapsed, moving to next set")
            isResting = false
            // Don't automatically move to next set, let user decide
          }
        }

        // Don't restart live activity here - let cleanUpExistingLiveActivities handle it
        // during the app foreground lifecycle event

        // If we were in a presented state, make sure the sheet is shown
        if isPresented && !isCollapsed {
          // The sheet should already be presented due to the restored isPresented state
          print("Restored workout with expanded bottom sheet")
        } else if isCollapsed {
          print("Restored workout with collapsed bottom sheet")
        }

        print("Successfully restored workout state")
      } else {
        print("Could not find saved workout, clearing saved state")
        clearSavedState()
      }
    } catch {
      print("Failed to restore workout state: \(error)")
      clearSavedState()
    }
  }

  /// Clear saved state from UserDefaults
  func clearSavedState() {
    UserDefaults.standard.removeObject(forKey: Self.workoutStateKey)
    print("Cleared saved workout state")
  }

  /// Find a workout by ID and date (this needs model context access)
  private func findWorkout(id: UUID, date: Date) -> Workout? {
    guard let modelContext = modelContext else {
      print("No model context available for finding workout")
      return nil
    }

    do {
      // First try to find by exact ID
      let descriptor = FetchDescriptor<Workout>(
        predicate: #Predicate<Workout> { workout in
          workout.id == id
        }
      )
      let workouts = try modelContext.fetch(descriptor)

      // If we find the workout with the exact ID, use it
      // This is more reliable than date matching due to potential precision issues
      if let workout = workouts.first {
        return workout
      }

      // Fallback: try to find by date if ID doesn't match (workout might have been recreated)
      let calendar = Calendar.current
      let startOfDay = calendar.startOfDay(for: date)
      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

      let dateDescriptor = FetchDescriptor<Workout>(
        predicate: #Predicate<Workout> { workout in
          workout.date >= startOfDay && workout.date < endOfDay
        }
      )
      let dayWorkouts = try modelContext.fetch(dateDescriptor)
      return dayWorkouts.first

    } catch {
      print("Error fetching workout: \(error)")
      return nil
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
