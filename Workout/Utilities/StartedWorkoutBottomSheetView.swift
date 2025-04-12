//
//  StartedWorkoutBottomSheetView.swift
//  Workout
//
//  Created by Copilot on 2025-04-10.
//

import SwiftData
import SwiftUI

private struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

extension View {
  /// Adds a bottom sheet to the view.
  func startedWorkoutBottomSheet() -> some View {
    modifier(StartedWorkoutBottomSheetViewModifier())
  }

  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

private struct StartedWorkoutBottomSheetViewModifier: ViewModifier {
  @Environment(\.startedWorkoutViewModel) private var viewModel

  func body(content: Content) -> some View {

    content
      .padding(.bottom, viewModel.workout != nil ? 80 : 0)
      .overlay(
        Group {
          if let workout = viewModel.workout {
            StartedWorkoutBottomSheetView(workout: workout)
          }
        }
      )
  }
}

private struct StartedWorkoutBottomSheetView: View {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.userAccentColor) private var userAccentColor

  private var collapsedHeight: CGFloat = 120
  @State var offset: CGFloat = 0
  @State private var isExpanded: Bool = true

  @Bindable var workout: Workout

  init(workout: Workout) {
    self.workout = workout
  }

  var body: some View {
    @Bindable var viewModel = viewModel

    GeometryReader { geometry in

      let height = geometry.frame(in: .global).height
      let topOffset = -height + collapsedHeight

      Color(UIColor.systemBackground)
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .offset(y: height - collapsedHeight)
        .offset(y: offset)

      VStack {
        if isExpanded {
          HStack {
            Button {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.stop()
              }
              withAnimation(.snappy(duration: 0.3)) {
                offset = 0
              }
            } label: {
              Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
            }

            Spacer()
            Capsule()
              .frame(width: 40, height: 5)
              .foregroundStyle(.gray)
            Spacer()

            // For symmetry
            Image(systemName: "xmark")
              .font(.title2)
              .foregroundColor(.clear)
              .padding()
          }
          .frame(maxWidth: .infinity)
          .padding(.top, isExpanded ? 50 : 8)
          .background(Color(UIColor.systemBackground))
          .onTapGesture { isExpanded = false }
        }

        if isExpanded {
          StartedWorkoutView(workout: workout)
            .padding(.bottom, 47)
        } else {
          VStack {
            CollapsedWorkoutView(workout: workout)
              .frame(maxHeight: collapsedHeight)
          }
        }

      }
      .frame(maxHeight: .infinity, alignment: .top)
      .frame(maxWidth: .infinity)
      //        .background(userAccentColor.opacity(0.2))
      .background(isExpanded ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
      .cornerRadius(30, corners: [.topLeft, .topRight])
      .offset(y: height - collapsedHeight)
      .offset(y: offset)
      .onChange(of: isExpanded) { oldValue, newValue in
        withAnimation(.snappy(duration: 0.3)) {
          print("onChange isExpanded: \(newValue)")
          if newValue {
            offset = topOffset
          } else {
            offset = 0
          }
          print("onChange isExpanded offset: \(offset)")
        }
      }
      .onTapGesture {
        guard !isExpanded else { return }
        isExpanded = true
      }
      .gesture(
        DragGesture()
          .onChanged { value in
            guard isExpanded else { return }
            print("onChanged value: \(value.translation.height)")
            let translation = max(value.translation.height, 0)
            offset = topOffset + translation
            print("onChanged offset: \(offset)")
          }
          .onEnded { value in
            guard isExpanded else { return }
            withAnimation(.snappy(duration: 0.3)) {

              print("onEnded value: \(value.translation.height)")
              print("onEnded offset: \(offset)")

              let translation = max(value.translation.height, 0)
              let velocity = value.predictedEndTranslation.height

              if translation + velocity > (geometry.size.height * 0.5) {
                isExpanded = false
                offset = 0
              } else {
                isExpanded = true
                offset = topOffset
              }
            }
          }
      )
      .onAppear {
        withAnimation(.snappy(duration: 0.3)) {
          offset = topOffset
        }
      }
    }
    .ignoresSafeArea(edges: .all)
  }

}

private struct CollapsedWorkoutView: View {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.userAccentColor) private var userAccentColor
  
  @Bindable var workout: Workout
  
  init(workout: Workout) {
    self.workout = workout
  }
  
  var body: some View {
    HStack(spacing: 16) {
      if let currentSet = viewModel.currentWorkoutSet, let exerciseDefinition = currentSet.exerciseDefinition {
        // Left side: Show next set info if resting, otherwise current set info
        if viewModel.isResting, let nextSet = viewModel.nextWorkoutSet, let nextDefinition = nextSet.exerciseDefinition {
          // When resting, show the next set information on the left
          CollapsedExerciseInfoView(
            exerciseDefinition: nextDefinition,
            set: nextSet.set,
            setIndex: nextSet.setIndex,
            totalSets: nextSet.exercise.sets.count,
            isSuperset: nextSet.isSuperset,
            displayWeightInLbs: viewModel.displayWeightInLbs,
            isPrefixedWithNext: true
          )
        } else {
          // When not resting, show current set info
          CollapsedExerciseInfoView(
            exerciseDefinition: exerciseDefinition,
            set: currentSet.set,
            setIndex: currentSet.setIndex,
            totalSets: currentSet.exercise.sets.count,
            isSuperset: currentSet.isSuperset,
            displayWeightInLbs: viewModel.displayWeightInLbs
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
        } else {
          // Show Done Set button when not resting
          CollapsedActionButtonView(
            title: "Done Set",
            action: viewModel.handleDoneSet
          )
        }
      } else if viewModel.isWorkoutComplete {
        CollapsedCompletionView(
          stopAction: viewModel.stop
        )
      }
    }
    .padding(.horizontal, 4)
  }
}

/// A reusable view that displays exercise information in the collapsed workout view
private struct CollapsedExerciseInfoView: View {
  @Environment(\.userAccentColor) private var userAccentColor
  
  let exerciseDefinition: ExerciseDefinition
  let set: SetEntry
  let setIndex: Int
  let totalSets: Int
  let isSuperset: Bool
  let displayWeightInLbs: Bool
  let isPrefixedWithNext: Bool
  
  init(
    exerciseDefinition: ExerciseDefinition,
    set: SetEntry,
    setIndex: Int,
    totalSets: Int,
    isSuperset: Bool,
    displayWeightInLbs: Bool,
    isPrefixedWithNext: Bool = false
  ) {
    self.exerciseDefinition = exerciseDefinition
    self.set = set
    self.setIndex = setIndex
    self.totalSets = totalSets
    self.isSuperset = isSuperset
    self.displayWeightInLbs = displayWeightInLbs
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
        
        Text(isPrefixedWithNext ? "NEXT: \(exerciseDefinition.name)" : exerciseDefinition.name)
          .font(.title3)
          .fontWeight(.semibold)
          .lineLimit(1)
      }
      
      CollapsedSetDetailsView(
        setIndex: setIndex,
        totalSets: totalSets,
        reps: set.reps,
        weight: set.weight,
        displayWeightInLbs: displayWeightInLbs
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
      
      Text("\(weight.weightValue(inLbs: displayWeightInLbs), specifier: "%.1f") \(displayWeightInLbs ? "lbs" : "kg")")
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
    .environment(\.startedWorkoutViewModel, startedWorkoutViewModel)
    .modelContainer(AppContainer.preview.modelContainer)
  } else {
    Text("Failed no workout")
  }
}
