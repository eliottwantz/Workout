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

  @State private var selectedExercises: Set<PersistentIdentifier> = []
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
        .buttonStyle(.borderedProminent)
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
            predicate: #Predicate { $0.id == definitionID }
          )
        ).first {
          let exercise = Exercise(definition: definition)
          let workoutItem = WorkoutItem(exercise: exercise)
          workout.addItem(workoutItem)
        }
      }
    } else {
      // Create a superset with the selected exercises
      let superset = Superset()

      for (index, definitionID) in selectedExercises.enumerated() {
        if let definition = try? modelContext.fetch(
          FetchDescriptor<ExerciseDefinition>(
            predicate: #Predicate { $0.id == definitionID }
          )
        ).first {
          let exercise = Exercise(
            definition: definition,
            orderWithinSuperset: index
          )
          superset.addExercise(exercise)
        }
      }

      let workoutItem = WorkoutItem(superset: superset)
      workout.addItem(workoutItem)
    }

    try? modelContext.save()
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
