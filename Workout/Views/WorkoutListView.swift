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
    
    var body: some View {
        List {
            ForEach(workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutRowView(workout: workout)
                }
            }
            .onDelete(perform: deleteWorkouts)
        }
        .navigationTitle("Workout Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    createNewWorkout()
                }) {
                    Label("Add Workout", systemImage: "plus")
                }
            }
        }
    }
    
    private func createNewWorkout() {
        let newWorkout = Workout(date: Date())
        modelContext.insert(newWorkout)
        try? modelContext.save()
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
            Text(formattedDate)
                .font(.headline)
            
            Text("\(workout.items.count) exercise(s)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let calendar = Calendar.current
        if calendar.isDateInToday(workout.date) {
            return "Today"
        } else if calendar.isDateInYesterday(workout.date) {
            return "Yesterday"
        } else {
            return formatter.string(from: workout.date)
        }
    }
}

#Preview {
    WorkoutListView()
        .modelContainer(AppContainer.preview.modelContainer)
}