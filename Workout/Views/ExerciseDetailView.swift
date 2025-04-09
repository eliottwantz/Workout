import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var exercise: Exercise

  @State private var isEditingMode = false
  @State private var restTime: Int
  @State private var editMode = EditMode.inactive
  @AppStorage("displayWeightInLbs") private var displayWeightInLbs: Bool = false

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

      if exercise.containingSuperset == nil {
        Section("Rest Time") {
          RestTimePicker(exercise: exercise)
        }
      }

      if let sets = exercise.orderedSets, !sets.isEmpty {
        Section("Sets") {
          // Table header
          HStack {
            Text("#")
              .font(.headline)
              .frame(width: 40, alignment: .leading)

            Text("Reps")
              .font(.headline)
              .frame(maxWidth: .infinity, alignment: .center)

            HStack(alignment: .bottom, spacing: 6) {
              Text("Weight")
                .font(.headline)
              Text(displayWeightInLbs ? "(lbs)" : "(kg)")
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
          }
          .padding(.leading, 6)

          ForEach(exercise.sets) { set in
            EditableSetRowView(set: set, displayWeightInLbs: displayWeightInLbs)
              .frame(minHeight: 50)
          }
          .onDelete(perform: deleteSets)
          .onMove(perform: moveSets)

          Button {
            addSet()
          } label: {
            Label("Add Set", systemImage: "plus")
          }
          .frame(minHeight: 40)
        }
      }
    }
    .overlay {
      if exercise.sets.isEmpty {
        ContentUnavailableView {
          Label("No sets", systemImage: "dumbbell.fill")
        } actions: {
          Button {
            addSet()
          } label: {
            Label("Add Set", systemImage: "plus")
          }
        }
      }
    }
    .navigationTitle(exercise.definition?.name ?? "Exercise Detail")
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          addSet()
        } label: {
          Label("Add Set", systemImage: "plus")
        }
        EditButton()
      }
    }
    .environment(\.editMode, $editMode)
    .scrollDismissesKeyboard(.immediately)
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

  private func addSet() {
    if let lastSet = exercise.sets.last {
      let set = SetEntry(reps: lastSet.reps, weight: lastSet.weight)
      exercise.addSet(set)
      try? modelContext.save()
    } else {
      let set = SetEntry(reps: 10, weight: 0.0)
      exercise.addSet(set)
      try? modelContext.save()
    }
  }

  private func deleteSets(at offsets: IndexSet) {
    for index in offsets {
      if let sets = exercise.orderedSets {
        let setToDelete = exercise.sets[index]
        if let setIndex = sets.firstIndex(where: { $0.persistentModelID == setToDelete.persistentModelID }) {
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

private struct EditableSetRowView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var set: SetEntry

  @State private var reps: Int
  @State private var weight: Double
  @AppStorage("displayWeightInLbs") private var displayWeightInLbs: Bool = false

  init(set: SetEntry, displayWeightInLbs: Bool) {
    self.set = set
    self._reps = State(initialValue: set.reps)
    self._weight = State(initialValue: displayWeightInLbs ? set.weight * 2.20462 : set.weight)
    self.displayWeightInLbs = displayWeightInLbs
  }

  var body: some View {
    HStack {
      ZStack {
        Circle()
          .fill(Color.gray.opacity(0.2))
          .frame(width: 24, height: 24)

        Text("\(set.order + 1)")
          .font(.system(.callout, weight: .medium))
      }
      .frame(width: 40, alignment: .leading)

      // Reps column - editable
      RepsInputField(reps: $set.reps)

      // Weight column - editable
      WeightInputField(weight: $weight, displayWeightInLbs: displayWeightInLbs)
        .onChange(of: weight) { newValue in
          set.weight = displayWeightInLbs ? newValue / 2.20462 : newValue
          try? modelContext.save()
        }
    }
    .padding(.vertical, 4)
  }
}

private struct RestTimePicker: View {
  @Bindable var exercise: Exercise

  @State private var showingRestTimePicker = false

  var body: some View {
    Button {
      showingRestTimePicker = true
    } label: {
      Stepper(value: $exercise.restTime, in: 5...600, step: 5) {
        HStack {
          Text(exercise.restTime.formattedRestTime)
            .frame(minWidth: 60, alignment: .center)
            .font(.body.monospacedDigit())
            .foregroundStyle(Color.primary)
            .contentTransition(.numericText())
            .animation(.snappy, value: exercise.restTime)
        }
      }
      .sensoryFeedback(trigger: exercise.restTime) { oldValue, newValue in
        return newValue < oldValue ? .decrease : .increase
      }
    }
    .sheet(isPresented: $showingRestTimePicker) {
      RestTimePickerView(restTime: $exercise.restTime)
        .presentationDetents([.fraction(0.7)])
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

private struct WeightInputField: View {
  @Binding var weight: Double
  @FocusState var isFocused: Bool
  var displayWeightInLbs: Bool

  var body: some View {
    TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
      .keyboardType(.decimalPad)
      .multilineTextAlignment(.center)
      .textFieldStyle(.roundedBorder)
      .font(.body.monospacedDigit())
      .frame(maxWidth: .infinity)
      .focused($isFocused)
      .onChange(of: isFocused) { old, new in
        if new == true {
          // Use UIKit to select all text after asynchronously after input is focused
          DispatchQueue.main.async {
            UIApplication.shared.sendAction(
              #selector(UIResponder.selectAll(_:)),
              to: nil,
              from: nil,
              for: nil
            )
          }
        }
      }
  }
}

private struct RepsInputField: View {
  @Binding var reps: Int
  @FocusState var isFocused: Bool

  var body: some View {
    TextField("Reps", value: $reps, format: .number)
      .keyboardType(.numberPad)
      .multilineTextAlignment(.center)
      .textFieldStyle(.roundedBorder)
      .font(.body.monospacedDigit())
      .frame(maxWidth: .infinity)
      .focused($isFocused)
      .onChange(of: isFocused) { old, new in
        if new == true {
          // Use UIKit to select all text after asynchronously after input is focused
          DispatchQueue.main.async {
            UIApplication.shared.sendAction(
              #selector(UIResponder.selectAll(_:)),
              to: nil,
              from: nil,
              for: nil
            )
          }
        }
      }
  }
}

#Preview {
  let container = AppContainer.preview.modelContainer

  // Adding some sample data for the preview
  let modelContext = container.mainContext

  // Create sample data
  let workout = Workout(date: Date())
  let exerciseDefinition = ExerciseDefinition(name: "Bench Press")
  modelContext.insert(exerciseDefinition)
  modelContext.insert(workout)

  let exercise = Exercise(definition: exerciseDefinition, workout: workout, restTime: 90)

  let workoutItem = WorkoutItem(exercise: exercise)
  workout.addItem(workoutItem)

  // Add some sets
  let set1 = SetEntry(reps: 8, weight: 135)
  let set2 = SetEntry(reps: 8, weight: 145)
  let set3 = SetEntry(reps: 6, weight: 155)

  exercise.addSet(set1)
  exercise.addSet(set2)
  exercise.addSet(set3)

  try? modelContext.save()

  return NavigationStack {
    ExerciseDetailView(exercise: exercise)
      .modelContainer(container)
  }
}
