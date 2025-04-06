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
          : "Select exercises to include in your superset"
      ) {
        Button {
          addSelectedExercisesToWorkout()
          dismiss()
        } label: {
          Text(
            selectedOption == .individual
              ? "Add ^[\(selectedExercises.count) Exercise](inflect: true)"
              : "Add Superset with ^[\(selectedExercises.count) Exercise](inflect: true)"
          )
          .frame(maxWidth: .infinity)
        }
        .disabled(selectedOption == .individual ? selectedExercises.isEmpty : selectedExercises.count < 2)
      }
    }
    .navigationTitle("Add Exercise")
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
          if let previousExercise = findMostRecentExercise(for: definitionID) {
            // Create a new exercise with the same definition and rest time
            let exercise = Exercise(
              definition: definition,
              restTime: previousExercise.restTime,
              notes: previousExercise.notes
            )
            
            // Copy all sets from the previous exercise
            for setEntry in previousExercise.sets {
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
            let exercise = Exercise(definition: definition)
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
          if let previousExercise = findMostRecentExercise(for: definitionID) {
            // Create a new exercise with the same definition and rest time
            let exercise = Exercise(
              definition: definition,
              restTime: previousExercise.restTime,
              orderWithinSuperset: index,
              notes: previousExercise.notes
            )
            
            // Copy all sets from the previous exercise
            for setEntry in previousExercise.sets {
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

  private func findMostRecentExercise(for definitionID: PersistentIdentifier) -> Exercise? {
    // Find the most recent workout that contains this exercise definition
    
    let descriptor = FetchDescriptor<Workout>(
      sortBy: [SortDescriptor(\.date, order: .reverse)]  // Most recent workouts first
    )
    
    guard let workouts = try? modelContext.fetch(descriptor) else { return nil }
    
    // Skip the current workout if it's already in the database
    let workoutsToSearch = workouts.filter { $0.persistentModelID != workout.persistentModelID }
    
    // Search through workouts from most recent to oldest
    for pastWorkout in workoutsToSearch {
      // Look through each workout item
      for item in pastWorkout.orderedItems {
        // Check individual exercises
        if let exercise = item.exercise, 
           exercise.definition?.persistentModelID == definitionID {
          return exercise
        }
        
        // Check exercises in supersets
        if let superset = item.superset {
          for exercise in superset.exercises {
            if exercise.definition?.persistentModelID == definitionID {
              return exercise
            }
          }
        }
      }
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
