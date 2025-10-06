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
  @Environment(\.router) private var router
  @Query(sort: \ExerciseDefinition.name) private var exercises: [ExerciseDefinition]

  @State private var isEditorPresented = false

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.exercises.path) {
      List {
        ForEach(exercises) { definition in
          NavigationLink(
            value: ExercisesRouter.Route.exerciseDefinitionDetailView(exercise: definition)
          ) {
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
      .navigationDestination(for: ExercisesRouter.Route.self) { route in
        switch route {
        case .settings:
          SettingsView()
        case .exerciseDefinitionDetailView(let exercise):
          ExerciseDefinitionDetailView(exercise: exercise)
        default:
          ExerciseDefinitionListView()
        }
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
