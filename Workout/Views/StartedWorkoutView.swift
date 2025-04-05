//
//  WorkoutListView.swift
//  Workout
//
//  Created by Eliott on 2025-04-05.
//

import Combine
import SwiftData
import SwiftUI

struct StartedWorkoutView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.userAccentColor) private var userAccentColor
  @Bindable var workout: Workout

  @State private var currentItemIndex = 0
  @State private var currentExerciseIndex = 0
  @State private var currentSetIndex = 0
  @State private var isResting = false
  @State private var remainingRestTime = 0
  @State private var timer: Timer.TimerPublisher?
  @State private var timerCancellable: Cancellable?
  // Keep track of all active timers
  @State private var activeTimers: [Timer] = []

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
      remainingRestTime = restTime

      // Cancel any previous timers
      timerCancellable?.cancel()

      // Invalidate all active timers
      activeTimers.forEach { $0.invalidate() }
      activeTimers.removeAll()

      // Create a new timer
      let scheduledTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
        if remainingRestTime > 0 {
          remainingRestTime -= 1
        } else {
          timer.invalidate()
          activeTimers.removeAll { $0 === timer }
          isResting = false

          // Move to the next exercise/set when timer ends
          moveToNextExerciseOrSet()
        }
      }

      // Add the timer to active timers
      activeTimers.append(scheduledTimer)

      // This is no longer needed since we're tracking the timers directly
      timer = nil
      timerCancellable = nil
    } else {
      // Move to the next exercise/set directly if no rest time
      moveToNextExerciseOrSet()
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
      // Cancel current rest timer
      timerCancellable?.cancel()

      // Invalidate all active timers
      activeTimers.forEach { $0.invalidate() }
      activeTimers.removeAll()

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
      .frame(width: .infinity, height: 90, alignment: .top)

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
          VStack {
            Text("REST")
              .font(.headline)
              .foregroundColor(.secondary)

            Text("\(remainingRestTime)")
              .font(.system(size: 70, weight: .bold, design: .rounded))
              .foregroundColor(.primary)
              .monospacedDigit()

            Text("seconds")
              .font(.headline)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(35)
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(15)
          .padding(.horizontal)

          Button("Skip Rest") {
            handleDoneSet()
          }
          .padding()
          .font(.headline)
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
              .background(Color(hue: 0.321, saturation: 0.978, brightness: 0.752))
              .foregroundStyle(.black)
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
    .sensoryFeedback(.decrease, trigger: remainingRestTime, condition: { oldValue, newValue in
      newValue <= 3
    })
    .sensoryFeedback(.error, trigger: remainingRestTime, condition: { oldValue, newValue in
      oldValue == 1 && newValue == 0
    })
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
      // Check if timer should be reset when app comes back to foreground
      if isResting {
        // Re-sync the timer if needed
      }
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
