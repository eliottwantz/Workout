//
//  WorkoutListView.swift
//  Workout
//
//  Created by Eliott on 2025-04-05.
//

import Combine
import SwiftData
import SwiftUI
import UserNotifications

// Define a struct to represent a single set in our flattened workout sequence
struct WorkoutSet: Identifiable {
  let id = UUID()
  let itemIndex: Int  // Index of the WorkoutItem in the workout
  let exerciseIndex: Int  // Index of the Exercise within a superset (0 for regular exercises)
  let setIndex: Int  // Index of the SetEntry within the exercise
  let exercise: Exercise  // Reference to the actual exercise
  let set: SetEntry  // Reference to the actual set
  let isSuperset: Bool  // Whether this set is part of a superset

  // Helper computed properties
  var exerciseDefinition: ExerciseDefinition? { exercise.definition }
  var exerciseName: String { exerciseDefinition?.name ?? "Unknown Exercise" }
  var restTime: Int {
    if isSuperset {
      // For supersets, use the superset's rest time
      return exercise.containingSuperset?.restTime ?? 0
    } else {
      // For regular exercises, use the exercise's rest time
      return exercise.restTime
    }
  }

  // Determines if rest should be shown after this set
  var shouldShowRest: Bool {
    if isSuperset {
      // Only show rest after the last exercise in a superset
      if let superset = exercise.containingSuperset {
        let lastExerciseInSuperset = superset.exercises.last
        return exercise == lastExerciseInSuperset
      }
      return false
    } else {
      // Always show rest after a regular exercise set (unless rest time is 0)
      return restTime > 0
    }
  }
}

struct StartedWorkoutView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.userAccentColor) private var userAccentColor
  @Bindable var workout: Workout

  // State for tracking current position in workout
  @State private var currentSetIndex = 0
  @State private var isResting = false
  @State private var currentTimerId = UUID().uuidString

  // Our flattened list of all sets in the workout, in order
  @State private var workoutSets = [WorkoutSet]()

  // Computed properties to access the current and next set
  private var currentWorkoutSet: WorkoutSet? {
    guard !workoutSets.isEmpty, currentSetIndex < workoutSets.count else { return nil }
    return workoutSets[currentSetIndex]
  }

  private var nextWorkoutSet: WorkoutSet? {
    guard !workoutSets.isEmpty, currentSetIndex + 1 < workoutSets.count else { return nil }
    return workoutSets[currentSetIndex + 1]
  }

  // Function to build the flattened list of workout sets
  private func buildWorkoutSetsList() {
    var sets: [WorkoutSet] = []

    for (itemIndex, item) in workout.orderedItems.enumerated() {
      if let exercise = item.exercise {
        // Regular exercise - add all its sets
        for (setIndex, set) in exercise.sets.enumerated() {
          sets.append(
            WorkoutSet(
              itemIndex: itemIndex,
              exerciseIndex: 0,
              setIndex: setIndex,
              exercise: exercise,
              set: set,
              isSuperset: false
            )
          )
        }
      } else if let superset = item.superset {
        // Superset - add first set of each exercise in the superset, then second set, etc.
        let maxNumberOfSets = (superset.exercises.map { $0.sets.count }.max()) ?? 0
        for setIndex in 0..<maxNumberOfSets {
          for exercise in superset.exercises {
            guard setIndex < exercise.sets.count else { continue }
            let set = exercise.sets[setIndex]
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

    workoutSets = sets
  }

  // Request notification permissions
  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        print("Notification permission granted")
      } else if let error = error {
        print("Error requesting notification permissions: \(error.localizedDescription)")
      }
    }
  }

  // Updated function to move to the next set
  private func moveToNextSet() {
    removeAllPendingNotifications()
    currentSetIndex += 1
  }

  // Function to handle when user completes a set
  private func handleDoneSet() {
    if isResting {
      // If we're resting, just move to next set
      isResting = false
      moveToNextSet()
    } else {
      // Check if there's a rest period after this set
      if let currentSet = currentWorkoutSet, currentSet.shouldShowRest {
        startRestTimer()
      } else {
        // No rest needed, just move to next set
        moveToNextSet()
      }
    }
  }

  // Start the rest timer
  private func startRestTimer() {
    guard let currentSet = currentWorkoutSet, currentSet.restTime > 0 else {
      moveToNextSet()
      return
    }

    isResting = true

    // Generate a new timer ID for this rest period
    currentTimerId = UUID().uuidString

    // Schedule a notification for when rest is finished
    scheduleRestFinishedNotification(timeInterval: TimeInterval(currentSet.restTime))
  }

  // Function to schedule a notification for when rest time is finished
  private func scheduleRestFinishedNotification(timeInterval: TimeInterval) {
    // Remove any pending notifications first
    removeAllPendingNotifications()

    // Create notification content
    let content = UNMutableNotificationContent()

    if let nextDefinition = nextWorkoutSet?.exerciseDefinition {
      // Next exercise exists, notify about the next exercise
      content.title = "Rest Time Finished!"
      content.body = "Time to start your next set of \(nextDefinition.name)"
    } else {
      // No next exercise, workout is complete
      content.title = "Workout Complete!"
      content.body = "Great job! You've finished your workout."
    }

    content.sound = .default

    // Create trigger (fire immediately)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

    // Create request
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: trigger
    )

    // Add request to notification center
    print("Schedule notification for rest timer: \(timeInterval) seconds")
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error scheduling notification: \(error.localizedDescription)")
      }
    }
  }

  // Function to remove all pending notifications
  private func removeAllPendingNotifications() {
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.removeAllPendingNotificationRequests()
    print("Removed all pending notifications")
  }

  var body: some View {
    VStack {
      HStack {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
            .font(.title2)
            .foregroundColor(.primary)
            .padding()
        }

        Spacer()

        Text("Workout Session")
          .font(.headline)

        Spacer()

        // Empty view for symmetry
        Image(systemName: "xmark")
          .font(.title2)
          .foregroundColor(.clear)
          .padding()
      }
      .frame(maxWidth: .infinity)

      if let currentSet = currentWorkoutSet, let exerciseDefinition = currentSet.exerciseDefinition {
        // Current exercise and set
        VStack(spacing: 12) {
          HStack {
            Text(exerciseDefinition.name)
              .font(.title)
              .fontWeight(.bold)
              .multilineTextAlignment(.center)

            Spacer()

            Text("SET \(currentSet.setIndex + 1)/\(currentSet.exercise.sets.count)")
              .font(.headline)
              .foregroundColor(.secondary)
          }
          .padding(.horizontal)

          HStack(spacing: 35) {
            VStack {
              Text("REPS")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(currentSet.set.reps)")
                .font(.title2)
                .fontWeight(.semibold)
            }

            VStack {
              Text("WEIGHT")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(currentSet.set.weight, specifier: "%.1f") kg")
                .font(.title2)
                .fontWeight(.semibold)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(25)
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(15)
          .padding(.horizontal)
        }

        Spacer()

        // Middle action button or rest timer
        VStack {
          if isResting {
            CountdownTimer(
              time: currentSet.restTime,
              id: currentTimerId,
              onComplete: {
                isResting = false
                moveToNextSet()
              }
            )

            Button("Skip Rest") {
              handleDoneSet()
            }
            .padding(.top, 20)
          } else {
            Button {
              handleDoneSet()
            } label: {
              Text("Done Set")
                .font(.headline)
                .frame(width: 200, height: 60)
                .background(userAccentColor)
                .foregroundStyle(userAccentColor.contrastColor)
                .cornerRadius(15)
            }
          }
        }
        .padding()

        Spacer()

        // Next set information
        if let nextSet = nextWorkoutSet, let nextDefinition = nextSet.exerciseDefinition {
          VStack(spacing: 12) {
            HStack {
              Text("NEXT: \(nextDefinition.name)")
                .font(.headline)
                .foregroundColor(.secondary)

              Spacer()

              Text("SET \(nextSet.setIndex + 1)/\(nextSet.exercise.sets.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            HStack(spacing: 35) {
              VStack {
                Text("REPS")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text("\(nextSet.set.reps)")
                  .font(.title3)
              }

              VStack {
                Text("WEIGHT")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text("\(nextSet.set.weight, specifier: "%.1f") kg")
                  .font(.title3)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
            .padding(.horizontal)
          }
        } else {
          VStack(spacing: 10) {
            Text("WORKOUT COMPLETE")
              .font(.headline)
              .foregroundColor(.secondary)

            Text("No more sets in this workout")
              .font(.body)
              .foregroundColor(.secondary)
              .padding(.vertical, 10)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
          }
          .frame(maxWidth: .infinity)
          .padding(25)
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(15)
          .padding(.horizontal)
        }
      } else {
        Text("Workout Complete!")
          .font(.largeTitle)
          .fontWeight(.bold)
        Spacer()
        Text("🏆🏆🏆")
          .font(.largeTitle)
          .fontWeight(.bold)
        Spacer()
        Button {
          dismiss()
        } label: {
          Text("Finish")
            .font(.headline)
            .frame(width: 200, height: 60)
            .background(userAccentColor)
            .foregroundStyle(userAccentColor.contrastColor)
            .cornerRadius(15)
        }
      }
    }
    .onAppear {
      requestNotificationPermissions()
      buildWorkoutSetsList()
    }
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer
  let modelContext = container.mainContext
  AppContainer.addSampleData(modelContext)

  let workoutFetchDescriptor = FetchDescriptor<Workout>()
  let workouts = try! modelContext.fetch(workoutFetchDescriptor)
  let sampleWorkout = workouts.first ?? Workout(date: Date())

  return StartedWorkoutView(workout: sampleWorkout)
    .modelContainer(container)
}
