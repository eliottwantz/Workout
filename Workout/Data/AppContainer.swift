//
//  File.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {
  static let shared = AppContainer()
  static let preview = AppContainer(preview: true)

  private let schema = Schema([
    Workout.self,
    WorkoutItem.self,
    Exercise.self,
    Superset.self,
    SetEntry.self,
    ExerciseDefinition.self,
  ])

  let modelContainer: ModelContainer

  private init(preview: Bool = false) {
    do {
      let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: preview)
      modelContainer = try ModelContainer(for: schema, configurations: config)
      #if DEBUG
        //        if preview {
        //          AppContainer.addSampleData(modelContainer.mainContext)
        //        }
      #endif
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  // Function to add some sample data
  static func addSampleData(_ modelContext: ModelContext) {
    try? modelContext.delete(model: Workout.self)
    try? modelContext.delete(model: ExerciseDefinition.self)

    // Create some Exercise Definitions
    let squatDefinition = ExerciseDefinition(name: "Squats")
    let benchPressDefinition = ExerciseDefinition(name: "Bench Press")
    let deadliftDefinition = ExerciseDefinition(name: "Deadlift")
    let pullUpDefinition = ExerciseDefinition(name: "Pull-ups")
    let bicepCurlDefinition = ExerciseDefinition(name: "Bicep Curls")
    let tricepsExtensionDefinition = ExerciseDefinition(name: "Triceps Extensions")
    let shoulderPressDefinition = ExerciseDefinition(name: "Shoulder Press")
    let lungesDefinition = ExerciseDefinition(name: "Lunges")

    modelContext.insert(squatDefinition)
    modelContext.insert(benchPressDefinition)
    modelContext.insert(deadliftDefinition)
    modelContext.insert(pullUpDefinition)
    modelContext.insert(bicepCurlDefinition)
    modelContext.insert(tricepsExtensionDefinition)
    modelContext.insert(shoulderPressDefinition)
    modelContext.insert(lungesDefinition)

    // Create a sample past workout
    let pastWorkout = Workout(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, name: "Leg day")

    // Add exercises to the past workout
    let squatExercise1 = Exercise(definition: squatDefinition, restTime: 100)
    squatExercise1.addSet(SetEntry(reps: 8, weight: 100.0))
    squatExercise1.addSet(SetEntry(reps: 8, weight: 100.0))
    squatExercise1.addSet(SetEntry(reps: 6, weight: 105.0))
    let squatItem1 = WorkoutItem(order: 0, exercise: squatExercise1)
    pastWorkout.addItem(squatItem1)

    let benchPressExercise1 = Exercise(definition: benchPressDefinition, restTime: 120)
    benchPressExercise1.addSet(SetEntry(reps: 6, weight: 80.0))
    benchPressExercise1.addSet(SetEntry(reps: 6, weight: 80.0))
    benchPressExercise1.addSet(SetEntry(reps: 4, weight: 85.0))
    let benchPressItem1 = WorkoutItem(order: 1, exercise: benchPressExercise1)
    pastWorkout.addItem(benchPressItem1)

    let deadliftExercise1 = Exercise(definition: deadliftDefinition, restTime: 150)
    deadliftExercise1.addSet(SetEntry(reps: 5, weight: 120.0))
    deadliftExercise1.addSet(SetEntry(reps: 3, weight: 130.0))
    let deadliftItem1 = WorkoutItem(order: 2, exercise: deadliftExercise1)
    pastWorkout.addItem(deadliftItem1)

    modelContext.insert(pastWorkout)

    // Create another sample past workout with a superset
    let anotherPastWorkout = Workout(
      date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)

    // Create a superset
    let armsSuperset = Superset(notes: "Very intense")
    let bicepCurlExercise1 = Exercise(definition: bicepCurlDefinition, restTime: 60, orderWithinSuperset: 0)
    bicepCurlExercise1.addSet(SetEntry(reps: 10, weight: 25.0))
    bicepCurlExercise1.addSet(SetEntry(reps: 10, weight: 25.0))
    armsSuperset.addExercise(bicepCurlExercise1)

    let tricepsExtensionExercise1 = Exercise(
      definition: tricepsExtensionDefinition, restTime: 60, orderWithinSuperset: 1)
    tricepsExtensionExercise1.addSet(SetEntry(reps: 12, weight: 40.0))
    tricepsExtensionExercise1.addSet(SetEntry(reps: 12, weight: 40.0))
    armsSuperset.addExercise(tricepsExtensionExercise1)

    let supersetItem1 = WorkoutItem(order: 0, superset: armsSuperset)
    anotherPastWorkout.addItem(supersetItem1)

    // Add a regular exercise after the superset
    let shoulderPressExercise1 = Exercise(definition: shoulderPressDefinition, restTime: 90)
    shoulderPressExercise1.addSet(SetEntry(reps: 8, weight: 50.0))
    shoulderPressExercise1.addSet(SetEntry(reps: 8, weight: 50.0))
    let shoulderPressItem1 = WorkoutItem(order: 1, exercise: shoulderPressExercise1)
    anotherPastWorkout.addItem(shoulderPressItem1)

    modelContext.insert(anotherPastWorkout)

    // Create a sample today's workout
    let todaysWorkout = Workout(date: Date())

    let lungesExercise1 = Exercise(definition: lungesDefinition, restTime: 80)
    lungesExercise1.addSet(SetEntry(reps: 10, weight: 30.0))
    lungesExercise1.addSet(SetEntry(reps: 10, weight: 30.0))
    let lungesItem1 = WorkoutItem(order: 0, exercise: lungesExercise1)
    todaysWorkout.addItem(lungesItem1)

    let squatExercise2 = Exercise(definition: squatDefinition, restTime: 95)
    squatExercise2.addSet(SetEntry(reps: 6, weight: 105.0))
    squatExercise2.addSet(SetEntry(reps: 6, weight: 105.0))
    squatExercise2.addSet(SetEntry(reps: 4, weight: 110.0))
    let squatItem2 = WorkoutItem(order: 1, exercise: squatExercise2)
    todaysWorkout.addItem(squatItem2)

    modelContext.insert(todaysWorkout)

    try? modelContext.save()
  }

}
