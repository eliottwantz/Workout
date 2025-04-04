//
//  ExerciseSelectionView.swift
//  Workout
//
//  Created by Eliott on 2025-04-04.
//

import SwiftData
import SwiftUI

/// A reusable view for selecting exercises from a list.
/// Used by both AddExerciseView and AddExerciseToSupersetView to maintain DRY principles.
struct ExerciseSelectionView<ActionButton: View>: View {
  @Environment(\.modelContext) private var modelContext

  @Query(sort: \ExerciseDefinition.name) var exerciseDefinitions: [ExerciseDefinition]
  @Binding var selectedExercises: Set<PersistentIdentifier>
  @State private var searchText = ""
  @State private var showingAddNewExerciseDialog = false
  @State private var newExerciseName = ""
  @State private var editMode = EditMode.active

  // Custom button to be provided by parent views
  let actionButton: ActionButton
  let headerText: String

  init(
    selectedExercises: Binding<Set<PersistentIdentifier>>,
    headerText: String,
    @ViewBuilder actionButton: () -> ActionButton
  ) {
    self._selectedExercises = selectedExercises
    self.headerText = headerText
    self.actionButton = actionButton()
  }

  var body: some View {
    VStack {
      Text(headerText)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.horizontal)

      List(filteredExerciseDefinitions, selection: $selectedExercises) { definition in
        Text(definition.name)
      }
      .searchable(text: $searchText, prompt: "Search exercises")
      .environment(\.editMode, .constant(.active))
      .listStyle(.inset)

      actionButton
        .padding([.horizontal, .bottom])
        .disabled(selectedExercises.isEmpty)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          showingAddNewExerciseDialog = true
        } label: {
          Label("Add New Exercise", systemImage: "plus")
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
      return exerciseDefinitions
    } else {
      return exerciseDefinitions.filter {
        $0.name.localizedCaseInsensitiveContains(searchText)
      }
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
}
