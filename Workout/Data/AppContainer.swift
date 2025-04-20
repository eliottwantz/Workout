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
        if preview {
          AppContainer.addSampleData(modelContainer.mainContext)
        }
      #endif
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  // Function to add some sample data
  static func addSampleData(_ modelContext: ModelContext) {
    // Create exercise definitions
    let squatDefinition = ExerciseDefinition(name: "Squat")
    let benchPressDefinition = ExerciseDefinition(name: "Bench Press")
    let deadliftDefinition = ExerciseDefinition(name: "Deadlift")
    let bicepCurlDefinition = ExerciseDefinition(name: "Bicep Curl")
    let tricepsExtensionDefinition = ExerciseDefinition(name: "Triceps Extension")
    let shoulderPressDefinition = ExerciseDefinition(name: "Shoulder Press")
    let lungesDefinition = ExerciseDefinition(name: "Lunges")

    // Create some workouts
    let workout1 = Workout(
      date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
      name: "Lower Body"
    )

    let workout2 = Workout(
      date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
      name: "Upper Body"
    )

    let todayWorkout = Workout(
      date: Date(),
      name: "Full Body"
    )

    // Insert all models into context first
    modelContext.insert(squatDefinition)
    modelContext.insert(benchPressDefinition)
    modelContext.insert(deadliftDefinition)
    modelContext.insert(bicepCurlDefinition)
    modelContext.insert(tricepsExtensionDefinition)
    modelContext.insert(shoulderPressDefinition)
    modelContext.insert(lungesDefinition)

    modelContext.insert(workout1)
    modelContext.insert(workout2)
    modelContext.insert(todayWorkout)

    // Workout 1 (3 days ago): Squat
    let squatExercise1 = Exercise(definition: squatDefinition, workout: workout1, restTime: 100)
    for i in 0..<3 {
      let set = SetEntry(reps: 8, weight: 225.0 + Double(i * 10))
      squatExercise1.addSet(set)
    }
    let workoutItem1 = WorkoutItem(exercise: squatExercise1)
    workout1.addItem(workoutItem1)

    // Workout 2 (yesterday): Bench Press
    let benchPressExercise1 = Exercise(definition: benchPressDefinition, workout: workout2, restTime: 120)
    for i in 0..<3 {
      let set = SetEntry(reps: 8, weight: 135.0 + Double(i * 10))
      benchPressExercise1.addSet(set)
    }
    let workoutItem2 = WorkoutItem(exercise: benchPressExercise1)
    workout2.addItem(workoutItem2)

    // Workout 2: Deadlift
    let deadliftExercise1 = Exercise(definition: deadliftDefinition, workout: workout2, restTime: 150)
    for i in 0..<3 {
      let set = SetEntry(reps: 5, weight: 275.0 + Double(i * 10))
      deadliftExercise1.addSet(set)
    }
    let workoutItem3 = WorkoutItem(exercise: deadliftExercise1)
    workout2.addItem(workoutItem3)

    // Today's Workout: Superset (Bicep Curl + Triceps Extension)
    let armsSuperset = Superset(restTime: 90)

    // Add Bicep Curl to superset
    let bicepCurlExercise1 = Exercise(
      definition: bicepCurlDefinition, workout: todayWorkout, restTime: 60, orderWithinSuperset: 0)
    for i in 0..<3 {
      let set = SetEntry(reps: 12, weight: 25.0 + Double(i * 5))
      bicepCurlExercise1.addSet(set)
    }
    armsSuperset.addExercise(bicepCurlExercise1)

    // Add Triceps Extension to superset
    let tricepsExtensionExercise1 = Exercise(
      definition: tricepsExtensionDefinition,
      workout: todayWorkout,
      restTime: 60,
      orderWithinSuperset: 1
    )
    for i in 0..<3 {
      let set = SetEntry(reps: 12, weight: 30.0 + Double(i * 5))
      tricepsExtensionExercise1.addSet(set)
    }
    armsSuperset.addExercise(tricepsExtensionExercise1)

    let workoutItem4 = WorkoutItem(superset: armsSuperset)
    todayWorkout.addItem(workoutItem4)

    // Today's Workout: Shoulder Press
    let shoulderPressExercise1 = Exercise(definition: shoulderPressDefinition, workout: todayWorkout, restTime: 90)
    for i in 0..<3 {
      let set = SetEntry(reps: 10, weight: 65.0 + Double(i * 5))
      shoulderPressExercise1.addSet(set)
    }
    let workoutItem5 = WorkoutItem(exercise: shoulderPressExercise1)
    todayWorkout.addItem(workoutItem5)

    // Create another workout from 5 days ago
    let workout3 = Workout(
      date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
      name: "Leg Day"
    )
    modelContext.insert(workout3)

    // Workout 3: Lunges
    let lungesExercise1 = Exercise(definition: lungesDefinition, workout: workout3, restTime: 80)
    for i in 0..<3 {
      let set = SetEntry(reps: 10, weight: 40.0 + Double(i * 5))
      lungesExercise1.addSet(set)
    }
    let workoutItem6 = WorkoutItem(exercise: lungesExercise1)
    workout3.addItem(workoutItem6)

    // Workout 3: Squat (a previous instance of squats)
    let squatExercise2 = Exercise(definition: squatDefinition, workout: workout3, restTime: 95)
    for i in 0..<3 {
      let set = SetEntry(reps: 8, weight: 215.0 + Double(i * 10))
      squatExercise2.addSet(set)
    }
    let workoutItem7 = WorkoutItem(exercise: squatExercise2)
    workout3.addItem(workoutItem7)

    try? modelContext.save()
  }

}

extension AppContainer {
  static func findMostRecentExercise(
    for definitionID: PersistentIdentifier, currentWorkoutID: UUID, modelContext: ModelContext
  ) -> Exercise? {
    do {
      // Use the direct relationship to Workout now that it exists in the model
      let predicate = #Predicate<Exercise> {
        $0.definition?.persistentModelID == definitionID && $0.workoutID != currentWorkoutID
      }

      var descriptor = FetchDescriptor<Exercise>(
        predicate: predicate,
        sortBy: [.init(\Exercise.workoutDate, order: .reverse)]
      )

      // Add relationship prefetching for performance
      descriptor.relationshipKeyPathsForPrefetching = [
        \Exercise.workout, \Exercise.definition, \Exercise.sets,
      ]
      descriptor.fetchLimit = 1

      let exercises = try modelContext.fetch(descriptor)
      return exercises.first
    } catch {
      print("Error fetching most recent exercise: \(error)")
      return nil
    }
  }

}

let UserAccentColorKey: String = "userAccentColor"
let AllowMultipleWorkoutsPerDayKey: String = "allowMultipleWorkoutsPerDay"
let DisplayWeightInLbsKey: String = "displayWeightInLbs"
