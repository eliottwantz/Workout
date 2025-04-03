//
//  ExerciseUtilities.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import Foundation
import SwiftData

enum ExerciseUtilities {
  /// Creates a new exercise definition with properly capitalized name and inserts it into the model context
  /// - Parameters:
  ///   - exerciseName: The raw exercise name input from the user
  ///   - modelContext: The SwiftData model context to insert the new definition into
  /// - Returns: The newly created ExerciseDefinition, or nil if the name was empty
  static func createNewExerciseDefinition(with exerciseName: String, in modelContext: ModelContext)
    -> ExerciseDefinition?
  {
    let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else {
      return nil
    }

    // Capitalize the first letter of each word
    let capitalizedName = trimmedName.capitalizingFirstLetterOfEachWord()

    let exerciseDefinition = ExerciseDefinition(name: capitalizedName)
    modelContext.insert(exerciseDefinition)
    try? modelContext.save()

    return exerciseDefinition
  }
}
