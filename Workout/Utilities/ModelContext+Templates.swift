//
//  ModelContext+Templates.swift
//  Workout
//
//  Created by Codex on 2025-10-29.
//

import Foundation
import SwiftData

extension ModelContext {
  @discardableResult
  func createTemplate(from workout: Workout, name: String, notes: String?) throws -> WorkoutTemplate {
    let template = workout.makeTemplate(name: name, notes: notes)
    template.refreshUpdatedAt()
    insert(template)
    try save()
    return template
  }

  @discardableResult
  func createEmptyTemplate(name: String, notes: String?) throws -> WorkoutTemplate {
    let template = WorkoutTemplate(name: name, notes: notes)
    template.refreshUpdatedAt()
    insert(template)
    try save()
    return template
  }

  func updateTemplate(_ template: WorkoutTemplate, name: String, notes: String?, isFavorite: Bool) throws {
    template.name = name
    template.notes = notes
    template.isFavorite = isFavorite
    template.refreshUpdatedAt()
    try save()
  }

  func deleteTemplate(_ template: WorkoutTemplate) throws {
    delete(template)
    try save()
  }

  @discardableResult
  func duplicateTemplate(_ template: WorkoutTemplate) throws -> WorkoutTemplate {
    let copyName = template.name + " Copy"
    let workoutCopy = template.instantiateWorkout()
    workoutCopy.name = copyName
    let duplicatedTemplate = workoutCopy.makeTemplate(name: copyName, notes: template.notes)
    duplicatedTemplate.isFavorite = template.isFavorite
    duplicatedTemplate.refreshUpdatedAt()
    insert(duplicatedTemplate)
    try save()
    return duplicatedTemplate
  }

  @discardableResult
  func instantiateWorkout(from template: WorkoutTemplate, on date: Date = .now) throws -> Workout {
    let workout = template.instantiateWorkout(on: date)
    insert(workout)
    template.refreshUpdatedAt()
    try save()
    return workout
  }
}
