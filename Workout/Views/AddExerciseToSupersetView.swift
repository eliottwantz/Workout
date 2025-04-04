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

  @Query(sort: \ExerciseDefinition.name) var exerciseDefinitions: [ExerciseDefinition]
  @State private var searchText = ""
  @State private var selectedExercises: Set<PersistentIdentifier> = []
  @State private var showingAddNewExerciseDialog = false
  @State private var newExerciseName = ""

  var body: some View {
    VStack {
      List(selection: $selectedExercises) {
        ForEach(filteredExerciseDefinitions) { definition in
          Text(definition.name)
        }
      }
      .searchable(text: $searchText, prompt: "Search exercises")
      .listStyle(.grouped)
      .environment(\.editMode, .constant(.active))

      Button {
        addSelectedExercisesToSuperset()
        dismiss()
      } label: {
        Text("Add ^[\(selectedExercises.count) Exercise](inflect: true) to Superset")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(selectedExercises.isEmpty)
      .padding([.horizontal, .bottom])

    }
    .navigationTitle("Add to Superset")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          showingAddNewExerciseDialog = true
        } label: {
          Label("Add New Exercise", systemImage: "plus")
            .frame(maxWidth: .infinity)
        }
      }
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
    }
    .alert("Add New Exercise", isPresented: $showingAddNewExerciseDialog) {
      TextField("Exercise Name", text: $newExerciseName)

      Button("Cancel", role: .cancel) {}
      Button("Add") {
        addNewExerciseDefinition()
      }
    } message: {
      Text("Enter the name of the exercise you want to add.")
    }
  }

  private var filteredExerciseDefinitions: [ExerciseDefinition] {
    if searchText.isEmpty {
      return exerciseDefinitions.sorted { $0.name < $1.name }
    } else {
      return exerciseDefinitions.filter {
        $0.name.localizedCaseInsensitiveContains(searchText)
      }.sorted { $0.name < $1.name }
    }
  }

  private func toggleSelection(_ definition: ExerciseDefinition) {
    if selectedExercises.contains(definition.id) {
      selectedExercises.remove(definition.id)
    } else {
      selectedExercises.insert(definition.id)
    }
  }

  private func addNewExerciseDefinition() {
    guard !newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    if ExerciseUtilities.createNewExerciseDefinition(with: newExerciseName, in: modelContext) != nil {
      // Reset the input field after successful creation
      newExerciseName = ""
    }
  }

  private func addSelectedExercisesToSuperset() {
    if selectedExercises.isEmpty { return }

    // Get the next available order within the superset
    let nextOrder = superset.exercises.count

    // Add the selected exercises to the superset
    for (index, definitionID) in selectedExercises.enumerated() {
      if let definition = exerciseDefinitions.first(where: { $0.id == definitionID }) {
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
