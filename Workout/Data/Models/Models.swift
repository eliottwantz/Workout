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

  // Using a dedicated WorkoutItem class to handle the mixed list of Exercises and Supersets
  // The order property on WorkoutItem will manage the display sequence.
  @Relationship(deleteRule: .cascade, inverse: \WorkoutItem.workout)
  var orderedItems: [WorkoutItem]? = []  // Use optional array initialization for SwiftData best practice

  // Computed property to get items sorted reliably by their order property
  @Transient var items: [WorkoutItem] {
    (orderedItems ?? []).sorted { $0.order < $1.order }
  }

  init(date: Date = Date()) {
    self.date = date
    self.orderedItems = []
  }

  // Convenience method to add a new item (Exercise or Superset) and maintain order
  func addItem(_ item: WorkoutItem) {
    item.order = (orderedItems?.count ?? 0)  // Append to the end
    orderedItems?.append(item)
    item.workout = self  // Set the inverse relationship
  }
}

extension Workout {
  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium

    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return "Today"
    } else if calendar.isDateInYesterday(date) {
      return "Yesterday"
    } else {
      return formatter.string(from: date)
    }
  }
}

// MARK: - Workout Item (Wrapper for Exercise/Superset in Workout Order)

@Model
final class WorkoutItem {
  var order: Int = 0  // Defines the sequence within the Workout

  var workout: Workout?  // Inverse relationship back to the Workout

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
}

// MARK: - Exercise Instance (within a Workout or Superset)

@Model
final class Exercise {
  var restTime: Int  // Rest time in seconds for *this specific instance*
  var orderWithinSuperset: Int = 0  // Order if part of a Superset (ignored otherwise)

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

  // Inverse relationship: Where does this exercise instance live?
  var workoutItem: WorkoutItem?  // If it's directly in a Workout
  var containingSuperset: Superset?  // If it's part of a Superset

  // Computed property for sorted sets
  @Transient var sets: [SetEntry] {
    (orderedSets ?? []).sorted { $0.order < $1.order }
  }

  // Requires the ExerciseDefinition to link to
  init(definition: ExerciseDefinition, restTime: Int = 120, orderWithinSuperset: Int = 0) {
    self.definition = definition
    // Use definition's default rest time if no specific override provided
    self.restTime = restTime
    self.orderWithinSuperset = orderWithinSuperset
    self.orderedSets = []
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
  // The exercises included in this specific superset instance, in order
  @Relationship(deleteRule: .cascade, inverse: \Exercise.containingSuperset)
  var orderedExercises: [Exercise]? = []  // Use optional array initialization

  // Inverse relationship: Which WorkoutItem represents this Superset in the Workout?
  var workoutItem: WorkoutItem?

  // Computed property for sorted exercises within the superset
  @Transient var exercises: [Exercise] {
    (orderedExercises ?? []).sorted { $0.orderWithinSuperset < $1.orderWithinSuperset }
  }

  init() {
    self.orderedExercises = []
  }

  // Convenience method to add an exercise and maintain order
  func addExercise(_ exercise: Exercise) {
    // Ensure the exercise isn't already linked elsewhere inappropriately
    exercise.workoutItem = nil
    exercise.containingSuperset = self  // Set inverse relationship
    exercise.orderWithinSuperset = (orderedExercises?.count ?? 0)  // Append to end
    orderedExercises?.append(exercise)
  }
}

// MARK: - Set Entry

@Model
final class SetEntry {
  var order: Int = 0  // Defines the sequence of sets within an Exercise instance
  var reps: Int
  var weight: Double  // Using Double for flexibility (e.g., 2.5 kg/lb plates)

  // Inverse relationship: Which Exercise instance does this set belong to?
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
