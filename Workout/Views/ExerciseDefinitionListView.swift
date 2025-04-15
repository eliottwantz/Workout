//
//  ExerciseDefinitionListView.swift
//  Workout
//
//  Created by Eliott on 2025-04-14.
//

import SwiftData
import SwiftUI

struct ExerciseDefinitionListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \ExerciseDefinition.name) private var exercises: [ExerciseDefinition]

  @State private var showingAddExerciseAlert = false
  @State private var newExerciseName = ""


  var body: some View {
    NavigationStack {
      List {
        ForEach(exercises) { definition in
          NavigationLink(value: definition) {
            Text(definition.name)
          }
          .padding(.vertical, 8)
        }
        .onDelete(perform: deleteExerciseDefinitions)
      }
      .navigationDestination(for: ExerciseDefinition.self) { definition in
        ExerciseDefinitionEditView(exerciseDefinition: definition)
      }
      .navigationTitle("Exercises")
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          NavigationLink(destination: SettingsView()) {
            Label("Settings", systemImage: "gear")
          }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          EditButton()

          Button {
            showingAddExerciseAlert = true
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .alert("Add New Exercise", isPresented: $showingAddExerciseAlert) {
        TextField("Exercise Name", text: $newExerciseName)
          .autocapitalization(.words)
        Button("Cancel", role: .cancel) {
          newExerciseName = ""
        }

        Button("Add") {
          addExerciseDefinition()
        }
        .disabled(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

      } message: {
        Text("Enter the name for the new exercise.")
      }
    }
  }

  private func addExerciseDefinition() {
    if ExerciseDefinition.createAndSave(with: newExerciseName, in: modelContext) != nil {
      newExerciseName = ""
    }
  }

  private func deleteExerciseDefinitions(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(exercises[index])
      }
      try? modelContext.save()
    }
  }
}

#Preview {
  // Example preview setup
  let container = AppContainer.preview.modelContainer

  return ExerciseDefinitionListView()
    .modelContainer(container)
}
