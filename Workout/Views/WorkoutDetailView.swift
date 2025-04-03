//
//  WorkoutDetailView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var workout: Workout

  @State private var isEditingMode = false
  @State private var showingAddExerciseView = false
  @State private var showingCopyToTodayAlert = false

  var body: some View {
    List {
      if let items = workout.orderedItems, !items.isEmpty {
        ForEach(workout.items) { workoutItem in
          WorkoutItemRowView(workoutItem: workoutItem)
            .contextMenu {
              Button(role: .destructive) {
                deleteItem(workoutItem)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
        }
        .onMove(perform: moveItems)
      } else {
        Text("No exercises added yet")
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding()
      }
    }
    .navigationTitle(formattedDate)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        if !Calendar.current.isDateInToday(workout.date) {
          Button {
            showingCopyToTodayAlert = true
          } label: {
            Label("Copy to Today", systemImage: "doc.on.doc")
          }
        }

        Button {
          isEditingMode.toggle()
        } label: {
          Text(isEditingMode ? "Done" : "Edit")
        }
        Button {
          showingAddExerciseView = true
        } label: {
          Label("Add Exercise", systemImage: "plus")
        }
      }
    }
    .environment(\.editMode, .constant(isEditingMode ? .active : .inactive))
    .sheet(isPresented: $showingAddExerciseView) {
      NavigationStack {
        AddExerciseView(workout: workout)
      }
      .presentationDetents([.medium, .large])
    }
    .alert("Copy Workout to Today", isPresented: $showingCopyToTodayAlert) {
      Button("Copy", role: .none) {
        copyWorkoutToToday()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Do you want to copy this workout to today?")
    }
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium

    let calendar = Calendar.current
    if calendar.isDateInToday(workout.date) {
      return "Today's Workout"
    } else if calendar.isDateInYesterday(workout.date) {
      return "Yesterday's Workout"
    } else {
      return formatter.string(from: workout.date)
    }
  }

  private func moveItems(from source: IndexSet, to destination: Int) {
    var items = workout.items
    items.move(fromOffsets: source, toOffset: destination)

    // Update the order property for all items
    for (index, item) in items.enumerated() {
      item.order = index
    }

    try? modelContext.save()
  }

  private func deleteItem(_ item: WorkoutItem) {
    if let items = workout.orderedItems, let index = items.firstIndex(where: { $0.id == item.id }) {
      workout.orderedItems?.remove(at: index)
      modelContext.delete(item)

      // Update order of remaining items
      for (index, item) in workout.items.enumerated() {
        item.order = index
      }

      try? modelContext.save()
    }
  }

  private func copyWorkoutToToday() {
    // Create a new workout with today's date
    let todayWorkout = Workout(date: Date())

    // Copy all workout items from the source workout
    for item in workout.items {
      if let exercise = item.exercise {
        // Create a new exercise
        let newExercise = Exercise(
          definition: exercise.definition!,
          restTime: exercise.restTime
        )

        // Copy all sets from the original exercise
        for setEntry in exercise.sets {
          newExercise.addSet(
            SetEntry(
              reps: setEntry.reps,
              weight: setEntry.weight
            ))
        }

        // Add the new exercise to the today workout
        let newItem = WorkoutItem(exercise: newExercise)
        todayWorkout.addItem(newItem)

      } else if let superset = item.superset {
        // Create a new superset
        let newSuperset = Superset()

        // Copy all exercises in the superset
        for exercise in superset.exercises {
          let newExercise = Exercise(
            definition: exercise.definition!,
            restTime: exercise.restTime,
            orderWithinSuperset: exercise.orderWithinSuperset
          )

          // Copy all sets from the original exercise
          for setEntry in exercise.sets {
            newExercise.addSet(
              SetEntry(
                reps: setEntry.reps,
                weight: setEntry.weight
              ))
          }

          newSuperset.addExercise(newExercise)
        }

        // Add the new superset to the today workout
        let newItem = WorkoutItem(superset: newSuperset)
        todayWorkout.addItem(newItem)
      }
    }

    // Insert the new workout into the model context
    modelContext.insert(todayWorkout)
    try? modelContext.save()
  }
}

struct WorkoutItemRowView: View {
  let workoutItem: WorkoutItem

  var body: some View {
    if let exercise = workoutItem.exercise, let definition = exercise.definition {
      NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
        HStack {
          Text(definition.name)
            .font(.headline)
          Spacer()
          Text("\(exercise.sets.count) sets")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
      }
    } else if let superset = workoutItem.superset {
      NavigationLink(destination: SupersetDetailView(superset: superset)) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Superset")
            .font(.headline)

          ForEach(superset.exercises) { exercise in
            if let definition = exercise.definition {
              Text("• \(definition.name)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
          }
        }
        .padding(.vertical, 4)
      }
    } else {
      Text("Unknown workout item")
        .foregroundColor(.secondary)
    }
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext
  AppContainer.addSampleData(modelContext)

  let workoutFetchDescriptor = FetchDescriptor<Workout>()
  let workouts = try! modelContext.fetch(workoutFetchDescriptor)
  let sampleWorkout = workouts.first ?? Workout(date: Date())

  return NavigationStack {
    WorkoutDetailView(workout: sampleWorkout)
      .modelContainer(container)
  }
}
