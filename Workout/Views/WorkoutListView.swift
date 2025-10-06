//
//  WorkoutListView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct WorkoutListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
  @AppStorage(AllowMultipleWorkoutsPerDayKey) private var allowMultipleWorkoutsPerDay: Bool = false

  @State private var showingNewWorkoutAlert = false
  @State private var showingMultipleWorkoutAlert = false
  @State private var showingCopyToTodayAlert = false
  @State private var workoutToCopy: Workout?
  @Environment(\.router) private var router

  var body: some View {
    @Bindable var router = router
    NavigationStack(path: $router.workouts.path) {
      List {
        if !workouts.isEmpty {
          Button {
            createNewWorkout()
          } label: {
            Label("Add Workout", systemImage: "plus")
          }
          .frame(minHeight: 40)
          ForEach(workouts) { workout in
            NavigationLink(value: WorkoutsRouter.Route.workoutDetail(workout: workout)) {
              WorkoutRowView(workout: workout)
                .frame(minHeight: 60)
            }
            .contextMenu {
              if !Calendar.current.isDateInToday(workout.date) {
                Button {
                  workoutToCopy = workout
                  showingCopyToTodayAlert = true
                } label: {
                  Label("Copy to Today", systemImage: "doc.on.doc")
                }
              }
            }
            .swipeActions(edge: .leading) {
              if !Calendar.current.isDateInToday(workout.date) {
                Button {
                  workoutToCopy = workout
                  showingCopyToTodayAlert = true
                } label: {
                  Label("Copy", systemImage: "doc.on.doc")
                }
                .tint(.blue)
              }
            }
          }
          .onDelete(perform: deleteWorkouts)
        }
      }
      .overlay {
        if workouts.isEmpty {
          ContentUnavailableView {
            Label("No workouts", systemImage: "tray")
          } actions: {
            Button("Add Workout", systemImage: "plus") {
              createNewWorkout()
            }
          }
        }
      }
      .navigationTitle("Workout Log")
      .alert("Can't add another workout for today", isPresented: $showingMultipleWorkoutAlert) {
        Button("Settings") {
          router.workouts.push(to: .settings)
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Enable 'Allow multiple workouts per day' in settings to create more than one workout per day."
        )
      }
      .alert("Copy Workout to Today", isPresented: $showingCopyToTodayAlert) {
        Button("Copy", role: .none) {
          if let workout = workoutToCopy {
            copyWorkoutToToday(workout)
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Do you want to copy this workout to today?")
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            router.workouts.push(to: .settings)
          } label: {
            Label("Settings", systemImage: "gear")
          }
        }

        ToolbarItemGroup(placement: .primaryAction) {
          EditButton()
          Button {
            createNewWorkout()
          } label: {
            Label("Add Workout", systemImage: "plus")
          }
        }
      }
      .navigationDestination(for: WorkoutsRouter.Route.self) { route in
        switch route {
        case .workoutDetail(let workout):
          WorkoutDetailView(workout: workout)
        case .settings:
          SettingsView()
        case .exerciseDetail(let exercise):
          ExerciseDetailView(exercise: exercise)
        default:
          WorkoutListView()
        }
      }
    }
  }

  private func createNewWorkout() {
    // Check if workout already exists for today
    let calendar = Calendar.current
    let hasWorkoutForToday = workouts.contains { calendar.isDateInToday($0.date) }

    if hasWorkoutForToday && !allowMultipleWorkoutsPerDay {
      // Show alert if multiple workouts per day are not allowed
      showingMultipleWorkoutAlert = true
    } else {
      // Create new workout
      let newWorkout = Workout(date: Date())
      modelContext.insert(newWorkout)
      try? modelContext.save()
      router.workouts.push(to: .workoutDetail(workout: newWorkout))
    }
  }

  private func deleteWorkouts(offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(workouts[index])
    }
    try? modelContext.save()
  }

  private func copyWorkoutToToday(_ workout: Workout) {
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

    // Clear the workout to copy reference
    workoutToCopy = nil
  }
}

struct WorkoutRowView: View {
  let workout: Workout

  var body: some View {
    VStack(alignment: .leading) {
      Text(workout.formattedDate)
        .font(.headline)

      if let name = workout.name {
        Text("\(workout.orderedItems.count) exercises - \(name)")
          .font(.subheadline)
          .foregroundColor(.secondary)
      } else {

        Text("\(workout.orderedItems.count) exercises")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  WorkoutListView()
    .modelContainer(AppContainer.preview.modelContainer)
}
