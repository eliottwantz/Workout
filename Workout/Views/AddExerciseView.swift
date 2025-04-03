//
//  AddExerciseView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workout: Workout
    
    @Query var exerciseDefinitions: [ExerciseDefinition]
    @State private var searchText = ""
    @State private var selectedExercises: Set<PersistentIdentifier> = []
    @State private var showingAddNewExerciseDialog = false
    @State private var newExerciseName = ""
    @State private var selectedOption = AddOption.individual
    
    enum AddOption {
        case individual
        case superset
    }
    
    var body: some View {
        VStack {
            Picker("Add Option", selection: $selectedOption) {
                Text("Add Individual Exercises").tag(AddOption.individual)
                Text("Create Superset").tag(AddOption.superset)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)
            
            Text(selectedOption == .individual 
                 ? "Select exercises to add to your workout" 
                 : "Select exercises to include in your superset")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            List {
                ForEach(filteredExerciseDefinitions) { definition in
                    Button(action: {
                        toggleSelection(definition)
                    }) {
                        HStack {
                            Text(definition.name)
                            Spacer()
                            if selectedExercises.contains(definition.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            
            VStack(spacing: 10) {
                Button(action: {
                    showingAddNewExerciseDialog = true
                }) {
                    Label("Add New Exercise Type", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                
                Button(action: {
                    addSelectedExercisesToWorkout()
                    dismiss()
                }) {
                    Text(selectedOption == .individual 
                         ? "Add \(selectedExercises.count) Exercise(s)" 
                         : "Create Superset with \(selectedExercises.count) Exercise(s)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedExercises.isEmpty)
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Add New Exercise", isPresented: $showingAddNewExerciseDialog) {
            TextField("Exercise Name", text: $newExerciseName)
            
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addNewExerciseDefinition()
            }
        } message: {
            Text("Enter the name of the exercise you want to add.")
        }
    }
    
    private var filteredExerciseDefinitions: [ExerciseDefinition] {
        if searchText.isEmpty {
            return exerciseDefinitions.sorted { $0.name < $1.name }
        } else {
            return exerciseDefinitions.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }.sorted { $0.name < $1.name }
        }
    }
    
    private func toggleSelection(_ definition: ExerciseDefinition) {
        if selectedExercises.contains(definition.id) {
            selectedExercises.remove(definition.id)
        } else {
            selectedExercises.insert(definition.id)
        }
    }
    
    private func addNewExerciseDefinition() {
        guard !newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let exerciseDefinition = ExerciseDefinition(name: newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(exerciseDefinition)
        try? modelContext.save()
        
        // Reset the input
        newExerciseName = ""
    }
    
    private func addSelectedExercisesToWorkout() {
        if selectedExercises.isEmpty { return }
        
        if selectedOption == .individual {
            // Add individual exercises to the workout
            for definitionID in selectedExercises {
                if let definition = exerciseDefinitions.first(where: { $0.id == definitionID }) {
                    let exercise = Exercise(definition: definition)
                    let workoutItem = WorkoutItem(exercise: exercise)
                    workout.addItem(workoutItem)
                }
            }
        } else {
            // Create a superset with the selected exercises
            let superset = Superset()
            
            for (index, definitionID) in selectedExercises.enumerated() {
                if let definition = exerciseDefinitions.first(where: { $0.id == definitionID }) {
                    let exercise = Exercise(
                        definition: definition,
                        orderWithinSuperset: index
                    )
                    superset.addExercise(exercise)
                }
            }
            
            let workoutItem = WorkoutItem(superset: superset)
            workout.addItem(workoutItem)
        }
        
        try? modelContext.save()
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
        AddExerciseView(workout: sampleWorkout)
            .modelContainer(container)
    }
}
