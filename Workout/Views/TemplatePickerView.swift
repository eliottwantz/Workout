//
//  TemplatePickerView.swift
//  Workout
//
//  Created by Codex on 2025-10-29.
//

import SwiftData
import SwiftUI

struct TemplatePickerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query(
    sort: [SortDescriptor(\WorkoutTemplate.updatedAt, order: .reverse)]
  ) private var templates: [WorkoutTemplate]

  var onSelect: (WorkoutTemplate) -> Void
  var onCreateBlank: () -> Void
  var onManageTemplates: () -> Void

  var body: some View {
    NavigationStack {
      List {
        Section("Templates") {
          if templates.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              Text("No templates yet")
                .font(.headline)
              Text("Create a template to quickly reuse your favorite routines.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
          } else {
            ForEach(templates) { template in
              Button {
                onSelect(template)
                dismiss()
              } label: {
                VStack(alignment: .leading, spacing: 6) {
                  HStack {
                    Text(template.name)
                      .font(.headline)
                    if template.isFavorite {
                      Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    }
                  }
                  Text("\(template.exerciseCount) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                  if let notes = template.notes, !notes.isEmpty {
                    Text(notes)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                  }
                }
                .padding(.vertical, 4)
              }
            }
          }
        }

        Section("Other Options") {
          Button {
            onCreateBlank()
            dismiss()
          } label: {
            Label("Create Blank Workout", systemImage: "plus")
          }

          Button {
            onManageTemplates()
            dismiss()
          } label: {
            Label("Manage Templates", systemImage: "square.stack.3d.up")
          }
        }
      }
      .navigationTitle("Choose Template")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  TemplatePickerView(
    onSelect: { _ in },
    onCreateBlank: {},
    onManageTemplates: {}
  )
  .modelContainer(AppContainer.preview.modelContainer)
}
