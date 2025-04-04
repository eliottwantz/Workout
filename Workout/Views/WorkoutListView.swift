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

  @State private var showingNewWorkoutAlert = false
  @State private var path = NavigationPath()

  var body: some View {
    NavigationStack(path: $path) {
      List {
        ForEach(workouts) { workout in
          NavigationLink(value: workout) {
            WorkoutRowView(workout: workout)
          }
        }
        .onDelete(perform: deleteWorkouts)
      }
      .overlay {
        if workouts.isEmpty {
          ContentUnavailableView {
            Label("No workouts", systemImage: "figure.strengthtraining.traditional")
          } actions: {
            Button("Add Workout") {
              createNewWorkout()
            }
          }
        }
      }
      .navigationTitle("Workout Log")
      .navigationDestination(for: Workout.self) { workout in
        WorkoutDetailView(workout: workout)
      }
      .toolbar {
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
    let newWorkout = Workout(date: Date())
    modelContext.insert(newWorkout)
    try? modelContext.save()
    path.append(newWorkout)
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

      Text("^[\(workout.items.count) exercise](inflect: true)")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  WorkoutListView()
    .modelContainer(AppContainer.preview.modelContainer)
}
