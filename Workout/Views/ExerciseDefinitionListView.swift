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

  @State private var isEditorPresented = false
  @State private var path = NavigationPath()

  var body: some View {
    NavigationStack(path: $path) {
      List {
        ForEach(exercises) { definition in
          NavigationLink(value: definition) {
            Text(definition.name)
          }
          .padding(.vertical, 8)
        }
        .onDelete(perform: deleteExerciseDefinitions)
      }
      .overlay {
        if exercises.isEmpty {
          ContentUnavailableView {
            Label("No exercises", systemImage: "dumbbell")
          } actions: {
            Button("Add Workout", systemImage: "plus") {
              isEditorPresented = true
            }
          }
        }
      }
      .navigationDestination(for: ExerciseDefinition.self) { definition in
        ExerciseDefinitionDetailView(exercise: definition, path: $path)
      }
      .navigationTitle("Exercises")
      .sheet(isPresented: $isEditorPresented) {
        ExerciseDefinitionEditor(exerciseDefinition: nil)
          .interactiveDismissDisabled()
      }
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          NavigationLink(destination: SettingsView()) {
            Label("Settings", systemImage: "gear")
          }
        }

        ToolbarItemGroup(placement: .primaryAction) {
          EditButton()

          Button {
            isEditorPresented = true
          } label: {
            Image(systemName: "plus")
          }
        }
      }
    }
  }

  private func deleteExerciseDefinitions(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        exercises[index].deleteWithAllContainingExercises(in: modelContext)
      }
    }
  }
}

#Preview {
  // Example preview setup
  let container = AppContainer.preview.modelContainer

  return ExerciseDefinitionListView()
    .modelContainer(container)
}
