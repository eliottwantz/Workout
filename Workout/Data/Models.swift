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
  var id = UUID()
  var date: Date = Date()
  var name: String?

  // Using a dedicated WorkoutItem class to handle the mixed list of Exercises and Supersets
  // The order property on WorkoutItem will manage the display sequence.
  // When a Workout is deleted, all its WorkoutItems should be deleted
  @Relationship(deleteRule: .cascade, inverse: \WorkoutItem.workout)
  var items: [WorkoutItem]? = []

  @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
  private var exercises: [Exercise]? = []

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

// MARK: - Workout Template

@Model
final class WorkoutTemplate {
  var id = UUID()
  var name: String = ""
  var notes: String?
  var createdAt: Date = Date.now
  var updatedAt: Date = Date.now
  var isFavorite: Bool = false

  @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateItem.template)
  var items: [WorkoutTemplateItem]? = []

  init(
    name: String,
    notes: String? = nil,
    createdAt: Date = .now,
    updatedAt: Date = .now,
    isFavorite: Bool = false
  ) {
    self.name = name
    self.notes = notes
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.isFavorite = isFavorite
    self.items = []
  }

  convenience init(name: String, sourceWorkout: Workout, notes: String? = nil) {
    self.init(name: name, notes: notes)
    copyItems(from: sourceWorkout)
  }

  @Transient var orderedItems: [WorkoutTemplateItem] {
    (items ?? []).sorted { $0.order < $1.order }
  }

  @Transient var exerciseCount: Int {
    orderedItems.reduce(into: 0) { count, item in
      if item.exercise != nil {
        count += 1
      } else if let superset = item.superset {
        count += superset.orderedExercises.count
      }
    }
  }

  func addItem(_ item: WorkoutTemplateItem) {
    if items == nil {
      items = []
    }
    item.order = (items?.count ?? 0)
    items?.append(item)
    item.template = self
    item.updateContainedRelationships()
  }

  func refreshUpdatedAt() {
    updatedAt = .now
  }

  func instantiateWorkout(on date: Date = .now) -> Workout {
    let workout = Workout(date: date)
    workout.name = name

    for item in orderedItems {
      if let exerciseTemplate = item.exercise, let definition = exerciseTemplate.definition {
        let exercise = Exercise(
          definition: definition,
          workout: workout,
          restTime: exerciseTemplate.restTime,
          notes: exerciseTemplate.notes
        )

        for setTemplate in exerciseTemplate.orderedSets {
          let set = SetEntry(reps: setTemplate.reps, weight: setTemplate.weight)
          exercise.addSet(set)
        }

        let workoutItem = WorkoutItem(exercise: exercise)
        workout.addItem(workoutItem)

      } else if let supersetTemplate = item.superset {
        let superset = Superset(notes: supersetTemplate.notes, restTime: supersetTemplate.restTime)

        for exerciseTemplate in supersetTemplate.orderedExercises {
          guard let definition = exerciseTemplate.definition else { continue }

          let exercise = Exercise(
            definition: definition,
            workout: workout,
            restTime: exerciseTemplate.restTime,
            orderWithinSuperset: exerciseTemplate.orderWithinSuperset,
            notes: exerciseTemplate.notes
          )

          for setTemplate in exerciseTemplate.orderedSets {
            let set = SetEntry(reps: setTemplate.reps, weight: setTemplate.weight)
            exercise.addSet(set)
          }

          superset.addExercise(exercise)
        }

        let workoutItem = WorkoutItem(superset: superset)
        workout.addItem(workoutItem)
      }
    }

    return workout
  }

  private func copyItems(from workout: Workout) {
    items = []
    for item in workout.orderedItems {
      if let exercise = item.exercise {
        let templateExercise = WorkoutTemplateExercise(
          definition: exercise.definition,
          restTime: exercise.restTime,
          notes: exercise.notes
        )

        for set in exercise.orderedSets {
          let templateSet = WorkoutTemplateSet(order: set.order, reps: set.reps, weight: set.weight)
          templateExercise.addSet(templateSet)
        }

        let templateItem = WorkoutTemplateItem(exercise: templateExercise)
        addItem(templateItem)
      } else if let superset = item.superset {
        let templateSuperset = WorkoutTemplateSuperset(notes: superset.notes, restTime: superset.restTime)

        for exercise in superset.orderedExercises {
          let templateExercise = WorkoutTemplateExercise(
            definition: exercise.definition,
            restTime: exercise.restTime,
            orderWithinSuperset: exercise.orderWithinSuperset,
            notes: exercise.notes
          )

          for set in exercise.orderedSets {
            let templateSet = WorkoutTemplateSet(order: set.order, reps: set.reps, weight: set.weight)
            templateExercise.addSet(templateSet)
          }

          templateSuperset.addExercise(templateExercise)
        }

        let templateItem = WorkoutTemplateItem(superset: templateSuperset)
        addItem(templateItem)
      }
    }
  }
}

@Model
final class WorkoutTemplateItem {
  var order: Int = 0
  var template: WorkoutTemplate?

  @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateExercise.templateItem)
  var exercise: WorkoutTemplateExercise?

  @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateSuperset.templateItem)
  var superset: WorkoutTemplateSuperset?

  private init(order: Int = 0, exercise: WorkoutTemplateExercise? = nil, superset: WorkoutTemplateSuperset? = nil) {
    self.order = order
    self.exercise = exercise
    self.superset = superset

    exercise?.templateItem = self
    superset?.templateItem = self
  }

  convenience init(order: Int = 0, exercise: WorkoutTemplateExercise) {
    self.init(order: order, exercise: exercise, superset: nil)
  }

  convenience init(order: Int = 0, superset: WorkoutTemplateSuperset) {
    self.init(order: order, exercise: nil, superset: superset)
  }

  func updateContainedRelationships() {
    exercise?.templateItem = self
    superset?.templateItem = self
  }
}

@Model
final class WorkoutTemplateExercise {
  var restTime: Int = 120
  var orderWithinSuperset: Int = 0
  var notes: String?

  var definition: ExerciseDefinition?

  @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateSet.exercise)
  var sets: [WorkoutTemplateSet]? = []

  var templateItem: WorkoutTemplateItem?
  var containingSuperset: WorkoutTemplateSuperset?

  @Transient var orderedSets: [WorkoutTemplateSet] {
    (sets ?? []).sorted { $0.order < $1.order }
  }

  init(
    definition: ExerciseDefinition?,
    restTime: Int = 120,
    orderWithinSuperset: Int = 0,
    notes: String? = nil
  ) {
    self.definition = definition
    self.restTime = restTime
    self.orderWithinSuperset = orderWithinSuperset
    self.notes = notes
    self.sets = []
  }

  func addSet(_ set: WorkoutTemplateSet) {
    set.order = (sets?.count ?? 0)
    sets?.append(set)
    set.exercise = self
  }
}

@Model
final class WorkoutTemplateSuperset {
  var notes: String?
  var restTime: Int = 150

  @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateExercise.containingSuperset)
  var exercises: [WorkoutTemplateExercise]? = []

  var templateItem: WorkoutTemplateItem?

  @Transient var orderedExercises: [WorkoutTemplateExercise] {
    (exercises ?? []).sorted { $0.orderWithinSuperset < $1.orderWithinSuperset }
  }

  init(notes: String? = nil, restTime: Int = 150) {
    self.notes = notes
    self.restTime = restTime
    self.exercises = []
  }

  func addExercise(_ exercise: WorkoutTemplateExercise) {
    exercise.templateItem = nil
    exercise.containingSuperset = self
    exercise.orderWithinSuperset = (exercises?.count ?? 0)
    exercises?.append(exercise)
  }
}

@Model
final class WorkoutTemplateSet {
  var order: Int = 0
  var reps: Int = 10
  var weight: Double = 20

  var exercise: WorkoutTemplateExercise?

  init(order: Int = 0, reps: Int, weight: Double) {
    self.order = order
    self.reps = reps
    self.weight = weight
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
        for exercise in superset.orderedExercises {
          exercise.workout = workout
        }
      }
    }
  }
}

// MARK: - Exercise Instance (within a Workout or Superset)

@Model
final class Exercise {
  var restTime: Int = 120  // Rest time in seconds for *this specific instance*
  var orderWithinSuperset: Int = 0  // Order if part of a Superset (ignored otherwise)
  var notes: String?

  // Link back to the generic definition of the exercise
  // Delete rule .nullify means if ExerciseDefinition is deleted, this link becomes nil
  // but the Exercise instance itself remains (perhaps showing "Deleted Exercise").
  // Consider .noAction if you want deletion of ExerciseDefinition to fail if instances exist.
  // Or handle this logic manually before deleting definitions. Let's use nullify for flexibility.
  var definition: ExerciseDefinition?

  // The sets performed for this specific exercise instance
  @Relationship(deleteRule: .cascade, inverse: \SetEntry.exercise)
  var sets: [SetEntry]? = []  // Use optional array initialization

  var workoutItem: WorkoutItem?  // If it's directly in a Workout
  var containingSuperset: Superset?  // If it's part of a Superset
  var workout: Workout?
  var workoutID: UUID = UUID()
  var workoutDate: Date = Date()

  // Computed property for sorted sets
  @Transient var orderedSets: [SetEntry] {
    (sets ?? []).sorted { $0.order < $1.order }
  }

  // Requires the ExerciseDefinition to link to
  init(
    definition: ExerciseDefinition, workout: Workout, restTime: Int = 120,
    orderWithinSuperset: Int = 0,
    notes: String? = nil
  ) {
    self.definition = definition
    self.workout = workout
    // Use definition's default rest time if no specific override provided
    self.restTime = restTime
    self.orderWithinSuperset = orderWithinSuperset
    self.sets = []
    self.notes = notes
    self.workoutDate = workout.date
    self.workoutID = workout.id
  }

  // Convenience method to add a set and maintain order
  func addSet(_ set: SetEntry) {
    set.order = (sets?.count ?? 0)  // Append to the end
    sets?.append(set)
    set.exercise = self  // Set inverse relationship
  }
}

@Model
final class Superset {
  var notes: String?
  var restTime: Int = 150
  // The exercises included in this specific superset instance, in order
  @Relationship(deleteRule: .cascade, inverse: \Exercise.containingSuperset)
  var exercises: [Exercise]? = []  // Use optional array initialization

  // Inverse relationship: Which WorkoutItem represents this Superset in the Workout?
  var workoutItem: WorkoutItem?

  // Computed property for sorted exercises within the superset
  @Transient var orderedExercises: [Exercise] {
    (exercises ?? []).sorted { $0.orderWithinSuperset < $1.orderWithinSuperset }
  }

  init(notes: String? = nil, restTime: Int = 150) {
    self.exercises = []
    self.notes = notes
    self.restTime = restTime
  }

  // Convenience method to add an exercise and maintain order
  func addExercise(_ exercise: Exercise) {
    // Ensure the exercise isn't already linked elsewhere inappropriately
    exercise.workoutItem = nil
    exercise.containingSuperset = self  // Set inverse relationship
    exercise.orderWithinSuperset = (exercises?.count ?? 0)  // Append to end
    exercises?.append(exercise)

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
  var reps: Int = 10
  var weight: Double = 20  // Using Double for flexibility (e.g., 2.5 kg/lb plates)

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

  var name: String = ""

  // Additional properties for better exercise management
  var muscleGroup: String = MuscleGroup.other.rawValue
  var notes: String?
  var favorite: Bool = false

  @Relationship(deleteRule: .cascade, inverse: \Exercise.definition) var exercises: [Exercise]?
  @Relationship(deleteRule: .nullify, inverse: \WorkoutTemplateExercise.definition) var templateExercises: [WorkoutTemplateExercise]?

  init(
    name: String, muscleGroup: MuscleGroup = .other, notes: String? = nil, favorite: Bool = false
  ) {
    self.name = name
    self.muscleGroup = muscleGroup.rawValue
    self.notes = notes
    self.favorite = favorite
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

  func deepCopy(for date: Date? = nil) -> Workout {
    let newWorkout = Workout(date: date ?? self.date, name: self.name)

    for item in orderedItems {
      if let exercise = item.exercise, let definition = exercise.definition {
        let newExercise = Exercise(
          definition: definition,
          workout: newWorkout,
          restTime: exercise.restTime,
          notes: exercise.notes
        )

        for set in exercise.orderedSets {
          let newSet = SetEntry(
            reps: set.reps,
            weight: set.weight
          )
          newExercise.addSet(newSet)
        }

        let newItem = WorkoutItem(exercise: newExercise)
        newWorkout.addItem(newItem)

      } else if let superset = item.superset {
        let newSuperset = Superset(notes: superset.notes, restTime: superset.restTime)

        for exercise in superset.orderedExercises {
          guard let definition = exercise.definition else { continue }

          let newExercise = Exercise(
            definition: definition,
            workout: newWorkout,
            restTime: exercise.restTime,
            orderWithinSuperset: exercise.orderWithinSuperset,
            notes: exercise.notes
          )

          for set in exercise.orderedSets {
            let newSet = SetEntry(
              reps: set.reps,
              weight: set.weight
            )
            newExercise.addSet(newSet)
          }

          newSuperset.addExercise(newExercise)
        }

        let newItem = WorkoutItem(superset: newSuperset)
        newWorkout.addItem(newItem)
      }
    }

    return newWorkout
  }

  func makeTemplate(name: String, notes: String? = nil) -> WorkoutTemplate {
    WorkoutTemplate(name: name, sourceWorkout: self, notes: notes)
  }
}

extension ExerciseDefinition {

  func deleteWithAllContainingExercises(in modelContext: ModelContext) {
    modelContext.delete(self)
    if let exercisesUsingThisOne = self.exercises {
      for exercise in exercisesUsingThisOne {
        modelContext.delete(exercise)
        if let workoutItem = exercise.workoutItem {
          modelContext.delete(workoutItem)
        }
      }
    }
    try? modelContext.save()
  }

}

// MARK: - Supporting Enums for Exercise Definitions

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {

  case abs = "Abs"
  case chest = "Chest"
  case back = "Back"
  case legs = "Legs"
  case lowerBack = "Lower Back"
  case trapezius = "Trapezius"
  case shoulders = "Shoulders"
  case biceps = "Biceps"
  case triceps = "Triceps"
  case forearms = "Forearms"
  case glutes = "Glutes"
  case hamstrings = "Hamstrings"
  case quadriceps = "Quadriceps"
  case calves = "Calves"
  case abductors = "Abductors"
  case adductors = "Adductors"
  case neck = "Neck"

  case other = "Other"

  var id: String { self.rawValue }

}
