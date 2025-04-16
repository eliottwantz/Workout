//
//  ExerciseDefinitionDetailView.swift
//  Workout
//
//  Created by Eliott on 2025-04-15.
//

import SwiftUI

struct ExerciseDefinitionDetailView: View {
  var exercise: ExerciseDefinition
  @Binding var path: NavigationPath

  @State private var isEditing = false
  @State private var isDeleting = false
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    List {
      Section("Basic Information") {
        HStack {
          Text("Muscle Group")
          Spacer()
          Text(exercise.muscleGroup)
        }

        HStack {
          Text("Favorite")
          Spacer()
          FavoriteButton(isSet: exercise.favorite)
        }

      }

      // MARK: - Notes

      Section("Notes") {
        if let notes = exercise.notes, !notes.isEmpty {
          Text(notes)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        } else {
          Text("It's empty here. Add some notes!")
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
      }
    }
    .navigationTitle(exercise.name)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        NavigationLink(destination: AnalyticsView(exerciseToShow: exercise)) {
          Label("Analytics", systemImage: "chart.xyaxis.line")
        }
        Button {
          isEditing = true
        } label: {
          Label("Edit", systemImage: "pencil")
        }
        Button {
          isDeleting = true
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    }
    .sheet(isPresented: $isEditing) {
      ExerciseDefinitionEditor(exerciseDefinition: exercise)
        .interactiveDismissDisabled()
    }
    .alert("Delete \(exercise.name)?", isPresented: $isDeleting) {
      Button("Yes, delete \(exercise.name)", role: .destructive) {
        exercise.deleteWithAllContainingExercises(in: modelContext)
        path.removeLast()
      }
    }
  }
}

#Preview {
  @Previewable @State var path = NavigationPath()
  NavigationStack {
    ExerciseDefinitionDetailView(
      exercise: .init(
        name: "Bench Press", muscleGroup: .chest, notes: "A great exercise for building upper body strength."),
      path: $path
    )
  }
  .modelContainer(AppContainer.preview.modelContainer)
}
