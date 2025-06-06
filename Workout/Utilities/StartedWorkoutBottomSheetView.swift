//
//  StartedWorkoutBottomSheetView.swift
//  Workout
//
//  Created by Copilot on 2025-04-10.
//

import SwiftData
import SwiftUI

extension View {
  /// Adds a bottom sheet to the view.
  func startedWorkoutBottomSheet() -> some View {
    modifier(StartedWorkoutBottomSheetViewModifier())
  }
}

private struct StartedWorkoutBottomSheetViewModifier: ViewModifier {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.keyboardIsShown) private var keyboardIsShown
  @Environment(\.mainWindowSafeAreaInsets) var safeAreaInsets
  @Environment(\.colorScheme) private var colorScheme

  @State private var dragOffset: CGFloat = 0
  @State private var isDragging: Bool = false
  @State private var dragStartLocation: CGPoint = .zero
  @State private var isVerticalDrag: Bool? = nil

  private let collapsedHeight: CGFloat = 120
  private let screenHeight: CGFloat = UIApplication.height
  private let dragThreshold: CGFloat = 10

  func body(content: Content) -> some View {
    @Bindable var viewModel = viewModel
    ZStack {
      content

      if let workout = viewModel.workout, viewModel.isCollapsed {
        ZStack(alignment: .bottom) {
          CollapsedWorkoutView(
            workout: workout,
            stopAction: {
              viewModel.stop()
            }
          )
          .padding(.horizontal, 8)
          .padding(.bottom, 55)  // Tab bar height
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      }
    }
    .fullScreenCover(isPresented: $viewModel.isPresented) {
      if let workout = viewModel.workout {
        NavigationView {
          StartedWorkoutView(
            workout: workout,
            stopAction: {
              viewModel.stop()
            }
          )
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button("Stop") {
                viewModel.stop()
              }
            }

            ToolbarItem(placement: .topBarTrailing) {
              Button("Collapse", systemImage: "chevron.down") {
                viewModel.collapse()
              }
            }
          }
          //        .offset(y: dragOffset)
          //        .background {
          //          Color(.yellow)
          //            .ignoresSafeArea()
          //            .offset(y: dragOffset)
          //        }
          //        .gesture(
          //          DragGesture(coordinateSpace: .global)
          //            .onChanged { value in
          //              handleDragChanged(value: value)
          //            }
          //            .onEnded { value in
          //              handleDragEnded(value: value)
          //            }
          //        )
          //        .animation(.interactiveSpring, value: dragOffset)
          //        .presentationBackground(.clear)
        }
      }
    }
  }

  private func handleDragChanged(value: DragGesture.Value) {
    guard value.translation.height > 0 else { return }

    let translation = value.translation.height
    dragOffset = translation
  }

  private func handleDragEnded(value: DragGesture.Value) {
    guard value.translation.height > 0 else {
      dragOffset = 0
      return
    }

    let velocity = value.predictedEndLocation.y - value.location.y
    if velocity > 300 || abs(value.translation.height) > screenHeight * 0.35 {
      viewModel.collapse()
    }

    dragOffset = 0
  }

}

private struct CollapsedWorkoutView: View {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.userAccentColor) private var userAccentColor

  var workout: Workout
  let stopAction: () -> Void

  var body: some View {
    HStack {
      if viewModel.isWorkoutComplete {
        CollapsedCompletionView(stopAction: stopAction)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      } else if let currentSet = viewModel.currentWorkoutSet, let exerciseDefinition = currentSet.exerciseDefinition {
        HStack(spacing: 16) {
          CollapsedExerciseInfoView(
            exerciseDefinition: exerciseDefinition,
            set: currentSet.set,
            setIndex: currentSet.setIndex,
            totalSets: currentSet.exercise.orderedSets.count,
            isSuperset: currentSet.isSuperset,
          )
          Spacer()
          if viewModel.isResting {
            CollapsedTimerView(
              time: currentSet.restTime,
              timerId: viewModel.currentTimerId,
              onComplete: viewModel.timerDidComplete
            )
          } else {
            CollapsedActionButtonView(
              title: "Done",
              action: viewModel.handleDoneSet
            )
          }
        }
      }
    }
    .frame(maxHeight: 60)
    .padding(.vertical, 4)
    .padding(.horizontal, 12)
    .background(userAccentColor.background)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    .onTapGesture {
      viewModel.expand()
    }
  }
}

/// A reusable view that displays exercise information in the collapsed workout view
private struct CollapsedExerciseInfoView: View {
  @Environment(\.userAccentColor) private var userAccentColor
  @AppStorage(DisplayWeightInLbsKey) private var displayWeightInLbs: Bool = false

  let exerciseDefinition: ExerciseDefinition
  let set: SetEntry
  let setIndex: Int
  let totalSets: Int
  let isSuperset: Bool
  let isPrefixedWithNext: Bool

  init(
    exerciseDefinition: ExerciseDefinition,
    set: SetEntry,
    setIndex: Int,
    totalSets: Int,
    isSuperset: Bool,
    isPrefixedWithNext: Bool = false,
  ) {
    self.exerciseDefinition = exerciseDefinition
    self.set = set
    self.setIndex = setIndex
    self.totalSets = totalSets
    self.isSuperset = isSuperset
    self.isPrefixedWithNext = isPrefixedWithNext
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(spacing: 4) {
        if isSuperset {
          Text("SUPERSET")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(userAccentColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(userAccentColor.opacity(0.2))
            .cornerRadius(4)
        }

        HStack {
          if isPrefixedWithNext {
            Text("NEXT: ")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Text(exerciseDefinition.name)
            .font(.title2)
            .fontWeight(.bold)
            .lineLimit(1)
            .multilineTextAlignment(.center)
        }
      }

      CollapsedSetDetailsView(
        setIndex: setIndex,
        totalSets: totalSets,
        reps: set.reps,
        weight: set.weight,
        displayWeightInLbs: displayWeightInLbs,
      )
    }
  }
}

/// A reusable view that displays set details information (set number, reps, weight)
private struct CollapsedSetDetailsView: View {
  let setIndex: Int
  let totalSets: Int
  let reps: Int
  let weight: Double
  let displayWeightInLbs: Bool

  var body: some View {
    HStack(spacing: 8) {
      Text("Set \(setIndex + 1)/\(totalSets)")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("•")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("\(reps) reps")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("•")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("\(weight.formattedWeight(inLbs: displayWeightInLbs))")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
  }
}

/// A reusable view for the timer in collapsed state
private struct CollapsedTimerView: View {
  let time: Int
  let timerId: String
  let onComplete: () -> Void

  var body: some View {
    CountdownTimer(
      time: time,
      id: timerId,
      onComplete: onComplete,
      compact: true
    )
  }
}

/// A reusable action button for the collapsed workout view
private struct CollapsedActionButtonView: View {
  @Environment(\.userAccentColor) private var userAccentColor

  let title: String
  let action: () -> Void

  var body: some View {
    Button {
      action()
    } label: {
      Text(title)
        .font(.subheadline)
        .fontWeight(.semibold)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(userAccentColor)
        .foregroundStyle(userAccentColor.contrastColor)
        .cornerRadius(10)
    }
  }
}

/// A view displayed when the workout is complete
private struct CollapsedCompletionView: View {
  @Environment(\.userAccentColor) private var userAccentColor

  let stopAction: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("Workout Completed! 🏆")
          .font(.headline)
          .fontWeight(.semibold)
      }
      .padding(.leading, 16)

      Spacer()

      CollapsedActionButtonView(
        title: "Finish",
        action: stopAction
      )
    }
  }
}

#Preview {
  @Previewable @State var startedWorkoutViewModel = StartedWorkoutViewModel()
  let workouts = try? AppContainer.preview.modelContainer.mainContext.fetch(FetchDescriptor<Workout>())
  if let workouts = workouts, let workout = workouts.first {

    VStack {
      WorkoutDetailView(workout: workout)
        .startedWorkoutBottomSheet()
    }
    .withGeometryEnvironment()
    .environment(\.startedWorkoutViewModel, startedWorkoutViewModel)
    .modelContainer(AppContainer.preview.modelContainer)
  } else {
    Text("Failed no workout")
  }
}
