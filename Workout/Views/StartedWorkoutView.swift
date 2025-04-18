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
  @AppStorage(DisplayWeightInLbsKey) private var displayWeightInLbs: Bool = false
  @Environment(\.dismiss) private var dismiss
  @Environment(\.userAccentColor) private var userAccentColor
  @Environment(\.startedWorkoutViewModel) private var startedWorkoutViewModel
  @Bindable var workout: Workout
  @State private var showingWorkoutEditor = false

  var ns: Namespace.ID
  let stopAction: () -> Void

  var body: some View {
    VStack {

      // MARK: - Workout completed view
      if startedWorkoutViewModel.isWorkoutComplete {
        Text("Workout Completed!")
          .font(.largeTitle)
          .fontWeight(.bold)
        Spacer()
        Text("🏆🏆🏆")
          .font(.largeTitle)
          .fontWeight(.bold)
        Spacer()
        Button {
          stopAction()
        } label: {
          Text("Finish")
            .font(.headline)
            .frame(width: 200, height: 60)
            .background(userAccentColor)
            .foregroundStyle(userAccentColor.contrastColor)
            .cornerRadius(15)
        }
      } else if let currentSet = startedWorkoutViewModel.currentWorkoutSet,
        let exerciseDefinition = currentSet.exerciseDefinition
      {
        // MARK: - Workout in progress
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

          Text("\(startedWorkoutViewModel.currentSetIndex + 1) of \(startedWorkoutViewModel.workoutSets.count) sets")
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          Button {
            startedWorkoutViewModel.navigateToNextSet()
          } label: {
            Image(systemName: "chevron.right")
              .font(.title2)
              .padding(10)
              .foregroundColor(
                startedWorkoutViewModel.currentSetIndex < startedWorkoutViewModel.workoutSets.count - 1
                  ? .primary : .gray)
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
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .matchedGeometryEffect(id: "exercise", in: ns)
            }

            Spacer()

            Text("SET \(currentSet.setIndex + 1)/\(currentSet.exercise.orderedSets.count)")
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
                Text(displayWeightInLbs ? "(lbs)" : "(kg)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              Text("\(currentSet.set.weight.weightValue(inLbs: displayWeightInLbs), specifier: "%.1f")")
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
            .matchedGeometryEffect(id: "timer", in: ns)

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
            .matchedGeometryEffect(id: "done_set", in: ns)
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

              Text("SET \(nextSet.setIndex + 1)/\(nextSet.exercise.orderedSets.count)")
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
                  Text(displayWeightInLbs ? "(lbs)" : "(kg)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Text("\(nextSet.set.weight.weightValue(inLbs: displayWeightInLbs), specifier: "%.1f")")
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
      }
    }
    .onAppear {
      print("Showing StartedWorkoutView")
    }
  }
}

#Preview {
  @Previewable @Namespace var ns
  let container = AppContainer.preview.modelContainer
  let modelContext = container.mainContext

  let workoutFetchDescriptor = FetchDescriptor<Workout>()
  let workouts = try! modelContext.fetch(workoutFetchDescriptor)
  let sampleWorkout = workouts.first ?? Workout(date: Date())

  return StartedWorkoutView(workout: sampleWorkout, ns: ns, stopAction: {})
    .modelContainer(container)
}
