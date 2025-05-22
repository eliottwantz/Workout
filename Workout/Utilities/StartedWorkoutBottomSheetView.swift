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
        .padding(
          .bottom, viewModel.workout != nil && !keyboardIsShown ? collapsedHeight - safeAreaInsets.bottom + 10 : 0)

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
  @State private var collapsedDragAmount: CGFloat = 0

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

  private var totalOffsetY: CGFloat {
    // chain base + drag + end into one single animatable offset
    baseOffsetY + cappedDragOffsetY + endOffsetY
  }

  init(workout: Workout, collapsedHeight: CGFloat) {
    self.workout = workout
    self.collapsedHeight = collapsedHeight
  }

  var body: some View {

    ZStack {

      Color(.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .offset(y: totalOffsetY)
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
        .padding(.bottom, isCollapsed ? 16 : 0)

        // MARK: - Workout View
        Group {
        if isCollapsed {
          CollapsedWorkoutView(workout: workout, stopAction: finishWorkout)
            .padding(.bottom, safeAreaInsets.bottom)
            .frame(maxHeight: collapsedHeight + abs(cappedDragOffsetY))
        } else {
          StartedWorkoutView(workout: workout, stopAction: finishWorkout)
            .padding(.bottom, safeAreaInsets.bottom)
        }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .background(userAccentColor.opacity(isDarkTheme ? 0.35 : 0.2))
      .clipShape(RoundedRectangle(cornerRadius: 20))
      .offset(y: totalOffsetY)
      .ignoresSafeArea()
      // Prevent drag gesture in the bottom safe area (home indicator area)
      .overlay(
        Rectangle()
          .frame(height: safeAreaInsets.bottom)
          .foregroundColor(.clear)
          .allowsHitTesting(false)
          .frame(maxHeight: .infinity, alignment: .bottom)
      )
      .contentShape(
        Rectangle()
          .inset(by: safeAreaInsets.bottom)
      )
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            // Only allow drag if not in the bottom safe area
            if value.startLocation.y < windowSize.height - safeAreaInsets.bottom {
              dragOffsetY = value.translation.height
            }
          }
          .onEnded { value in
            if value.startLocation.y < windowSize.height - safeAreaInsets.bottom {
              let predictedY = value.predictedEndTranslation.height

              withAnimation(.spring) {
                if dragOffsetY <= -80 || (dragOffsetY <= -50 && predictedY + dragOffsetY <= -200) {
                  endOffsetY = -baseOffsetY
                } else if !isCollapsed
                  && (dragOffsetY > screenHeight / 2 || (dragOffsetY > 50 && dragOffsetY + predictedY > screenHeight / 2))
                {
                  endOffsetY = 0
                }
                dragOffsetY = 0
              }
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
  let stopAction: () -> Void

  @State private var dragOffset: CGFloat = 0
  @State private var isDragging = false

  var body: some View {
    GeometryReader { geo in
      ZStack {
        if viewModel.isWorkoutComplete {
          CollapsedCompletionView(stopAction: stopAction)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else if let currentSet = viewModel.currentWorkoutSet, let exerciseDefinition = currentSet.exerciseDefinition {
          // Current card
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
                onComplete: viewModel.timerDidComplete,
                isActive: !isDragging
              )
            } else {
              CollapsedActionButtonView(
                title: "Done Set",
                action: viewModel.handleDoneSet
              )
            }
          }
          .padding(.horizontal, 4)
          .offset(x: dragOffset)

          // Next card (dragging left)
          if isDragging, dragOffset < 0, let next = viewModel.nextWorkoutSet, let nextDef = next.exerciseDefinition {
            HStack(spacing: 16) {
              CollapsedExerciseInfoView(
                exerciseDefinition: nextDef,
                set: next.set,
                setIndex: next.setIndex,
                totalSets: next.exercise.orderedSets.count,
                isSuperset: next.isSuperset,
              )
              Spacer()
              CollapsedActionButtonView(
                title: "Done Set",
                action: viewModel.handleDoneSet
              )
            }
            .padding(.horizontal, 4)
            .offset(x: geo.size.width + dragOffset)
          }

          // Previous card (dragging right)
          if isDragging, dragOffset > 0, let prev = viewModel.previousWorkoutSet, let prevDef = prev.exerciseDefinition
          {
            HStack(spacing: 16) {
              CollapsedExerciseInfoView(
                exerciseDefinition: prevDef,
                set: prev.set,
                setIndex: prev.setIndex,
                totalSets: prev.exercise.orderedSets.count,
                isSuperset: prev.isSuperset,
              )
              Spacer()
              CollapsedActionButtonView(
                title: "Done Set",
                action: viewModel.handleDoneSet
              )
            }
            .padding(.horizontal, 4)
            .offset(x: -geo.size.width + dragOffset)
          }
        }
      }
      .background(Color.clear)
      .contentShape(Rectangle())
      .highPriorityGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            guard !viewModel.isWorkoutComplete else { return }
            isDragging = true
            let toRight = value.translation.width > 0
            if toRight && viewModel.currentSetIndex == 0 { return }
            if !toRight && viewModel.currentSetIndex == viewModel.workoutSets.count - 1 { return }
            dragOffset = value.translation.width
          }
          .onEnded { value in
            let toRight = value.translation.width > 0
            if toRight && viewModel.currentSetIndex == 0 { return }
            if !toRight && viewModel.currentSetIndex == viewModel.workoutSets.count - 1 { return }

            let width = geo.size.width
            let threshold = width * 0.2
            if abs(value.translation.width) > threshold || abs(value.predictedEndTranslation.width) > threshold {
              withAnimation(.spring(duration: 0.3)) {
                dragOffset = toRight ? width : -width
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if toRight {
                  viewModel.navigateToPreviousSet()
                } else {
                  viewModel.navigateToNextSet()
                }
                dragOffset = 0
                isDragging = false
              }
            } else {
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
            .font(.title)
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
  let isActive: Bool

  var body: some View {
    CountdownTimer(
      time: time,
      id: timerId,
      onComplete: onComplete,
      compact: true,
      isActive: isActive
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
