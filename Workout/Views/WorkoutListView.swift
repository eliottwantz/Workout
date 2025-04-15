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
  @State private var path = NavigationPath()

  var body: some View {
    NavigationStack(path: $path) {
      List {
        if !workouts.isEmpty {
          Section("Workouts") {
            Button {
              createNewWorkout()
            } label: {
              Label("Add Workout", systemImage: "plus")
            }
            .frame(minHeight: 40)
            ForEach(workouts) { workout in
              NavigationLink(value: workout) {
                WorkoutRowView(workout: workout)
                  .frame(minHeight: 60)
              }
            }
            .onDelete(perform: deleteWorkouts)
          }
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
      .navigationDestination(for: Workout.self) { workout in
        WorkoutDetailView(workout: workout, navigationPath: $path)
      }
      .navigationDestination(for: String.self) { destination in
        if destination == "settings" {
          SettingsView()
        }
      }
      .alert("Can't add another workout for today", isPresented: $showingMultipleWorkoutAlert) {
        Button("Settings") {
          path.append("settings")
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Enable 'Allow multiple workouts per day' in settings to create more than one workout per day."
        )
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
            createNewWorkout()
          } label: {
            Label("Add Workout", systemImage: "plus")
          }
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
      path.append(newWorkout)
    }
  }

  private func deleteWorkouts(offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(workouts[index])
    }
    try? modelContext.save()
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
