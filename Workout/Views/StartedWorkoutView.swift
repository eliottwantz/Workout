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
  @Environment(\.startedWorkoutViewModel) private var startedWorkoutViewModel
  @Bindable var workout: Workout
  @State private var showingWorkoutEditor = false

  var body: some View {
    VStack {
      HStack {
        Button {
          withAnimation {
            startedWorkoutViewModel.stop()
          }
        } label: {
          Image(systemName: "xmark")
            .font(.title2)
            .foregroundColor(.primary)
            .padding()
        }

        Spacer()
      }
      .frame(maxWidth: .infinity)

      if let currentSet = startedWorkoutViewModel.currentWorkoutSet, let exerciseDefinition = currentSet.exerciseDefinition {
        // Set navigation controls
        HStack {
          Button {
            startedWorkoutViewModel.navigateToPreviousSet()
          } label: {
            Image(systemName: "chevron.left")
              .font(.title2)
              .padding(10)
              .foregroundColor(startedWorkoutViewModel.currentSetIndex > 0 ? .primary : .gray)
          }
          .disabled(startedWorkoutViewModel.currentSetIndex <= 0)

          Spacer()

          Text("\(startedWorkoutViewModel.currentSetIndex + 1) of \(startedWorkoutViewModel.workoutSets.count)")
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          Button {
            startedWorkoutViewModel.navigateToNextSet()
          } label: {
            Image(systemName: "chevron.right")
              .font(.title2)
              .padding(10)
              .foregroundColor(startedWorkoutViewModel.currentSetIndex < startedWorkoutViewModel.workoutSets.count - 1 ? .primary : .gray)
          }
          .disabled(startedWorkoutViewModel.currentSetIndex >= startedWorkoutViewModel.workoutSets.count - 1)
        }
        .padding(.horizontal)

        // Current exercise and set
        VStack(spacing: 12) {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              if currentSet.isSuperset {
                Text("SUPERSET")
                  .font(.callout)
                  .fontWeight(.semibold)
                  .foregroundColor(userAccentColor)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 3)
                  .background(userAccentColor.opacity(0.2))
                  .cornerRadius(4)
              }
              Text(exerciseDefinition.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            }

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
              HStack(alignment: .bottom, spacing: 6) {
                Text("WEIGHT")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text(startedWorkoutViewModel.displayWeightInLbs ? "(lbs)" : "(kg)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              Text("\(currentSet.set.weight.weightValue(inLbs: startedWorkoutViewModel.displayWeightInLbs), specifier: "%.1f")")
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
          if startedWorkoutViewModel.isResting {
            CountdownTimer(
              time: currentSet.restTime,
              id: startedWorkoutViewModel.currentTimerId,
              onComplete: {
                startedWorkoutViewModel.timerDidComplete()
              }
            )

            Button("Skip Rest") {
              startedWorkoutViewModel.skipRest()
            }
            .padding(.top, 20)
          } else {
            Button {
              startedWorkoutViewModel.handleDoneSet()
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
        if let nextSet = startedWorkoutViewModel.nextWorkoutSet, let nextDefinition = nextSet.exerciseDefinition {
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
                HStack(alignment: .bottom, spacing: 6) {
                  Text("WEIGHT")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Text(startedWorkoutViewModel.displayWeightInLbs ? "(lbs)" : "(kg)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Text("\(nextSet.set.weight.weightValue(inLbs: startedWorkoutViewModel.displayWeightInLbs), specifier: "%.1f")")
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
      } else if startedWorkoutViewModel.isWorkoutComplete {
        Text("Workout Completed!")
          .font(.largeTitle)
          .fontWeight(.bold)
        Spacer()
        Text("🏆🏆🏆")
          .font(.largeTitle)
          .fontWeight(.bold)
        Spacer()
        Button {
          startedWorkoutViewModel.stop()
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
      // No need to call these individually since they're handled in the view model
      // when the workout is started
    }
    .sheet(
      isPresented: $showingWorkoutEditor,
      onDismiss: {
        startedWorkoutViewModel.buildWorkoutSetsList()
      }
    ) {
      NavigationStack {
        WorkoutDetailEditorView(workout: workout)
      }
      .dismissKeyboardOnTap()
    }
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer
  let modelContext = container.mainContext

  let workoutFetchDescriptor = FetchDescriptor<Workout>()
  let workouts = try! modelContext.fetch(workoutFetchDescriptor)
  let sampleWorkout = workouts.first ?? Workout(date: Date())

  return StartedWorkoutView(workout: sampleWorkout)
    .modelContainer(container)
}
