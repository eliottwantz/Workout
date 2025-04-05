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
        Text("Add ^[\(selectedExercises.count) Exercise](inflect: true) to Superset")
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

    // Get the next available order within the superset
    let nextOrder = superset.exercises.count

    // Add the selected exercises to the superset
    for (index, definitionID) in selectedExercises.enumerated() {
      if let definition = try? modelContext.fetch(
        FetchDescriptor<ExerciseDefinition>(
          predicate: #Predicate { $0.persistentModelID == definitionID }
        )
      ).first {
        let exercise = Exercise(
          definition: definition,
          orderWithinSuperset: nextOrder + index
        )
        superset.addExercise(exercise)
      }
    }

    try? modelContext.save()
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext

  // Create a sample superset
  let superset = Superset()

  // Add some exercise definitions
  let benchPressDefinition = ExerciseDefinition(name: "Bench Press")
  let squatDefinition = ExerciseDefinition(name: "Squat")
  let deadliftDefinition = ExerciseDefinition(name: "Deadlift")

  modelContext.insert(benchPressDefinition)
  modelContext.insert(squatDefinition)
  modelContext.insert(deadliftDefinition)

  // Add one exercise to the superset
  let benchPressExercise = Exercise(definition: benchPressDefinition, orderWithinSuperset: 0)
  superset.addExercise(benchPressExercise)

  modelContext.insert(superset)

  return NavigationStack {
    AddExerciseToSupersetView(superset: superset)
      .modelContainer(container)
  }
}
