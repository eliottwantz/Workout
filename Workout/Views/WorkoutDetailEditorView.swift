//
//  WorkoutDetailEditorView.swift
//  Workout
//
//  Created by Eliott on 2025-04-09.
//

import SwiftData
import SwiftUI

struct WorkoutDetailEditorView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.userAccentColor) private var userAccentColor
  @Environment(\.dismiss) private var dismiss
  @Bindable var workout: Workout

  @State private var editMode = EditMode.inactive
  @State private var showingAddExerciseView = false

  var body: some View {
    List {
      if !workout.orderedItems.isEmpty {
        Section("Exercises") {
          ForEach(workout.orderedItems) { workoutItem in
            WorkoutItemRowView(workoutItem: workoutItem)
              .frame(minHeight: 60)
          }
          .onMove(perform: moveItems)
          .onDelete(perform: deleteItems)

          Button {
            showingAddExerciseView = true
          } label: {
            Label("Add Exercises", systemImage: "plus")
          }
          .frame(minHeight: 40)
        }
      }
    }
    .overlay {
      if workout.orderedItems.isEmpty {
        ContentUnavailableView {
          Label("No exercises", systemImage: "figure.strengthtraining.traditional")
        } actions: {
          Button("Add Exercises", systemImage: "plus") {
            showingAddExerciseView = true
          }
        }
      }
    }
    .navigationTitle("Edit Workout")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarLeading) {
        Button("Done") {
          dismiss()
        }
      }

      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          showingAddExerciseView = true
        } label: {
          Label("Add Exercises", systemImage: "plus")
        }
        EditButton()
      }
    }
    .environment(\.editMode, $editMode)
    .sheet(isPresented: $showingAddExerciseView) {
      NavigationStack {
        AddExerciseView(workout: workout)
      }
    }
  }

  private func moveItems(from source: IndexSet, to destination: Int) {
    withAnimation {
      var items = workout.orderedItems
      items.move(fromOffsets: source, toOffset: destination)

      for (index, item) in items.enumerated() {
        item.order = index
      }

      try? modelContext.save()
    }
  }

  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(workout.orderedItems[index])
      }

      // Update the order of remaining items
      for (index, item) in workout.orderedItems.enumerated() {
        item.order = index
      }

      try? modelContext.save()
    }
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext

  let workoutFetchDescriptor = FetchDescriptor<Workout>()
  let workouts = try! modelContext.fetch(workoutFetchDescriptor)
  let sampleWorkout = workouts.first ?? Workout(date: Date())

  return NavigationStack {
    WorkoutDetailEditorView(workout: sampleWorkout)
      .modelContainer(container)
  }
}
