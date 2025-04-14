//
//  File.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import Foundation
import SwiftData

// MARK: - Core Workout Structure

@Model
final class Workout {
  var date: Date
  var name: String?

  // Using a dedicated WorkoutItem class to handle the mixed list of Exercises and Supersets
  // The order property on WorkoutItem will manage the display sequence.
  // When a Workout is deleted, all its WorkoutItems should be deleted
  @Relationship(deleteRule: .cascade, inverse: \WorkoutItem.workout)
  var items: [WorkoutItem]? = []  // Use optional array initialization for SwiftData best practice

  init(date: Date = Date(), name: String? = nil) {
    self.date = date
    self.name = name
    self.items = []
  }

  // Computed property to get items sorted reliably by their order property
  @Transient var orderedItems: [WorkoutItem] {
    (items ?? []).sorted { $0.order < $1.order }
  }

  // Convenience method to add a new item (Exercise or Superset) and maintain order
  func addItem(_ item: WorkoutItem) {
    item.order = (items?.count ?? 0)  // Append to the end
    items?.append(item)
    item.workout = self  // Set the inverse relationship
    item.updateContainedItemWorkouts()  // Update workout relationship on contained items
  }
}

extension Workout {
  var formattedDate: LocalizedStringResource {
    "\(date, format: .dateTime.day().month(.wide).year())"
  }

  var smartFormattedDate: LocalizedStringResource {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return "Today"
    } else if calendar.isDateInYesterday(date) {
      return "Yesterday"
    } else {
      return formattedDate
    }
  }
}

// MARK: - Workout Item (Wrapper for Exercise/Superset in Workout Order)

@Model
final class WorkoutItem {
  var order: Int = 0  // Defines the sequence within the Workout

  var workout: Workout?

  // A WorkoutItem represents EITHER a single Exercise OR a Superset
  @Relationship(deleteRule: .cascade, inverse: \Exercise.workoutItem)
  var exercise: Exercise?

  @Relationship(deleteRule: .cascade, inverse: \Superset.workoutItem)
  var superset: Superset?

  // Enforce that only one relationship (exercise or superset) is set.
  // This is a logical constraint, SwiftData doesn't enforce XOR directly.
  // You'll manage this in your application logic when creating WorkoutItems.

  private init(order: Int = 0, exercise: Exercise? = nil, superset: Superset? = nil) {
    self.order = order
    self.exercise = exercise
    self.superset = superset

    // Establish inverse relationships if items are provided at init
    exercise?.workoutItem = self
    superset?.workoutItem = self
  }

  convenience init(order: Int = 0, exercise: Exercise) {
    self.init(order: order, exercise: exercise, superset: nil)
  }

  convenience init(order: Int = 0, superset: Superset) {
    self.init(order: order, exercise: nil, superset: superset)
  }

  // Update the workout relationship on contained items when the workout is set
  func updateContainedItemWorkouts() {
    if let workout = self.workout {
      // Update exercise's workout relationship
      if let exercise = self.exercise {
        exercise.workout = workout
      }

      // Update all exercises in a superset
      if let superset = self.superset {
        for exercise in superset.exercises {
          exercise.workout = workout
        }
      }
    }
  }
}

// MARK: - Exercise Instance (within a Workout or Superset)

@Model
final class Exercise {
  var restTime: Int  // Rest time in seconds for *this specific instance*
  var orderWithinSuperset: Int = 0  // Order if part of a Superset (ignored otherwise)
  var notes: String?

  // Link back to the generic definition of the exercise
  // Delete rule .nullify means if ExerciseDefinition is deleted, this link becomes nil
  // but the Exercise instance itself remains (perhaps showing "Deleted Exercise").
  // Consider .noAction if you want deletion of ExerciseDefinition to fail if instances exist.
  // Or handle this logic manually before deleting definitions. Let's use nullify for flexibility.
  @Relationship(deleteRule: .nullify)
  var definition: ExerciseDefinition?

  // The sets performed for this specific exercise instance
  @Relationship(deleteRule: .cascade, inverse: \SetEntry.exercise)
  var orderedSets: [SetEntry]? = []  // Use optional array initialization

  var workoutItem: WorkoutItem?  // If it's directly in a Workout
  var containingSuperset: Superset?  // If it's part of a Superset
  var workout: Workout

  // Computed property for sorted sets
  @Transient var sets: [SetEntry] {
    (orderedSets ?? []).sorted { $0.order < $1.order }
  }

  // Requires the ExerciseDefinition to link to
  init(
    definition: ExerciseDefinition, workout: Workout, restTime: Int = 120, orderWithinSuperset: Int = 0,
    notes: String? = nil
  ) {
    self.definition = definition
    self.workout = workout
    // Use definition's default rest time if no specific override provided
    self.restTime = restTime
    self.orderWithinSuperset = orderWithinSuperset
    self.orderedSets = []
    self.notes = notes
  }

  // Convenience method to add a set and maintain order
  func addSet(_ set: SetEntry) {
    set.order = (orderedSets?.count ?? 0)  // Append to the end
    orderedSets?.append(set)
    set.exercise = self  // Set inverse relationship
  }
}

// MARK: - Superset Instance (within a Workout)

@Model
final class Superset {
  var notes: String?
  var restTime: Int = 180
  // The exercises included in this specific superset instance, in order
  @Relationship(deleteRule: .cascade, inverse: \Exercise.containingSuperset)
  var orderedExercises: [Exercise]? = []  // Use optional array initialization

  // Inverse relationship: Which WorkoutItem represents this Superset in the Workout?
  var workoutItem: WorkoutItem?

  // Computed property for sorted exercises within the superset
  @Transient var exercises: [Exercise] {
    (orderedExercises ?? []).sorted { $0.orderWithinSuperset < $1.orderWithinSuperset }
  }

  init(notes: String? = nil, restTime: Int = 180) {
    self.orderedExercises = []
    self.notes = notes
    self.restTime = restTime
  }

  // Convenience method to add an exercise and maintain order
  func addExercise(_ exercise: Exercise) {
    // Ensure the exercise isn't already linked elsewhere inappropriately
    exercise.workoutItem = nil
    exercise.containingSuperset = self  // Set inverse relationship
    exercise.orderWithinSuperset = (orderedExercises?.count ?? 0)  // Append to end
    orderedExercises?.append(exercise)

    // Set the workout relationship if the superset is already in a workout
    if let workoutItem = self.workoutItem, let workout = workoutItem.workout {
      exercise.workout = workout
    }
  }
}

// MARK: - Set Entry

@Model
final class SetEntry {
  var order: Int = 0  // Defines the sequence of sets within an Exercise instance
  var reps: Int
  var weight: Double  // Using Double for flexibility (e.g., 2.5 kg/lb plates)

  var exercise: Exercise?

  init(order: Int = 0, reps: Int, weight: Double) {
    self.order = order
    self.reps = reps
    self.weight = weight
  }
}

// MARK: - Exercise Definition (The template/blueprint)

@Model
final class ExerciseDefinition {

  // Make the name unique to avoid duplicate exercise definitions
  @Attribute(.unique) var name: String

  // SwiftData automatically handles the inverse relationship from Exercise.definition
  // We don't strictly need to store a list of all instances here unless needed for specific queries.

  init(name: String) {
    self.name = name
  }
}

extension ExerciseDefinition {
  /// Creates a new exercise definition with properly capitalized name and inserts it into the model context
  /// - Parameters:
  ///   - exerciseName: The raw exercise name input from the user
  ///   - modelContext: The SwiftData model context to insert the new definition into
  /// - Returns: The newly created ExerciseDefinition, or nil if the name was empty
  static func createAndSave(with exerciseName: String, in modelContext: ModelContext)
    -> ExerciseDefinition?
  {
    let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else { return nil }

    // Capitalize the first letter of each word
    let capitalizedName = trimmedName.capitalizingFirstLetterOfEachWord()

    let exerciseDefinition = ExerciseDefinition(name: capitalizedName)
    modelContext.insert(exerciseDefinition)
    try? modelContext.save()

    return exerciseDefinition
  }
}
