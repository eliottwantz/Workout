//
//  WorkoutDetailView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
  @AppStorage(AllowMultipleWorkoutsPerDayKey) var allowMultipleWorkoutsPerDay: Bool = false
  @Environment(\.modelContext) private var modelContext
  @Environment(\.userAccentColor) private var userAccentColor
  @Environment(\.startedWorkoutViewModel) private var startedWorkoutViewModel
  @Bindable var workout: Workout
  @Binding var navigationPath: NavigationPath

  @State private var editMode = EditMode.inactive
  @State private var showingAddExerciseView = false
  @State private var showingCopyToTodayAlert = false
  @State private var showingStartedWorkoutView = false
  @State private var showingMultipleWorkoutAlert = false

  // For previews
  init(workout: Workout) {
    self.workout = workout
    self._navigationPath = .constant(NavigationPath())
  }

  // For actual use
  init(workout: Workout, navigationPath: Binding<NavigationPath>) {
    self.workout = workout
    self._navigationPath = navigationPath
  }

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
    .safeAreaInset(edge: .bottom) {
      if !workout.orderedItems.isEmpty
        && !workout.orderedItems.flatMap({ item in
          if let exercise = item.exercise {
            return exercise.orderedSets
          }
          if let superset = item.superset {
            return superset.orderedExercises.flatMap({ $0.orderedSets })
          }
          return []
        }).isEmpty && startedWorkoutViewModel.workout == nil
      {
        Button {
          startedWorkoutViewModel.start(workout: workout)
        } label: {
          Text("Start Workout")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(userAccentColor)
            .foregroundStyle(userAccentColor.contrastColor)
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
      }
    }
    .navigationTitle(String(localized: workout.smartFormattedDate))
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        if !Calendar.current.isDateInToday(workout.date) {
          Button {
            showingCopyToTodayAlert = true
          } label: {
            Label("Copy to Today", systemImage: "doc.on.doc")
          }
        }

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
        AddExerciseView(workout: workout)
      }
    }
    .alert("Copy Workout to Today", isPresented: $showingCopyToTodayAlert) {
      Button("Copy", role: .none) {
        copyWorkoutToToday()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Do you want to copy this workout to today?")
    }
    .alert("Can't add another workout for today", isPresented: $showingMultipleWorkoutAlert) {
      Button("Settings") {
        navigationPath.append("settings")
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(
        "Enable 'Allow multiple workouts per day' in settings to create more than one workout per day."
      )
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

    startedWorkoutViewModel.updateLiveActivity()
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

    startedWorkoutViewModel.updateLiveActivity()
  }

  private func copyWorkoutToToday() {

    var descriptor = FetchDescriptor<Workout>(
      sortBy: [.init(\Workout.date, order: .reverse)]
    )
    descriptor.fetchLimit = 1

    do {
      let allWorkouts = try modelContext.fetch(descriptor)
      let hasWorkoutForToday = allWorkouts.contains { Calendar.current.isDateInToday($0.date) }

      if hasWorkoutForToday && !allowMultipleWorkoutsPerDay {
        // Show alert if multiple workouts per day are not allowed
        showingCopyToTodayAlert = false
        showingMultipleWorkoutAlert = true
        return
      }
    } catch {
      print("Failed to fetch workouts: \(error)")
    }

    // Create a new workout with today's date
    let todayWorkout = Workout(date: Date())

    // Copy all workout items from the source workout
    for item in workout.orderedItems {
      if let exercise = item.exercise {
        // Create a new exercise
        let newExercise = Exercise(
          definition: exercise.definition!,
          workout: todayWorkout,
          restTime: exercise.restTime,
          notes: exercise.notes
        )

        // Copy all sets from the original exercise
        for setEntry in exercise.orderedSets {
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
        let newSuperset = Superset(notes: superset.notes, restTime: superset.restTime)

        // Copy all exercises in the superset
        for exercise in superset.orderedExercises {
          let newExercise = Exercise(
            definition: exercise.definition!,
            workout: todayWorkout,
            restTime: exercise.restTime,
            orderWithinSuperset: exercise.orderWithinSuperset,
            notes: exercise.notes
          )

          // Copy all sets from the original exercise
          for setEntry in exercise.orderedSets {
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

    // Navigate back to home screen
    navigationPath.removeLast(navigationPath.count)
  }
}

struct WorkoutItemRowView: View {
  @Bindable var workoutItem: WorkoutItem

  var body: some View {
    if let exercise = workoutItem.exercise, let definition = exercise.definition {
      NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
        HStack {
          VStack(alignment: .leading, spacing: 8) {
            Text(definition.name)
              .font(.headline)

            if let notes = exercise.notes, !notes.isEmpty {
              Text(notes)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          Spacer()

          Text("\(exercise.orderedSets.count) sets")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }
    } else if let superset = workoutItem.superset {
      NavigationLink(destination: SupersetDetailView(superset: superset)) {
        HStack {
          VStack(alignment: .leading, spacing: 8) {
            Text("Superset")
              .font(.headline)
            VStack(alignment: .leading) {
              ForEach(superset.orderedExercises) { exercise in
                if let definition = exercise.definition {
                  Text("  \(definition.name)")
                    .font(.subheadline)
                }
              }
            }

            if let notes = superset.notes, !notes.isEmpty {
              Text(notes)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          Spacer()

          Text("\(superset.orderedExercises.flatMap {$0.orderedSets}.count) sets")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }
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
    WorkoutDetailView(workout: sampleWorkout)
      .modelContainer(container)
  }
}
