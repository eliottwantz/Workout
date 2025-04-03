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

  init(exercise: Exercise) {
    self.exercise = exercise
    self._restTime = State(initialValue: exercise.restTime)
  }

  var body: some View {
    List {
      Section {
        if let definition = exercise.definition {
          Text(definition.name)
            .font(.title)
            .fontWeight(.bold)
        } else {
          Text("Unknown Exercise")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
        }

        Button(action: {
          showingRestTimePicker = true
        }) {
          HStack {
            Text("Rest Time")
            Spacer()
            Text(formatRestTime(restTime))
              .foregroundColor(.secondary)
          }
        }
        .sheet(isPresented: $showingRestTimePicker) {
          RestTimePickerView(restTime: $restTime) {
            exercise.restTime = restTime
            try? modelContext.save()
          }
          .presentationDetents([.medium])
        }
      }

      Section("Sets") {
        if let sets = exercise.orderedSets, !sets.isEmpty {
          ForEach(exercise.sets) { set in
            SetRowView(set: set)
          }
          .onDelete(perform: deleteSets)
          .onMove(perform: moveSets)
        } else {
          Text("No sets added yet")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
      }

      Section {
        HStack {
          Text("New Set")
            .font(.headline)

          Spacer()

          Stepper("\(newReps) reps", value: $newReps, in: 1...100)
        }

        HStack {
          Text("Weight")

          Spacer()

          TextField("Weight", value: $newWeight, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)

          Text("lbs")
        }

        Button(action: addNewSet) {
          Label("Add Set", systemImage: "plus")
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.bordered)
      }
    }
    .navigationTitle("Exercise Detail")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: {
          isEditingMode.toggle()
        }) {
          Text(isEditingMode ? "Done" : "Edit")
        }
      }
    }
    .environment(\.editMode, .constant(isEditingMode ? .active : .inactive))
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

struct RestTimePickerView: View {
  @Binding var restTime: Int
  @Environment(\.dismiss) private var dismiss
  var onSave: () -> Void

  private let restTimeOptions = [30, 45, 60, 90, 120, 180, 240, 300]

  var body: some View {
    NavigationStack {
      List {
        ForEach(restTimeOptions, id: \.self) { seconds in
          Button(action: {
            restTime = seconds
            onSave()
            dismiss()
          }) {
            HStack {
              Text(formatRestTime(seconds))
              Spacer()
              if restTime == seconds {
                Image(systemName: "checkmark")
                  .foregroundColor(.blue)
              }
            }
          }
          .foregroundColor(.primary)
        }

        Section("Custom") {
          Stepper(value: $restTime, in: 5...600, step: 5) {
            HStack {
              Text("Rest Time")
              Spacer()
              Text(formatRestTime(restTime))
                .foregroundColor(.secondary)
            }
          }

          Button("Save") {
            onSave()
            dismiss()
          }
          .buttonStyle(.bordered)
          .frame(maxWidth: .infinity, alignment: .center)
        }
      }
      .navigationTitle("Rest Time")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
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
