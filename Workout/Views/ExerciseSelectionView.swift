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
struct ExerciseSelectionView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.userAccentColor) private var userAccentColor
  @Query(sort: \ExerciseDefinition.name) var exerciseDefinitions: [ExerciseDefinition]

  @Binding var selectedExercises: Set<PersistentIdentifier>
  let headerText: LocalizedStringResource
  let disabled: Bool
  let confirmAction: () -> Void

  @State private var searchText = ""

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
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          confirmAction()
        } label: {
          Label("Confirm", systemImage: "checkmark")
        }
        .disabled(disabled)
        .buttonStyle(.glassProminent)

      }
    }
    .interactiveDismissDisabled()
    .presentationDetents([.fraction(0.65), .large])
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
