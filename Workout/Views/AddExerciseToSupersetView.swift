//
//  AddExerciseToSupersetView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct AddExerciseToSupersetView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.startedWorkoutViewModel) private var startedWorkoutViewModel
  @Environment(\.dismiss) private var dismiss

  @Bindable var superset: Superset

  @State private var selectedExercises = Set<PersistentIdentifier>()

  var body: some View {
    ExerciseSelectionView(
      selectedExercises: $selectedExercises,
      headerText: "Select exercises to add to your superset"
    ) {
      Button {
        addSelectedExercisesToSuperset()
        dismiss()
      } label: {
        Text("Add \(selectedExercises.count) Exercises to Superset")
          .frame(maxWidth: .infinity)
      }
      .disabled(selectedExercises.isEmpty)
    }
    .navigationTitle("Add to Superset")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
    }
  }

  private func addSelectedExercisesToSuperset() {
    if selectedExercises.isEmpty { return }

    // Add the selected exercises to the superset
    for definitionID in selectedExercises {
      addExerciseToSuperset(definitionID: definitionID)
    }

    try? modelContext.save()
    
    startedWorkoutViewModel.updateLiveActivity()
  }

  private func addExerciseToSuperset(definitionID: PersistentIdentifier) {
    if let definition = try? modelContext.fetch(
      FetchDescriptor<ExerciseDefinition>(
        predicate: #Predicate { $0.persistentModelID == definitionID }
      )
    ).first {
      // Get the workout from the superset's workoutItem
      if let workout = superset.workoutItem?.workout {
        // Look for the most recent instance of this exercise
        if let previousExercise = AppContainer.findMostRecentExercise(
          for: definitionID, currentWorkoutID: workout.id, modelContext: modelContext)
        {
          // Create a new exercise with the same definition and rest time
          let exercise = Exercise(
            definition: definition,
            workout: workout,
            restTime: previousExercise.restTime,
            orderWithinSuperset: superset.orderedExercises.count,
            notes: previousExercise.notes
          )

          // Copy all sets from the previous exercise
          for setEntry in previousExercise.orderedSets {
            let newSet = SetEntry(
              reps: setEntry.reps,
              weight: setEntry.weight
            )
            exercise.addSet(newSet)
          }

          superset.addExercise(exercise)
        } else {
          // No previous exercise found, create a new one with defaults
          let exercise = Exercise(
            definition: definition,
            workout: workout,
            orderWithinSuperset: superset.orderedExercises.count
          )
          superset.addExercise(exercise)
        }
        try? modelContext.save()
      }
    }
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext

  // Create a sample workout and superset
  let workout = Workout(date: Date())
  let superset = Superset()

  // Create workout item for the superset
  let workoutItem = WorkoutItem(superset: superset)
  workout.addItem(workoutItem)

  // Add some exercise definitions
  let benchPressDefinition = ExerciseDefinition(name: "Bench Press")
  let squatDefinition = ExerciseDefinition(name: "Squat")
  let deadliftDefinition = ExerciseDefinition(name: "Deadlift")

  modelContext.insert(benchPressDefinition)
  modelContext.insert(squatDefinition)
  modelContext.insert(deadliftDefinition)
  modelContext.insert(workout)

  // Add one exercise to the superset
  let benchPressExercise = Exercise(definition: benchPressDefinition, workout: workout, orderWithinSuperset: 0)
  superset.addExercise(benchPressExercise)

  return NavigationStack {
    AddExerciseToSupersetView(superset: superset)
      .modelContainer(container)
  }
}
