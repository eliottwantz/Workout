//
//  AddExerciseView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct AddExerciseView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @Bindable var workout: Workout

  @State private var selectedExercises = Set<PersistentIdentifier>()
  @State private var selectedOption = AddOption.individual

  enum AddOption {
    case individual
    case superset
  }

  var body: some View {
    VStack {
      Picker("Add Option", selection: $selectedOption) {
        Text("Individual Exercises").tag(AddOption.individual)
        Text("Superset").tag(AddOption.superset)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)

      ExerciseSelectionView(
        selectedExercises: $selectedExercises,
        headerText: selectedOption == .individual
          ? "Select exercises to add to your workout"
          : "Select exercises to include in your superset",
        disabled: selectedOption == .individual
          ? selectedExercises.isEmpty : selectedExercises.count < 2,
        confirmAction: {
          switch selectedOption {
          case .individual:
            addSelectedExercisesToWorkout()
            dismiss()
          case .superset:
            addSelectedExercisesToWorkout()
            dismiss()
          }
        }
      )
    }
    .navigationTitle("Add Exercises")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
    }
  }

  private func addSelectedExercisesToWorkout() {
    if selectedExercises.isEmpty { return }

    if selectedOption == .individual {
      // Add individual exercises to the workout
      for definitionID in selectedExercises {
        if let definition = try? modelContext.fetch(
          FetchDescriptor<ExerciseDefinition>(
            predicate: #Predicate { $0.persistentModelID == definitionID }
          )
        ).first {
          // Look for the most recent instance of this exercise
          if let previousExercise = AppContainer.findMostRecentExercise(
            for: definitionID, currentWorkoutID: workout.id, modelContext: modelContext)
          {
            // Create a new exercise with the same definition and rest time
            let exercise = Exercise(
              definition: definition,
              workout: workout,
              restTime: previousExercise.restTime,
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

            let workoutItem = WorkoutItem(exercise: exercise)
            workout.addItem(workoutItem)
          } else {
            // No previous exercise found, create a new one with defaults
            let exercise = Exercise(definition: definition, workout: workout)
            let workoutItem = WorkoutItem(exercise: exercise)
            workout.addItem(workoutItem)
          }
        }
      }
    } else {
      // Create a superset with the selected exercises
      let superset = Superset()

      for (index, definitionID) in selectedExercises.enumerated() {
        if let definition = try? modelContext.fetch(
          FetchDescriptor<ExerciseDefinition>(
            predicate: #Predicate { $0.persistentModelID == definitionID }
          )
        ).first {
          // Look for the most recent instance of this exercise
          if let previousExercise = AppContainer.findMostRecentExercise(
            for: definitionID, currentWorkoutID: workout.id, modelContext: modelContext)
          {
            // Create a new exercise with the same definition and rest time
            let exercise = Exercise(
              definition: definition,
              workout: workout,
              restTime: previousExercise.restTime,
              orderWithinSuperset: index,
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
              orderWithinSuperset: index
            )
            superset.addExercise(exercise)
          }
        }
      }

      let workoutItem = WorkoutItem(superset: superset)
      workout.addItem(workoutItem)
    }

    try? modelContext.save()
  }

  // Helper function to get the workout date for an exercise
  private func getWorkoutDateForExercise(_ exercise: Exercise) -> Date? {
    // Check if the exercise is directly in a workout
    if let workoutItem = exercise.workoutItem, let workout = workoutItem.workout {
      return workout.date
    }

    // Check if the exercise is in a superset
    if let superset = exercise.containingSuperset,
      let workoutItem = superset.workoutItem,
      let workout = workoutItem.workout
    {
      return workout.date
    }

    return nil
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext
  AppContainer.addSampleData(modelContext)

  let workoutFetchDescriptor = FetchDescriptor<Workout>()
  let workouts = try! modelContext.fetch(workoutFetchDescriptor)
  let sampleWorkout = workouts.first ?? Workout(date: Date())

  return NavigationStack {
    AddExerciseView(workout: sampleWorkout)
      .modelContainer(container)
  }
}
