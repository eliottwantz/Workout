//
//  ExerciseDefinitionEditView.swift
//  Workout
//
//  Created by Eliott on 2025-04-14.
//

import SwiftData
import SwiftUI

struct ExerciseDefinitionEditor: View {
  var exerciseDefinition: ExerciseDefinition?

  private var editorTitle: LocalizedStringResource {
    exerciseDefinition == nil ? "Add Exercise" : "Edit Exercise"
  }

  @State private var name: String = ""
  @State private var muscleGroup: MuscleGroup = .other
  @State private var favorite: Bool = false
  @State private var notes: String = ""

  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) private var modelContext

  init(exerciseDefinition: ExerciseDefinition?) {
    self.exerciseDefinition = exerciseDefinition
    if let exerciseDefinition {
      self._name = State(initialValue: exerciseDefinition.name)
      self._muscleGroup = State(initialValue: MuscleGroup(rawValue: exerciseDefinition.muscleGroup) ?? .other)
      self._favorite = State(initialValue: exerciseDefinition.favorite)
      self._notes = State(initialValue: exerciseDefinition.notes ?? "")
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Basic Information") {
          HStack {
            Text("Name")
              .foregroundStyle(.secondary)
            
            TextField("Exercise Name", text: $name)
              .autocapitalization(.words)
              .disableAutocorrection(true)
          }
          
          Picker("Muscle Group", selection: $muscleGroup) {
            ForEach(MuscleGroup.allCases.sorted(by: { $0.rawValue < $1.rawValue })) { group in
              Text(group.rawValue).tag(group)
            }
          }
          
          HStack {
            Text("Favorite")
            Spacer()
            EditableFavoriteButton(isSet: $favorite)
          }
        }
        
        // MARK: - Notes
        Section("Notes") {
          ZStack(alignment: .topLeading) {
            TextEditor(text: $notes)
              .frame(minHeight: 100)
            
            if notes.isEmpty {
              Text("Enter any notes or instructions here...")
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .padding(.leading, 4)
                .allowsHitTesting(false)
            }
          }
        }
      }
      .navigationTitle(String(localized: editorTitle))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            withAnimation {
              save()
              dismiss()
            }
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }

  private func save() {
    if let exerciseDefinition {
      exerciseDefinition.name = name.capitalized
      exerciseDefinition.muscleGroup = muscleGroup.rawValue
      exerciseDefinition.notes = notes
      exerciseDefinition.favorite = favorite
    } else {
      let newExerciseDefinition = ExerciseDefinition(
        name: name.capitalized,
        muscleGroup: muscleGroup,
        notes: notes,
        favorite: favorite)
      modelContext.insert(newExerciseDefinition)
      try? modelContext.save()
    }
  }

}

#Preview("Add Exercise Definition") {
  ExerciseDefinitionEditor(exerciseDefinition: nil)
    .modelContainer(AppContainer.preview.modelContainer)
}

#Preview("Edit Exercise Definition") {
  let container = AppContainer.preview.modelContainer
  let sampleExercise = ExerciseDefinition(
    name: "Barbell Bench Press",
    muscleGroup: .chest,
    notes: "Keep elbows at 45°, maintain back arch.",
    favorite: true)
  container.mainContext.insert(sampleExercise)

  return
    ExerciseDefinitionEditor(exerciseDefinition: sampleExercise)
      .modelContainer(container)

}
