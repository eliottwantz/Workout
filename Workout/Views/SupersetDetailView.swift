//
//  SupersetDetailView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct SupersetDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var superset: Superset

  @State private var editMode = EditMode.inactive
  @State private var showingAddExerciseView = false

  var body: some View {
    List {
      Section("Rest time") {
        RestTimePicker(superset: superset)
      }
      Section("Exercises") {
        if let exercises = superset.orderedExercises, !exercises.isEmpty {
          ForEach(superset.exercises) { exercise in
            if let definition = exercise.definition {
              NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                HStack {
                  Text(definition.name)
                    .font(.headline)
                  Spacer()
                  Text("\(exercise.sets.count) sets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
              }
            } else {
              Text("Unknown Exercise")
                .foregroundColor(.secondary)
            }
          }
          .onDelete(perform: deleteExercises)
          .onMove(perform: moveExercises)
        } else {
          Text("No exercises in this superset")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
      }
    }
    .navigationTitle("Superset Detail")
    .toolbar {
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
        AddExerciseToSupersetView(superset: superset)
      }
    }
  }

  private func deleteExercises(at offsets: IndexSet) {
    for index in offsets {
      if let exercises = superset.orderedExercises {
        let exerciseToDelete = superset.exercises[index]
        if let exerciseIndex = exercises.firstIndex(where: {
          $0.persistentModelID == exerciseToDelete.persistentModelID
        }) {
          superset.orderedExercises?.remove(at: exerciseIndex)
          modelContext.delete(exerciseToDelete)
        }
      }
    }

    // Update order of remaining exercises
    for (index, exercise) in superset.exercises.enumerated() {
      exercise.orderWithinSuperset = index
    }

    try? modelContext.save()
  }

  private func moveExercises(from source: IndexSet, to destination: Int) {
    var exercises = superset.exercises
    exercises.move(fromOffsets: source, toOffset: destination)

    // Update the order property for all exercises
    for (index, exercise) in exercises.enumerated() {
      exercise.orderWithinSuperset = index
    }

    try? modelContext.save()
  }

}

private struct RestTimePicker: View {
  @Bindable var superset: Superset

  @State private var showingRestTimePicker = false

  var body: some View {
    Button {
      showingRestTimePicker = true
    } label: {
      Stepper(value: $superset.restTime, in: 5...600, step: 5) {
        HStack {
          Text(superset.restTime.formattedRestTime)
            .frame(minWidth: 60, alignment: .center)
            .font(.body.monospacedDigit())
            .foregroundStyle(Color.primary)
            .contentTransition(.numericText())
            .animation(.snappy, value: superset.restTime)
        }
      }
    }
    .sheet(isPresented: $showingRestTimePicker) {
      RestTimePickerView(restTime: $superset.restTime)
        .presentationDetents([.fraction(0.7)])
    }
  }

  private func incrementRestTime() {
    withAnimation {
      superset.restTime += 15
    }
  }

  private func decrementRestTime() {
    withAnimation {
      // Ensure we don't go below 0 seconds
      superset.restTime = max(0, superset.restTime - 15)
    }
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext

  let bicepCurlDefinition = ExerciseDefinition(name: "Bicep Curls")
  let tricepsExtensionDefinition = ExerciseDefinition(name: "Triceps Extensions")

  modelContext.insert(bicepCurlDefinition)
  modelContext.insert(tricepsExtensionDefinition)

  let superset = Superset()

  let bicepCurlExercise = Exercise(
    definition: bicepCurlDefinition, restTime: 60, orderWithinSuperset: 0)
  bicepCurlExercise.addSet(SetEntry(reps: 12, weight: 20.0))
  bicepCurlExercise.addSet(SetEntry(reps: 10, weight: 22.5))
  superset.addExercise(bicepCurlExercise)

  let tricepsExtensionExercise = Exercise(
    definition: tricepsExtensionDefinition, restTime: 60, orderWithinSuperset: 1)
  tricepsExtensionExercise.addSet(SetEntry(reps: 12, weight: 35.0))
  tricepsExtensionExercise.addSet(SetEntry(reps: 10, weight: 40.0))
  superset.addExercise(tricepsExtensionExercise)

  modelContext.insert(superset)

  return NavigationStack {
    SupersetDetailView(superset: superset)
      .modelContainer(container)
  }
}
