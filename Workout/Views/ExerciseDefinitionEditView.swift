//
//  ExerciseDefinitionEditView.swift
//  Workout
//
//  Created by Eliott on 2025-04-14.
//

import SwiftData
import SwiftUI

struct ExerciseDefinitionEditView: View {
  @Bindable var exerciseDefinition: ExerciseDefinition
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) var dismiss

  @FocusState private var isFocused: Bool

  var body: some View {
    Form {
      TextField("Exercise Name", text: $exerciseDefinition.name)
        .autocapitalization(.words)
        .focused($isFocused)
        .padding()
        .font(.title2)
        .fontWeight(.semibold)
    }
    .onAppear {
      isFocused = true
    }
    .navigationTitle(exerciseDefinition.name)
    .navigationBarTitleDisplayMode(.inline)
  }
}


#Preview {
  let container = AppContainer.preview.modelContainer
  let sampleExercise = ExerciseDefinition(name: "Sample Exercise")
  container.mainContext.insert(sampleExercise)

  return NavigationStack {
    ExerciseDefinitionEditView(exerciseDefinition: sampleExercise)
      .modelContainer(container)
  }
}
