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
  @Environment(\.router) private var router
  @Environment(\.userAccentColor) private var userAccentColor
  @Namespace private var namespace

  func body(content: Content) -> some View {
    @Bindable var viewModel = viewModel
    ZStack {
      content
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
          Group {
            if let workout = viewModel.workout {
              CollapsedWorkoutView(
                workout: workout,
                stopAction: {
                  viewModel.stop()
                }
              )
              .padding(.horizontal, 16)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background {
                ZStack {
                  Color(.systemBackground)
                  userAccentColor.background
                }
              }

            } else if case .workoutDetail(let workout) = router.currentRoute,
              !workout.orderedItems.isEmpty
                && !workout.orderedItems.flatMap({ item in
                  if let exercise = item.exercise {
                    return exercise.orderedSets
                  }
                  if let superset = item.superset {
                    return superset.orderedExercises.flatMap({ $0.orderedSets })
                  }
                  return []
                }).isEmpty && viewModel.workout == nil
            {
              HStack {
                Button {
                  viewModel.start(workout: workout)
                } label: {
                  Text("Start workout")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(userAccentColor.contrastColor)
                }
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(userAccentColor)
            } else {
              EmptyView()
            }
          }
          .matchedTransitionSource(id: "workout-view", in: namespace)
        }
        .fullScreenCover(isPresented: $viewModel.isPresented) {
          if let workout = viewModel.workout {
            ExpandedWorkoutView(workout: workout)
              .navigationTransition(.zoom(sourceID: "workout-view", in: namespace))
          }
        }
    }
  }

}

// MARK: - ExpandedWorkoutView
private struct ExpandedWorkoutView: View {
  @Environment(\.userAccentColor) private var userAccentColor
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.colorScheme) private var colorScheme

  let workout: Workout

  var body: some View {

    NavigationStack {
      VStack(spacing: 0) {
        StartedWorkoutView(
          workout: workout,
          stopAction: stop,
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background {
        ZStack {
          Color(.systemBackground)
          userAccentColor.background
        }
        .ignoresSafeArea()
      }
      // MARK: - ExpandedWorkoutView toolbar
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Collapse", systemImage: "chevron.down") {
            viewModel.isPresented = false
          }
        }

        ToolbarItem(placement: .title) {
          Capsule()
            .fill(Color(.systemBackground))
            .opacity(0.2275)
            .frame(width: 35, height: 5)

        }

        ToolbarItem(placement: .secondaryAction) {
          Button("Stop", systemImage: "stop.circle.fill") {
            stop()
          }
        }
      }
      .toolbarTitleDisplayMode(.inline)

    }

  }

  private func stop() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      viewModel.stop()
    }
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
      } else if let currentSet = viewModel.currentWorkoutSet,
        let exerciseDefinition = currentSet.exerciseDefinition
      {
        HStack {
          CollapsedExerciseInfoView(
            exerciseDefinition: exerciseDefinition,
            set: currentSet.set,
            setIndex: currentSet.setIndex,
            totalSets: currentSet.exercise.orderedSets.count,
            isSuperset: currentSet.isSuperset,
          )
          Spacer()
          if let countdownTimerModel = viewModel.countdownTimerModel {
            CollapsedTimerView(
              timerModel: countdownTimerModel,
              time: currentSet.restTime
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
    .contentShape(.rect)
    .onTapGesture {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
        viewModel.expand()
      }
    }
    .gesture(
      DragGesture(minimumDistance: 1)
        .onChanged { _ in
          withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            viewModel.expand()
          }
        }
    )
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
    VStack(alignment: .leading, spacing: 1) {
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
            .font(.title3)
            .fontWeight(.bold)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
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
  let timerModel: CountdownTimerModel
  let time: Int

  var body: some View {
    CountdownTimer(
      timerModel: timerModel,
      time: time,
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
  let workouts = try? AppContainer.preview.modelContainer.mainContext.fetch(
    FetchDescriptor<Workout>())
  if let workouts = workouts, let workout = workouts.first {

    //    TabView {
    //      Tab("Workouts", systemImage: "dumbbell") {
    VStack {
      WorkoutDetailView(workout: workout)
        .startedWorkoutBottomSheet()
      //        }
      //      }
    }
    .withGeometryEnvironment()
    .environment(\.startedWorkoutViewModel, startedWorkoutViewModel)
    .modelContainer(AppContainer.preview.modelContainer)
  } else {
    Text("Failed no workout")
  }
}
