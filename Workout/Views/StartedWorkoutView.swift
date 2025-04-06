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

struct StartedWorkoutView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.userAccentColor) private var userAccentColor
  @Bindable var workout: Workout

  @State private var currentItemIndex = 0
  @State private var currentExerciseIndex = 0
  @State private var currentSetIndex = 0
  @State private var isResting = false
  @State private var currentTimerId = UUID().uuidString

  private var currentItem: WorkoutItem? {
    guard currentItemIndex < workout.orderedItems.count else { return nil }
    return workout.orderedItems[currentItemIndex]
  }

  private var currentExercise: Exercise? {
    if let item = currentItem {
      if let exercise = item.exercise {
        return exercise
      } else if let superset = item.superset {
        guard currentExerciseIndex < superset.exercises.count else { return nil }
        return superset.exercises[currentExerciseIndex]
      }
    }
    return nil
  }

  private var nextExercise: Exercise? {
    if let item = currentItem {
      if item.exercise != nil {
        // Check if there's another item
        if currentItemIndex + 1 < workout.orderedItems.count {
          let nextItem = workout.orderedItems[currentItemIndex + 1]
          if let nextExercise = nextItem.exercise {
            return nextExercise
          } else if let nextSuperset = nextItem.superset, !nextSuperset.exercises.isEmpty {
            return nextSuperset.exercises[0]
          }
        }
        return nil
      } else if let superset = item.superset {
        if currentExerciseIndex + 1 < superset.exercises.count {
          // Next exercise in superset
          return superset.exercises[currentExerciseIndex + 1]
        } else if currentItemIndex + 1 < workout.orderedItems.count {
          // Next item
          let nextItem = workout.orderedItems[currentItemIndex + 1]
          if let nextExercise = nextItem.exercise {
            return nextExercise
          } else if let nextSuperset = nextItem.superset, !nextSuperset.exercises.isEmpty {
            return nextSuperset.exercises[0]
          }
        }
      }
    }
    return nil
  }

  private var currentSet: SetEntry? {
    guard let exercise = currentExercise, currentSetIndex < exercise.sets.count else { return nil }
    return exercise.sets[currentSetIndex]
  }

  private var nextSet: SetEntry? {
    if let exercise = currentExercise {
      if currentSetIndex + 1 < exercise.sets.count {
        return exercise.sets[currentSetIndex + 1]
      }
    }

    if let nextExercise = nextExercise, !nextExercise.sets.isEmpty {
      return nextExercise.sets[0]
    }

    return nil
  }

  private func startRestTimer() {
    var restTime = 0
    if let item = currentItem, let superset = item.superset {
      // For supersets, only start timer when it's the last exercise in the superset
      if currentExerciseIndex == superset.exercises.count - 1 {
        restTime = superset.restTime
      }
    } else if let exercise = currentExercise {
      restTime = exercise.restTime
    }

    if restTime > 0 {
      isResting = true

      // Generate a new timer ID for this rest period
      currentTimerId = UUID().uuidString

      // Schedule a notification for when rest is finished
      scheduleRestFinishedNotification(timeInterval: TimeInterval(restTime))
    } else {
      // Move to the next exercise/set directly if no rest time
      moveToNextExerciseOrSet()
    }
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

  // Function to schedule a notification for when rest time is finished
  private func scheduleRestFinishedNotification(timeInterval: TimeInterval) {
    // Create notification content
    let content = UNMutableNotificationContent()

    if let nextDefinition = nextSet?.exercise?.definition {
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

  private func moveToNextExerciseOrSet() {
    if let item = currentItem {
      if item.exercise != nil {
        if currentSetIndex + 1 < currentExercise?.sets.count ?? 0 {
          // Move to next set within the same exercise
          currentSetIndex += 1
        } else {
          // Move to next item
          currentItemIndex += 1
          currentExerciseIndex = 0
          currentSetIndex = 0
        }
      } else if let superset = item.superset {
        if currentExerciseIndex + 1 < superset.exercises.count {
          // Move to next exercise in superset
          currentExerciseIndex += 1
          currentSetIndex = 0
        } else if currentSetIndex + 1 < currentExercise?.sets.count ?? 0 {
          // Move to next set, restart with first exercise in superset
          currentSetIndex += 1
          currentExerciseIndex = 0
        } else {
          // Move to next item
          currentItemIndex += 1
          currentExerciseIndex = 0
          currentSetIndex = 0
        }
      }
    }
  }

  private func handleDoneSet() {
    if isResting {
      isResting = false
      moveToNextExerciseOrSet()
    } else {
      if let item = currentItem, let superset = item.superset {
        if currentExerciseIndex < superset.exercises.count - 1 {
          // In a superset but not the last exercise, just move to next exercise
          currentExerciseIndex += 1
        } else {
          // Last exercise in superset, start rest timer
          startRestTimer()
        }
      } else {
        // Regular exercise, start rest timer
        startRestTimer()
      }
    }
  }

  // Helper method to get the rest time for the current exercise or superset
  private func getRestTime() -> Int {
    if let item = currentItem, let superset = item.superset {
      // For supersets, only start timer when it's the last exercise in the superset
      if currentExerciseIndex == superset.exercises.count - 1 {
        return superset.restTime
      }
    } else if let exercise = currentExercise {
      return exercise.restTime
    }
    return 0
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
      .frame(height: 90, alignment: .top)
      .frame(maxWidth: .infinity)

      if let exercise = currentExercise, let exerciseDefinition = exercise.definition, let set = currentSet {
        // Current exercise and set
        VStack(spacing: 20) {
          Text(exerciseDefinition.name)
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)

          HStack(spacing: 35) {
            VStack {
              Text("SET")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(currentSetIndex + 1)/\(exercise.sets.count)")
                .font(.title2)
                .fontWeight(.semibold)
            }

            VStack {
              Text("REPS")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(set.reps)")
                .font(.title2)
                .fontWeight(.semibold)
            }

            VStack {
              Text("WEIGHT")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(set.weight, specifier: "%.1f") kg")
                .font(.title2)
                .fontWeight(.semibold)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(35)
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(15)
          .padding(.horizontal)
        }
      } else {
        Text("Workout Complete!")
          .font(.largeTitle)
          .fontWeight(.bold)
      }

      Spacer()

      // Middle action button or rest timer
      VStack {
        if isResting {
          CountdownTimer(
            time: getRestTime(),
            id: currentTimerId,
            onComplete: {
              isResting = false
              moveToNextExerciseOrSet()
            }
          )

          Button("Skip Rest") {
            handleDoneSet()
          }
          .padding(.top, 20)
        } else if currentExercise != nil {
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
        } else {
          Button {
            dismiss()
          } label: {
            Text("Finish Workout")
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

      // Next exercise information
      if let nextExercise = nextExercise, let nextDefinition = nextExercise.definition, let nextSet = nextSet {
        VStack(spacing: 10) {
          Text("NEXT")
            .font(.caption)
            .foregroundColor(.secondary)

          Text(nextDefinition.name)
            .font(.headline)

          HStack(spacing: 30) {
            VStack {
              Text("REPS")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(nextSet.reps)")
                .font(.title3)
            }

            VStack {
              Text("WEIGHT")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(nextSet.weight, specifier: "%.1f") kg")
                .font(.title3)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
      }
    }
    .onAppear {
      requestNotificationPermissions()
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
