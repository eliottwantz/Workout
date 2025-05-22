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

  @State private var dragOffset: CGFloat = 0
  @State private var isDragging = false

  let stopAction: () -> Void

  var body: some View {
    GeometryReader { geo in
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
        } else if let currentSet = startedWorkoutViewModel.currentWorkoutSet {
          ZStack {
            // ➋ Current card
            SetCardView(
              currentSet: currentSet,
              currentSetIndex: startedWorkoutViewModel.currentSetIndex,
              nextSet: startedWorkoutViewModel.nextWorkoutSet,
              isResting: startedWorkoutViewModel.isResting,
              displayWeightInLbs: displayWeightInLbs,
              userAccentColor: userAccentColor,
            ) {
              startedWorkoutViewModel.handleDoneSet()
            }
            .offset(x: dragOffset)

            // ➌ Next or Previous card while dragging
            if isDragging {

              let width = geo.size.width
              // dragging left => show NEXT
              if dragOffset < 0, let next = startedWorkoutViewModel.nextWorkoutSet {
                SetCardView(
                  currentSet: next,
                  currentSetIndex: startedWorkoutViewModel.currentSetIndex,
                  nextSet: startedWorkoutViewModel.nextOfNextWorkoutSet,
                  isResting: false,
                  displayWeightInLbs: displayWeightInLbs,
                  userAccentColor: userAccentColor,
                ) {
                  startedWorkoutViewModel.navigateToNextSet()
                }
                .offset(x: width + dragOffset)
              }
              // dragging right => show PREVIOUS
              else if dragOffset > 0, let prev = startedWorkoutViewModel.previousWorkoutSet {
                SetCardView(
                  currentSet: prev,
                  currentSetIndex: startedWorkoutViewModel.currentSetIndex,
                  nextSet: currentSet,
                  isResting: false,
                  displayWeightInLbs: displayWeightInLbs,
                  userAccentColor: userAccentColor,
                ) {
                  startedWorkoutViewModel.navigateToPreviousSet()
                }
                .offset(x: -width + dragOffset)
              }

            }
          }
          .contentShape(Rectangle())
          .gesture(
            DragGesture()
              .onChanged { value in
                guard !startedWorkoutViewModel.isWorkoutComplete else { return }
                let toRight = value.translation.width > 0
                if toRight && startedWorkoutViewModel.currentSetIndex == 0 { return }
                if !toRight && startedWorkoutViewModel.currentSetIndex == startedWorkoutViewModel.workoutSets.count - 1
                {
                  return
                }
                dragOffset = value.translation.width
                isDragging = true
              }
              .onEnded { value in
                let toRight = value.translation.width > 0
                if toRight && startedWorkoutViewModel.currentSetIndex == 0 { return }
                if !toRight && startedWorkoutViewModel.currentSetIndex == startedWorkoutViewModel.workoutSets.count - 1
                {
                  return
                }

                let width = geo.size.width
                let threshold = width * 0.5
                // If passed half-screen, complete transition
                if abs(value.translation.width) > threshold || abs(value.predictedEndTranslation.width) > threshold {
                  withAnimation(.spring(duration: 0.3)) {
                    dragOffset = toRight ? width : -width
                  }
                  // After the animation, update the model and reset
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if toRight {
                      startedWorkoutViewModel.navigateToPreviousSet()
                    } else {
                      startedWorkoutViewModel.navigateToNextSet()
                    }
                    dragOffset = 0
                    isDragging = false
                  }
                }
                // Otherwise cancel
                else {
                  withAnimation(.spring(duration: 0.3)) {
                    dragOffset = 0
                  }
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isDragging = false
                  }
                }
              }
          )
        }
      }
    }
    .onAppear {
      print("Showing StartedWorkoutView")
    }
  }
}

struct SetCardView: View {
  @Environment(\.startedWorkoutViewModel) private var startedWorkoutViewModel
  let currentSet: WorkoutSet
  let currentSetIndex: Int
  let nextSet: WorkoutSet?
  let isResting: Bool
  let displayWeightInLbs: Bool
  let userAccentColor: Color
  let onDone: () -> Void

  var body: some View {
    VStack {
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

        Text("\(currentSetIndex + 1) of \(startedWorkoutViewModel.workoutSets.count) sets")
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
            Text(currentSet.exerciseName)
              .font(.title)
              .fontWeight(.bold)
              .lineLimit(1)
              .multilineTextAlignment(.center)
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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // .background(Color(UIColor.secondarySystemBackground))
    //    .background(Color.red.opacity(0.8))
    .cornerRadius(15)
    //    .padding(.horizontal)
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
