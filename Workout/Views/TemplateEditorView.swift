//
//  TemplateEditorView.swift
//  Workout
//
//  Created by Codex on 2025-10-29.
//

import SwiftData
import SwiftUI

struct TemplateEditorView: View {
  @Environment(\.modelContext) private var modelContext

  @Bindable var template: WorkoutTemplate

  @State private var notes: String
  @State private var editMode = EditMode.inactive
  @State private var showingAddExerciseView = false

  init(template: WorkoutTemplate) {
    self.template = template
    _notes = State(initialValue: template.notes ?? "")
  }

  var body: some View {
    Form {
      Section("Template Info") {
        LabeledContent("Template name") {
          TextField("Template name", text: $template.name)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.tint)
        }
        .onChange(of: template.name) { _, _ in
          template.refreshUpdatedAt()
        }

        LabeledContent("Favorite") {
          HStack {
            Spacer()
            EditableFavoriteButton(isSet: $template.isFavorite)
          }
        }
        .onChange(of: template.isFavorite) { _, _ in
          template.refreshUpdatedAt()
        }
      }

      Section("Notes") {
        TextField("Optional notes", text: $notes, axis: .vertical)
          .onChange(of: notes) { _, _ in
            template.notes = notes
            template.refreshUpdatedAt()
          }
      }

      Section("Exercises") {
        if template.orderedItems.isEmpty {
          Text("No exercises yet. Use the button below to add some.")
            .foregroundStyle(.secondary)
        }

        ForEach(template.orderedItems) { item in
          TemplateWorkoutItemRowView(workoutItem: item)
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
    .navigationTitle(template.name)
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
    .sheet(isPresented: $showingAddExerciseView, onDismiss: markTemplateUpdated) {
      NavigationStack {
        TemplateAddExerciseView(template: template)
      }
    }
  }

  private func moveItems(from source: IndexSet, to destination: Int) {
    withAnimation {
      var items = template.orderedItems
      items.move(fromOffsets: source, toOffset: destination)
      for (index, item) in items.enumerated() {
        item.order = index
      }
      try? modelContext.save()
      markTemplateUpdated()
    }
  }

  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(template.orderedItems[index])
      }

      for (index, item) in template.orderedItems.enumerated() {
        item.order = index
      }

      try? modelContext.save()
      markTemplateUpdated()
    }
  }

  private func markTemplateUpdated() {
    template.refreshUpdatedAt()
    try? modelContext.save()
  }
}

private struct TemplateWorkoutItemRowView: View {
  @Bindable var workoutItem: WorkoutTemplateItem

  var body: some View {
    if let exercise = workoutItem.exercise, let definition = exercise.definition {
      NavigationLink {
        TemplateExerciseDetailView(exercise: exercise)
      } label: {
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
      NavigationLink {
        TemplateSupersetDetailView(superset: superset)
      } label: {
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

          Text("\(superset.orderedExercises.flatMap { $0.orderedSets }.count) sets")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }
    }
  }
}

private struct TemplateAddExerciseView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @Bindable var template: WorkoutTemplate

  @State private var selectedExercises = Set<PersistentIdentifier>()
  @State private var selectedOption = AddOption.individual

  enum AddOption {
    case individual
    case superset
  }

  var body: some View {
    VStack {
      Picker("Add Option", selection: $selectedOption) {
        Text("Individual Exercises").tag(AddOption.individual)
        Text("Superset").tag(AddOption.superset)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)

      ExerciseSelectionView(
        selectedExercises: $selectedExercises,
        headerText: selectedOption == .individual
          ? "Select exercises to add to your template"
          : "Select exercises to include in your superset",
        disabled: selectedOption == .individual
          ? selectedExercises.isEmpty : selectedExercises.count < 2,
        confirmAction: {
          addSelectedExercisesToTemplate()
          dismiss()
        }
      )
    }
    .navigationTitle("Add Template Exercise")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
    }
  }

  private func addSelectedExercisesToTemplate() {
    if selectedExercises.isEmpty { return }

    switch selectedOption {
    case .individual:
      for definitionID in selectedExercises {
        guard
          let definition = try? modelContext.fetch(
            FetchDescriptor<ExerciseDefinition>(
              predicate: #Predicate { $0.persistentModelID == definitionID }
            )
          ).first
        else { continue }

        let previousExercise = AppContainer.findMostRecentExercise(
          for: definitionID,
          currentWorkoutID: UUID(),
          modelContext: modelContext
        )

        let templateExercise = WorkoutTemplateExercise(
          definition: definition,
          restTime: previousExercise?.restTime ?? 120,
          notes: previousExercise?.notes
        )

        if let previousExercise {
          for setEntry in previousExercise.orderedSets {
            templateExercise.addSet(
              WorkoutTemplateSet(
                order: setEntry.order, reps: setEntry.reps, weight: setEntry.weight)
            )
          }
        }

        let item = WorkoutTemplateItem(exercise: templateExercise)
        template.addItem(item)
      }

    case .superset:
      let superset = WorkoutTemplateSuperset()
      for (index, definitionID) in selectedExercises.enumerated() {
        guard
          let definition = try? modelContext.fetch(
            FetchDescriptor<ExerciseDefinition>(
              predicate: #Predicate { $0.persistentModelID == definitionID }
            )
          ).first
        else { continue }

        let previousExercise = AppContainer.findMostRecentExercise(
          for: definitionID,
          currentWorkoutID: UUID(),
          modelContext: modelContext
        )

        let templateExercise = WorkoutTemplateExercise(
          definition: definition,
          restTime: previousExercise?.restTime ?? 120,
          orderWithinSuperset: index,
          notes: previousExercise?.notes
        )

        if let previousExercise {
          for setEntry in previousExercise.orderedSets {
            templateExercise.addSet(
              WorkoutTemplateSet(
                order: setEntry.order, reps: setEntry.reps, weight: setEntry.weight)
            )
          }
        }

        superset.addExercise(templateExercise)
      }

      let item = WorkoutTemplateItem(superset: superset)
      template.addItem(item)
    }

    template.refreshUpdatedAt()
    try? modelContext.save()
  }
}

private struct TemplateExerciseDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var exercise: WorkoutTemplateExercise

  @State private var editMode = EditMode.inactive
  @AppStorage(DisplayWeightInLbsKey) private var displayWeightInLbs: Bool = false
  @State private var restTime: Int
  @State private var notes: String
  @State private var isEditingNotes = false

  init(exercise: WorkoutTemplateExercise) {
    self.exercise = exercise
    _restTime = State(initialValue: exercise.restTime)
    _notes = State(initialValue: exercise.notes ?? "")
  }

  var body: some View {
    List {
      Section("Notes") {
        if let existingNotes = exercise.notes, !existingNotes.isEmpty {
          Text(existingNotes)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
          Text("No notes yet")
            .foregroundStyle(.secondary)
        }
      }

      Section("Rest Time") {
        //        Stepper(value: $restTime, in: 0...900, step: 5) {
        //          Text("Rest: \(formatRestTime(restTime))")
        //        }
        //        .onChange(of: restTime) { _, newValue in
        //          exercise.restTime = newValue
        //          markTemplateChanged()
        //        }
        RestTimePicker(exercise: exercise)
      }

      Section("Sets") {
        HStack {
          Text("#")
            .font(.headline)
            .frame(width: 40, alignment: .leading)

          Text("Reps")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .center)

          HStack(spacing: 6) {
            Text("Weight")
              .font(.headline)
            Text(displayWeightInLbs ? "(lbs)" : "(kg)")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.leading, 6)

        ForEach(exercise.orderedSets) { set in
          TemplateEditableSetRowView(set: set, displayWeightInLbs: displayWeightInLbs) {
            markTemplateChanged()
          }
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
    .navigationTitle(exercise.definition?.name ?? "Exercise")
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        EditButton()
        Button {
          addSet()
        } label: {
          Label("Add Set", systemImage: "plus")
        }
        Button {
          notes = exercise.notes ?? ""
          isEditingNotes = true
        } label: {
          Label("Edit Notes", systemImage: "pencil")
        }
      }
    }
    .environment(\.editMode, $editMode)
    .sheet(isPresented: $isEditingNotes) {
      TemplateEditNotesSheet(
        notes: $notes,
        onSave: {
          exercise.notes = notes.nilIfEmpty()
          markTemplateChanged()
          isEditingNotes = false
        },
        onCancel: {
          isEditingNotes = false
        }
      )
    }
  }

  private func addSet() {
    if let lastSet = exercise.orderedSets.last {
      let set = WorkoutTemplateSet(
        order: lastSet.order + 1, reps: lastSet.reps, weight: lastSet.weight)
      exercise.addSet(set)
    } else {
      let set = WorkoutTemplateSet(order: 0, reps: 10, weight: 20)
      exercise.addSet(set)
    }
    markTemplateChanged()
  }

  private func deleteSets(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        if let set = exercise.orderedSets[safe: index] {
          modelContext.delete(set)
        }
      }

      for (index, set) in exercise.orderedSets.enumerated() {
        set.order = index
      }

      markTemplateChanged()
    }
  }

  private func moveSets(from source: IndexSet, to destination: Int) {
    withAnimation {
      var sets = exercise.orderedSets
      sets.move(fromOffsets: source, toOffset: destination)
      for (index, set) in sets.enumerated() {
        set.order = index
      }
      markTemplateChanged()
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

  private func markTemplateChanged() {
    exercise.templateItem?.template?.refreshUpdatedAt()
    try? modelContext.save()
  }
}

private struct RestTimePicker: View {
  @Bindable var exercise: WorkoutTemplateExercise

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

private struct TemplateEditableSetRowView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var set: WorkoutTemplateSet
  let displayWeightInLbs: Bool
  @State private var weight: Double
  var onChange: () -> Void

  init(set: WorkoutTemplateSet, displayWeightInLbs: Bool, onChange: @escaping () -> Void) {
    self.set = set
    self.displayWeightInLbs = displayWeightInLbs
    _weight = State(initialValue: displayWeightInLbs ? set.weight * 2.20462 : set.weight)
    self.onChange = onChange
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

      RepsInputField(reps: $set.reps)

      WeightInputField(weight: $weight)
        .onChange(of: weight) { _, newValue in
          set.weight = displayWeightInLbs ? newValue / 2.20462 : newValue
        }
    }
    .padding(.vertical, 4)
  }
}

private struct TemplateEditNotesSheet: View {
  @Binding var notes: String
  var onSave: () -> Void
  var onCancel: () -> Void

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        TextEditor(text: $notes)
          .frame(minHeight: 180)
          .scrollContentBackground(.hidden)
          .padding()
      }
      .navigationTitle("Edit Notes")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave()
          }
          .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}

private struct TemplateSupersetDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var superset: WorkoutTemplateSuperset

  @State private var editMode = EditMode.inactive
  @State private var restTime: Int
  @State private var notes: String
  @State private var isEditingNotes = false
  @State private var showingAddExerciseSheet = false

  init(superset: WorkoutTemplateSuperset) {
    self.superset = superset
    _restTime = State(initialValue: superset.restTime)
    _notes = State(initialValue: superset.notes ?? "")
  }

  var body: some View {
    List {
      Section("Superset Info") {
        Stepper(value: $restTime, in: 0...900, step: 5) {
          Text("Rest: \(formatRestTime(restTime))")
        }
        .onChange(of: restTime) { _, newValue in
          superset.restTime = newValue
          markTemplateChanged()
        }

        Button {
          notes = superset.notes ?? ""
          isEditingNotes = true
        } label: {
          Label("Edit Notes", systemImage: "pencil")
        }
      }

      Section("Exercises") {
        ForEach(superset.orderedExercises) { exercise in
          NavigationLink {
            TemplateExerciseDetailView(exercise: exercise)
          } label: {
            VStack(alignment: .leading) {
              Text(exercise.definition?.name ?? "Exercise")
                .font(.headline)
              if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            .padding(.vertical, 4)
          }
        }
        .onDelete(perform: deleteExercises)
        .onMove(perform: moveExercises)

        Button {
          showingAddExerciseSheet = true
        } label: {
          Label("Add Exercise", systemImage: "plus")
        }
        .frame(minHeight: 40)
      }
    }
    .navigationTitle("Superset")
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        EditButton()
        Button {
          showingAddExerciseSheet = true
        } label: {
          Label("Add Exercise", systemImage: "plus")
        }
      }
    }
    .environment(\.editMode, $editMode)
    .sheet(isPresented: $isEditingNotes) {
      TemplateEditNotesSheet(
        notes: $notes,
        onSave: {
          superset.notes = notes.nilIfEmpty()
          markTemplateChanged()
          isEditingNotes = false
        },
        onCancel: {
          isEditingNotes = false
        }
      )
    }
    .sheet(isPresented: $showingAddExerciseSheet) {
      TemplateSupersetAddExerciseView(superset: superset)
    }
  }

  private func deleteExercises(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        if let exercise = superset.orderedExercises[safe: index] {
          modelContext.delete(exercise)
        }
      }

      for (index, exercise) in superset.orderedExercises.enumerated() {
        exercise.orderWithinSuperset = index
      }

      markTemplateChanged()
    }
  }

  private func moveExercises(from source: IndexSet, to destination: Int) {
    withAnimation {
      var exercises = superset.orderedExercises
      exercises.move(fromOffsets: source, toOffset: destination)
      for (index, exercise) in exercises.enumerated() {
        exercise.orderWithinSuperset = index
      }
      markTemplateChanged()
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

  private func markTemplateChanged() {
    superset.templateItem?.template?.refreshUpdatedAt()
    try? modelContext.save()
  }
}

private struct TemplateSupersetAddExerciseView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @Bindable var superset: WorkoutTemplateSuperset
  @State private var selectedExercises = Set<PersistentIdentifier>()

  var body: some View {
    NavigationStack {
      ExerciseSelectionView(
        selectedExercises: $selectedExercises,
        headerText: "Select exercises to add to this superset",
        disabled: selectedExercises.isEmpty,
        confirmAction: {
          addSelectedExercises()
          dismiss()
        }
      )
      .navigationTitle("Add Superset Exercise")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  private func addSelectedExercises() {
    let startingIndex = superset.orderedExercises.count

    for (offset, definitionID) in selectedExercises.enumerated() {
      guard
        let definition = try? modelContext.fetch(
          FetchDescriptor<ExerciseDefinition>(
            predicate: #Predicate { $0.persistentModelID == definitionID }
          )
        ).first
      else { continue }

      let previousExercise = AppContainer.findMostRecentExercise(
        for: definitionID,
        currentWorkoutID: UUID(),
        modelContext: modelContext
      )

      let templateExercise = WorkoutTemplateExercise(
        definition: definition,
        restTime: previousExercise?.restTime ?? 120,
        orderWithinSuperset: startingIndex + offset,
        notes: previousExercise?.notes
      )

      if let previousExercise {
        for setEntry in previousExercise.orderedSets {
          templateExercise.addSet(
            WorkoutTemplateSet(order: setEntry.order, reps: setEntry.reps, weight: setEntry.weight)
          )
        }
      }

      superset.addExercise(templateExercise)
    }
    markTemplateChanged()
  }

  private func markTemplateChanged() {
    superset.templateItem?.template?.refreshUpdatedAt()
    try? modelContext.save()
  }
}

extension String {
  fileprivate func nilIfEmpty() -> String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}

extension Array {
  fileprivate subscript(safe index: Int) -> Element? {
    guard indices.contains(index) else { return nil }
    return self[index]
  }
}

#Preview {
  TemplateEditorView(template: SampleData.template)
    .modelContainer(AppContainer.preview.modelContainer)
}

private enum SampleData {
  @MainActor
  static var template: WorkoutTemplate {
    let context = AppContainer.preview.modelContainer.mainContext
    AppContainer.addSampleData(context)
    let workoutFetch = FetchDescriptor<Workout>()
    if let workout = try? context.fetch(workoutFetch).first {
      return workout.makeTemplate(name: "Preview Template")
    }
    return WorkoutTemplate(name: "Empty")
  }
}
