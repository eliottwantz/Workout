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
      Section("Rest Time") {
        RestTimePicker(superset: superset)
      }
      if !superset.orderedExercises.isEmpty {
        Section("Exercises") {
          ForEach(superset.orderedExercises) { exercise in
            if let definition = exercise.definition {
              NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                HStack {
                  Text(definition.name)
                    .font(.headline)
                  Spacer()
                  Text("\(exercise.orderedSets.count) sets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .frame(minHeight: 60)
              }
            }
          }
          .onDelete(perform: deleteExercises)
          .onMove(perform: moveExercises)

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
      if superset.orderedExercises.isEmpty {
        ContentUnavailableView {
          Label("No exercises", systemImage: "figure.strengthtraining.traditional")
        } actions: {
          Button("Add Exercises", systemImage: "plus") {
            showingAddExerciseView = true
          }
        }
      }
    }
    .navigationTitle("Superset Detail")
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        EditButton()
        Button {
          showingAddExerciseView = true
        } label: {
          Label("Add Exercises", systemImage: "plus")
        }
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
      if let exercises = superset.exercises {
        let exerciseToDelete = superset.orderedExercises[index]
        if let exerciseIndex = exercises.firstIndex(where: {
          $0.persistentModelID == exerciseToDelete.persistentModelID
        }) {
          superset.exercises?.remove(at: exerciseIndex)
          modelContext.delete(exerciseToDelete)
        }
      }
    }

    // Update order of remaining exercises
    for (index, exercise) in superset.orderedExercises.enumerated() {
      exercise.orderWithinSuperset = index
    }

    try? modelContext.save()
  }

  private func moveExercises(from source: IndexSet, to destination: Int) {
    var exercises = superset.orderedExercises
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
      .sensoryFeedback(trigger: superset.restTime) { oldValue, newValue in
        return newValue < oldValue ? .decrease : .increase
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

  // Create a sample workout
  let workout = Workout(date: Date())
  modelContext.insert(workout)

  // Create a superset
  let superset = Superset()
  let workoutItem = WorkoutItem(superset: superset)
  workout.addItem(workoutItem)

  // Add exercise definitions
  let bicepCurlDefinition = ExerciseDefinition(name: "Bicep Curl")
  let tricepsDefinition = ExerciseDefinition(name: "Triceps Extension")
  modelContext.insert(bicepCurlDefinition)
  modelContext.insert(tricepsDefinition)

  // Add exercises to the superset
  let bicepCurlExercise = Exercise(
    definition: bicepCurlDefinition,
    workout: workout,
    restTime: 60,
    orderWithinSuperset: 0
  )
  superset.addExercise(bicepCurlExercise)

  let tricepsExtensionExercise = Exercise(
    definition: tricepsDefinition,
    workout: workout,
    restTime: 60,
    orderWithinSuperset: 1
  )
  superset.addExercise(tricepsExtensionExercise)

  // Add some sets
  let set1 = SetEntry(reps: 10, weight: 25)
  let set2 = SetEntry(reps: 10, weight: 30)

  bicepCurlExercise.addSet(set1)
  tricepsExtensionExercise.addSet(set2)

  try? modelContext.save()

  return NavigationStack {
    SupersetDetailView(superset: superset)
      .modelContainer(container)
  }
}
