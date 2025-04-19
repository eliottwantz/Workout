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
  @State private var exerciseExists: Bool = false

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
          VStack(alignment: .leading) {
            HStack {
              Text("Name")
                .foregroundStyle(.secondary)

              TextField("Exercise Name", text: $name)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .onChange(of: name) { oldValue, newValue in
                  exerciseExists = false
                }
            }
            if exerciseExists {
              Text("Exercise already exists.")
                .foregroundColor(.red)
                .font(.caption)
            }
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
            }
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }

  private func save() {
    if let exerciseDefinition {
      exerciseDefinition.name = name.capitalized.trimmingCharacters(in: .whitespacesAndNewlines)
      exerciseDefinition.muscleGroup = muscleGroup.rawValue
      exerciseDefinition.notes = notes
      exerciseDefinition.favorite = favorite
    } else {
      let capitalizedTrimmedName = name.capitalized.trimmingCharacters(in: .whitespacesAndNewlines)
      var descriptor = FetchDescriptor<ExerciseDefinition>(
        predicate: #Predicate { $0.name == capitalizedTrimmedName }
      )
      descriptor.fetchLimit = 1
      let matchingExerciseCount = try? modelContext.fetchCount(descriptor)
      guard let count = matchingExerciseCount, count == 0 else {
        exerciseExists = true
        return
      }

      let newExerciseDefinition = ExerciseDefinition(
        name: capitalizedTrimmedName,
        muscleGroup: muscleGroup,
        notes: notes,
        favorite: favorite)
      modelContext.insert(newExerciseDefinition)
      try? modelContext.save()
    }

    dismiss()
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
