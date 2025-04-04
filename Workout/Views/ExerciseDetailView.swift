//
//  ExerciseDetailView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var exercise: Exercise

  @State private var isEditingMode = false
  @State private var newReps = 8
  @State private var newWeight = 0.0
  @State private var restTime: Int
  @State private var showingRestTimePicker = false
  @State private var editMode = EditMode.inactive

  init(exercise: Exercise) {
    self.exercise = exercise
    self._restTime = State(initialValue: exercise.restTime)
  }

  var body: some View {
    List {
      if let notes = exercise.notes, !notes.isEmpty {
        Section("Notes") {
          Text(notes)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
      }

      Section("Rest time") {
        RestTimePicker(exercise: exercise)
      }

      Section("Sets") {
        if let sets = exercise.orderedSets, !sets.isEmpty {
          ForEach(exercise.sets) { set in
            SetRowView(set: set)
          }
          .onDelete(perform: deleteSets)
          .onMove(perform: moveSets)
        } else {
          ContentUnavailableView {
            Label("No sets", systemImage: "dumbbell.fill")
          }
        }
      }

      Section("New set") {

        Stepper("^[\(newReps) rep](inflect: true)", value: $newReps, in: 1...100)

        HStack {
          Text("Weight")

          Spacer()

          TextField("Weight", value: $newWeight, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)

          Text("lbs")
        }

        Button {
          addNewSet()
        } label: {
          Label("Add Set", systemImage: "plus")
            .frame(maxWidth: .infinity, alignment: .center)
        }
      }

    }
    .navigationTitle(exercise.definition?.name ?? "Exercise Detail")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        EditButton()
      }
    }
    .environment(\.editMode, $editMode)
  }

  private func formatRestTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60

    if minutes > 0 {
      return "\(minutes)m \(remainingSeconds)s"
    } else {
      return "\(seconds)s"
    }
  }

  private func addNewSet() {
    let set = SetEntry(reps: newReps, weight: newWeight)
    exercise.addSet(set)

    // Reset inputs
    newWeight = exercise.sets.last?.weight ?? 0.0

    try? modelContext.save()
  }

  private func deleteSets(at offsets: IndexSet) {
    for index in offsets {
      if let sets = exercise.orderedSets {
        let setToDelete = exercise.sets[index]
        if let setIndex = sets.firstIndex(where: { $0.id == setToDelete.id }) {
          exercise.orderedSets?.remove(at: setIndex)
          modelContext.delete(setToDelete)
        }
      }
    }

    // Update order of remaining items
    for (index, set) in exercise.sets.enumerated() {
      set.order = index
    }

    try? modelContext.save()
  }

  private func moveSets(from source: IndexSet, to destination: Int) {
    var sets = exercise.sets
    sets.move(fromOffsets: source, toOffset: destination)

    // Update the order property for all sets
    for (index, set) in sets.enumerated() {
      set.order = index
    }

    try? modelContext.save()
  }
}

struct SetRowView: View {
  let set: SetEntry

  var body: some View {
    HStack {
      Text("Set \(set.order + 1)")
        .font(.headline)

      Spacer()

      Text("\(set.reps) reps at \(String(format: "%.1f", set.weight)) lbs")
        .font(.subheadline)
    }
  }
}

private struct RestTimePicker: View {
  @Bindable var exercise: Exercise

  var body: some View {
    Stepper(value: $exercise.restTime, in: 5...600, step: 5) {
      HStack {
        Text(formatRestTime(exercise.restTime))
          .frame(minWidth: 60, alignment: .center)
          .font(.body.monospacedDigit())
          .contentTransition(.numericText())
          .animation(.snappy, value: exercise.restTime)
      }
    }
  }

  private func incrementRestTime() {
    withAnimation {
      exercise.restTime += 15
    }
  }

  private func decrementRestTime() {
    withAnimation {
      // Ensure we don't go below 0 seconds
      exercise.restTime = max(0, exercise.restTime - 15)
    }
  }
}

private func formatRestTime(_ seconds: Int) -> String {
  let minutes = seconds / 60
  let remainingSeconds = seconds % 60

  if minutes > 0 {
    return "\(minutes)m \(remainingSeconds)s"
  } else {
    return "\(seconds)s"
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext
  let exerciseDefinition = ExerciseDefinition(name: "Bench Press")
  modelContext.insert(exerciseDefinition)

  let exercise = Exercise(definition: exerciseDefinition, restTime: 90)
  exercise.addSet(SetEntry(reps: 8, weight: 135.0))
  exercise.addSet(SetEntry(reps: 8, weight: 135.0))
  exercise.addSet(SetEntry(reps: 6, weight: 145.0))

  modelContext.insert(exercise)

  return NavigationStack {
    ExerciseDetailView(exercise: exercise)
      .modelContainer(container)
  }
}
