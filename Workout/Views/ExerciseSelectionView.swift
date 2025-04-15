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
  @Environment(\.userAccentColor) private var userAccentColor

  @Query(sort: \ExerciseDefinition.name) var exerciseDefinitions: [ExerciseDefinition]
  @Binding var selectedExercises: Set<PersistentIdentifier>
  @State private var searchText = ""
  @State private var isEditorPresented = false

  // Custom button to be provided by parent views
  let actionButton: ActionButton
  let headerText: LocalizedStringResource

  init(
    selectedExercises: Binding<Set<PersistentIdentifier>>,
    headerText: LocalizedStringResource,
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
      .searchable(text: $searchText, prompt: "Exercise Name")
      .environment(\.editMode, .constant(.active))
      .listStyle(.inset)

      actionButton
        .padding([.horizontal, .bottom])
        .buttonStyle(.borderedProminent)
        .foregroundStyle(userAccentColor.contrastColor)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          isEditorPresented = true
        } label: {
          Label("Add New Exercise", systemImage: "plus")
        }
      }
    }
    .interactiveDismissDisabled()
    .presentationDetents([.fraction(0.65), .large])
    .sheet(isPresented: $isEditorPresented) {
      ExerciseDefinitionEditor(exerciseDefinition: nil)
        .interactiveDismissDisabled()
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

}
