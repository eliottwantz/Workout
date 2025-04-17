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

  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedRectangle(cornerRadius: radius))
  }
}

private struct StartedWorkoutBottomSheetViewModifier: ViewModifier {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.keyboardIsShown) private var keyboardIsShown
  @Environment(\.mainWindowSafeAreaInsets) var safeAreaInsets
  @Environment(\.colorScheme) private var colorScheme

  private let collapsedHeight: CGFloat = 120
  
  func body(content: Content) -> some View {
    ZStack {
      Rectangle()
          .fill(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
        .ignoresSafeArea()
      content
        .padding(.bottom, viewModel.workout != nil && !keyboardIsShown ? collapsedHeight-safeAreaInsets.bottom+10 : 0)

      if let workout = viewModel.workout {
        StartedWorkoutBottomSheetView(workout: workout, collapsedHeight: collapsedHeight)
      }

    }
  }

}

private struct StartedWorkoutBottomSheetView: View {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.userAccentColor) private var userAccentColor
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.mainWindowSize) var windowSize
  @Environment(\.mainWindowSafeAreaInsets) var safeAreaInsets

  @Namespace private var ns

  var workout: Workout
  let collapsedHeight: CGFloat

  @State private var baseOffsetY: CGFloat = 0
  @State private var dragOffsetY: CGFloat = 0
  @State private var endOffsetY: CGFloat = 0

  @State private var showStopAlert: Bool = false

  private var screenHeight: CGFloat {
    windowSize.height + safeAreaInsets.top + safeAreaInsets.bottom
  }

  private var cappedDragOffsetY: CGFloat {
    endOffsetY == 0
      ? min(dragOffsetY, 0)
      : max(dragOffsetY, 0)
  }

  private var isCollapsed: Bool {
    endOffsetY == 0
  }

  private var isDarkTheme: Bool {
    colorScheme == .dark
  }

  init(workout: Workout, collapsedHeight: CGFloat) {
    self.workout = workout
    self.collapsedHeight = collapsedHeight
  }

  var body: some View {

    ZStack {

      Color(.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .offset(y: baseOffsetY)
        .offset(y: cappedDragOffsetY)
        .offset(y: endOffsetY)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        // MARK: - Header
        HStack {
          if !isCollapsed {
            Button {
              showStopAlert = true
            } label: {
              Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(isCollapsed ? .clear : .gray)
                .padding()
            }
          }

          Spacer()
          Capsule()
            .frame(width: 40, height: 5)
            .foregroundStyle(.gray)
          Spacer()

          // For symmetry
          if !isCollapsed {
            Image(systemName: "xmark")
              .font(.title2)
              .foregroundColor(.clear)
              .padding()
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, isCollapsed ? 6 : safeAreaInsets.top)
        .padding(.bottom, isCollapsed ? 2 : 10)

        // MARK: - Workout View
        if isCollapsed {
          CollapsedWorkoutView(workout: workout, ns: ns, stopAction: finishWorkout)
            .padding(.bottom, safeAreaInsets.bottom)
            .frame(maxHeight: collapsedHeight + abs(cappedDragOffsetY))
        } else {
          StartedWorkoutView(workout: workout, ns: ns, stopAction: finishWorkout)
            .padding(.bottom, safeAreaInsets.bottom)
        }
      }
      .frame(maxWidth: .infinity)
      .background(userAccentColor.opacity(isDarkTheme ? 0.35 : 0.2))
      .clipShape(RoundedRectangle(cornerRadius: 30))
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .offset(y: baseOffsetY)
      .offset(y: cappedDragOffsetY)
      .offset(y: endOffsetY)
      .ignoresSafeArea()
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            withAnimation(.linear(duration: 0.2)) {
              dragOffsetY = value.translation.height
            }

            withAnimation(.spring) {
              if dragOffsetY <= -150 {
                endOffsetY = -baseOffsetY
                dragOffsetY = 0
              } else if endOffsetY != 0 && dragOffsetY > 150 {
                endOffsetY = 0
                dragOffsetY = 0
              }
            }
          }
          .onEnded { value in
            let predictedY = value.predictedEndTranslation.height

            withAnimation(.spring) {
              if dragOffsetY <= -80 || (dragOffsetY <= -50 && predictedY + dragOffsetY <= -200) {
                endOffsetY = -baseOffsetY
              } else if endOffsetY != 0 && (dragOffsetY > 80 || (dragOffsetY > 50 && dragOffsetY + predictedY > 200)) {
                endOffsetY = 0
              }
              dragOffsetY = 0
            }
          }
      )
    }
    .onAppear {
      print("windowSize \(windowSize)")
      print("screenSize: \(screenHeight)")
      baseOffsetY = screenHeight - collapsedHeight
      print("safe area bottom: \(safeAreaInsets.bottom)")

      withAnimation(.spring) {
        endOffsetY = -baseOffsetY
        print("baseOffsetY \(baseOffsetY)")
      }
    }
    .navigationBarBackButtonHidden(!isCollapsed)
    .alert("Stop Workout", isPresented: $showStopAlert) {
      Button("Stop", role: .none) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
          viewModel.stop()
        }
        withAnimation(.snappy(duration: 0.5)) {
          endOffsetY = 0 + collapsedHeight
          print("baseOffsetY \(baseOffsetY)")
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will stop the workout. Are you sure you want to stop?")
    }

  }


  private func finishWorkout() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
      viewModel.stop()
    }
    withAnimation(.snappy(duration: 0.5)) {
      endOffsetY = 0 + collapsedHeight
      print("baseOffsetY \(baseOffsetY)")
    }
  }
}

private struct CollapsedWorkoutView: View {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.userAccentColor) private var userAccentColor

  var workout: Workout
  let ns: Namespace.ID
  let stopAction: () -> Void

  var body: some View {
    HStack(spacing: 16) {
      if viewModel.isWorkoutComplete {
        CollapsedCompletionView(
          stopAction: stopAction
        )
      } else if let currentSet = viewModel.currentWorkoutSet, let exerciseDefinition = currentSet.exerciseDefinition {
        // Left side: Show next set info if resting, otherwise current set info
        if viewModel.isResting, let nextSet = viewModel.nextWorkoutSet, let nextDefinition = nextSet.exerciseDefinition
        {
          // When resting, show the next set information on the left
          CollapsedExerciseInfoView(
            exerciseDefinition: nextDefinition,
            set: nextSet.set,
            setIndex: nextSet.setIndex,
            totalSets: nextSet.exercise.orderedSets.count,
            isSuperset: nextSet.isSuperset,
            isPrefixedWithNext: true,
            ns: ns
          )
        } else {
          // When not resting, show current set info
          CollapsedExerciseInfoView(
            exerciseDefinition: exerciseDefinition,
            set: currentSet.set,
            setIndex: currentSet.setIndex,
            totalSets: currentSet.exercise.orderedSets.count,
            isSuperset: currentSet.isSuperset,
            ns: ns
          )
        }

        Spacer()

        // Right side: Action button or rest timer
        if viewModel.isResting {
          // Show compact timer when resting
          CollapsedTimerView(
            time: currentSet.restTime,
            timerId: viewModel.currentTimerId,
            onComplete: viewModel.timerDidComplete
          )
          .matchedGeometryEffect(id: "timer", in: ns)
        } else {
          // Show Done Set button when not resting
          CollapsedActionButtonView(
            title: "Done Set",
            action: viewModel.handleDoneSet
          )
          .matchedGeometryEffect(id: "done_set", in: ns)
        }
      }
    }
    .padding(.horizontal, 4)
  }
}

/// A reusable view that displays exercise information in the collapsed workout view
private struct CollapsedExerciseInfoView: View {
  @Environment(\.userAccentColor) private var userAccentColor
  @AppStorage(DisplayWeightInLbsKey) private var displayWeightInLbs: Bool = true

  let exerciseDefinition: ExerciseDefinition
  let set: SetEntry
  let setIndex: Int
  let totalSets: Int
  let isSuperset: Bool
  let isPrefixedWithNext: Bool
  let ns: Namespace.ID

  init(
    exerciseDefinition: ExerciseDefinition,
    set: SetEntry,
    setIndex: Int,
    totalSets: Int,
    isSuperset: Bool,
    isPrefixedWithNext: Bool = false,
    ns: Namespace.ID
  ) {
    self.exerciseDefinition = exerciseDefinition
    self.set = set
    self.setIndex = setIndex
    self.totalSets = totalSets
    self.isSuperset = isSuperset
    self.isPrefixedWithNext = isPrefixedWithNext
    self.ns = ns
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
            .font(.title)
            .fontWeight(.bold)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .matchedGeometryEffect(id: "exercise", in: ns)
        }
      }

      CollapsedSetDetailsView(
        setIndex: setIndex,
        totalSets: totalSets,
        reps: set.reps,
        weight: set.weight,
        displayWeightInLbs: displayWeightInLbs,
        ns: ns
      )
    }
    .padding(.leading, 16)
  }
}

/// A reusable view that displays set details information (set number, reps, weight)
private struct CollapsedSetDetailsView: View {
  let setIndex: Int
  let totalSets: Int
  let reps: Int
  let weight: Double
  let displayWeightInLbs: Bool
  let ns: Namespace.ID

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
    .padding(.trailing, 16)
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
    .padding(.trailing, 16)
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
