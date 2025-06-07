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
  let stopAction: () -> Void
  
  @State private var currentIndex: Int = 0

  var body: some View {
    VStack {
      // MARK: - Workout completed view
      if startedWorkoutViewModel.isWorkoutComplete {
        VStack {
          Text("Workout Completed!")
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
          Spacer()
          Text("🏆🏆🏆")
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
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
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        // Carousel TabView for workout sets
        HStack {
          if !startedWorkoutViewModel.workoutSets.isEmpty {
            TabView(selection: $currentIndex) {
              ForEach(0..<startedWorkoutViewModel.workoutSets.count, id: \.self) { index in
                if index < startedWorkoutViewModel.workoutSets.count {
                  SetCardView(
                    tabViewIndex: $currentIndex,
                    currentSet: startedWorkoutViewModel.workoutSets[index],
                    currentSetIndex: index,
                    nextSet: index < startedWorkoutViewModel.workoutSets.count - 1
                      ? startedWorkoutViewModel.workoutSets[index + 1] : nil,
                    isResting: startedWorkoutViewModel.isResting
                      && index == startedWorkoutViewModel.currentSetIndex,
                    displayWeightInLbs: displayWeightInLbs,
                    userAccentColor: userAccentColor
                  )
                  .animation(.easeInOut, value: currentIndex)
                }
              }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { previousValue, newValue in
              guard newValue != startedWorkoutViewModel.currentSetIndex else { return }
              if newValue > previousValue {
                startedWorkoutViewModel.navigateToNextSet()
              } else if newValue < previousValue {
                startedWorkoutViewModel.navigateToPreviousSet()
              }
            }
          } else {
            // Show empty state when no workout sets are available
            VStack {
              Text("No workout sets available")
                .font(.headline)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }
      }
    }
    .background(userAccentColor.background)
    .onAppear {
      currentIndex = startedWorkoutViewModel.currentSetIndex
    }
  }
}

struct SetCardView: View {
  @Environment(\.startedWorkoutViewModel) private var startedWorkoutViewModel
  @Binding var tabViewIndex: Int
  let currentSet: WorkoutSet
  let currentSetIndex: Int
  let nextSet: WorkoutSet?
  let isResting: Bool
  let displayWeightInLbs: Bool
  let userAccentColor: Color

  var body: some View {
    VStack {
      // MARK: - Workout in progress
      // Set navigation controls
      HStack {
        Button {
          withAnimation {
            tabViewIndex -= 1
          }
        } label: {
          Image(systemName: "chevron.left")
            .font(.title2)
            .padding(10)
            .foregroundColor(tabViewIndex > 0 ? .primary : .gray)
        }
        .disabled(tabViewIndex <= 0)

        Spacer()

        Text("\(currentSetIndex + 1) of \(startedWorkoutViewModel.workoutSets.count) sets")
          .font(.subheadline)
          .foregroundColor(.secondary)

        Spacer()

        Button {
          withAnimation {
            tabViewIndex += 1
          }
        } label: {
          Image(systemName: "chevron.right")
            .font(.title2)
            .padding(10)
            .foregroundColor(
              tabViewIndex < startedWorkoutViewModel.workoutSets.count - 1
                ? .primary : .gray)
        }
        .disabled(tabViewIndex >= startedWorkoutViewModel.workoutSets.count - 1)
      }

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
            Text(currentSet.exerciseName)
              .font(.title)
              .fontWeight(.bold)
              .lineLimit(1)
              .multilineTextAlignment(.center)
          }
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
          
          VStack {
            Text("SET")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(currentSet.setIndex + 1)/\(currentSet.exercise.orderedSets.count)")
              .font(.title2)
              .fontWeight(.semibold)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
//        .padding(.horizontal)
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
      if let nextSet = nextSet {
        VStack(spacing: 12) {
          HStack {
            Text("NEXT: \(nextSet.exerciseName)")
              .font(.headline)
              .foregroundColor(.secondary)
          }
//          .padding(.horizontal)

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
            
            VStack {
              Text("SET")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(nextSet.setIndex + 1)/\(nextSet.exercise.orderedSets.count)")
                .font(.title3)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(20)
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(15)
//          .padding(.horizontal)
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
    .padding(.horizontal, 8)
    .padding(.vertical, 10)
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer
  let modelContext = container.mainContext

  let workoutFetchDescriptor = FetchDescriptor<Workout>()
  let workouts = try! modelContext.fetch(workoutFetchDescriptor)
  let sampleWorkout = workouts.first ?? Workout(date: Date())

  return StartedWorkoutView(workout: sampleWorkout, stopAction: {})
    .modelContainer(container)
}
