//
//  TemplateListView.swift
//  Workout
//
//  Created by Codex on 2025-10-29.
//

import SwiftData
import SwiftUI

struct TemplateListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router
  @Query(
    sort: [SortDescriptor(\WorkoutTemplate.updatedAt, order: .reverse)]
  ) private var templates: [WorkoutTemplate]

  @State private var showingNewTemplateSheet = false
  @State private var newTemplateName = ""
  @State private var newTemplateNotes = ""
  @State private var templateToDelete: WorkoutTemplate?
  @State private var showingDeleteConfirmation = false
  @State private var templateToStart: WorkoutTemplate?
  @State private var showingStartConfirmation = false

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.templates.path) {
      List {
        if !templates.isEmpty {
          Button {
            resetNewTemplateForm()
            showingNewTemplateSheet = true
          } label: {
            Label("New Template", systemImage: "plus")
          }
        }

        ForEach(templates) { template in
          TemplateRowView(template: template)
            //            .overlay(alignment: .topTrailing) {
            //              if template.isFavorite {
            //                Image(systemName: "star.fill")
            //                  .foregroundStyle(.yellow)
            //                  .padding(8)
            //              }
            //            }
            .contentShape(Rectangle())
            .onTapGesture {
              router.templates.navigate(path: [.edit(template: template)])
            }
            .swipeActions(edge: .leading) {
              Button {
                templateToStart = template
                showingStartConfirmation = true
              } label: {
                Label("Start", systemImage: "play.fill")
              }
              .tint(.green)
            }
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                templateToDelete = template
                showingDeleteConfirmation = true
              } label: {
                Label("Delete", systemImage: "trash")
              }
              .tint(.red)
              Button {
                if let duplicated = try? modelContext.duplicateTemplate(template) {
                  router.templates.navigate(path: [.edit(template: duplicated)])
                }
              } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
              }
              .tint(.blue)
            }
            .contextMenu {
              Button {
                router.templates.navigate(path: [.edit(template: template)])
              } label: {
                Label("Edit", systemImage: "pencil")
              }

              Button {
                if let duplicated = try? modelContext.duplicateTemplate(template) {
                  router.templates.navigate(path: [.edit(template: duplicated)])
                }
              } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
              }

              Button {
                templateToStart = template
                showingStartConfirmation = true
              } label: {
                Label("Start workout", systemImage: "play.fill")
              }

              Button(role: .destructive) {
                templateToDelete = template
                showingDeleteConfirmation = true
              } label: {
                Label("Delete", systemImage: "trash")
              }
              .tint(.red)
            }
        }
      }
      .overlay {
        if templates.isEmpty {
          ContentUnavailableView {
            Label("No templates", systemImage: "square.stack.3d.up")
          } actions: {
            Button("Create Template", systemImage: "plus") {
              resetNewTemplateForm()
              showingNewTemplateSheet = true
            }
          }
        }
      }
      .navigationTitle("Templates")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            resetNewTemplateForm()
            showingNewTemplateSheet = true
          } label: {
            Label("New Template", systemImage: "plus")
          }
        }
      }
      .navigationDestination(for: TemplatesRouter.Route.self) { route in
        switch route {
        case .edit(let template):
          TemplateEditorView(template: template)
        }
      }
      .alert("Start Workout from Template", isPresented: $showingStartConfirmation) {
        Button("Start", role: .none) {
          if let template = templateToStart,
            let workout = try? modelContext.instantiateWorkout(from: template)
          {
            router.selectedTab = .workouts
            router.workouts.navigate(path: [.workoutDetail(workout: workout)])
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Do you want to create today's workout using \(templateToStart?.name ?? "this template")?"
        )
      }
      .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
        Button("Delete", role: .destructive) {
          if let template = templateToDelete {
            try? modelContext.deleteTemplate(template)
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This will delete the template but not any workouts created from it.")
      }
      .sheet(isPresented: $showingNewTemplateSheet) {
        TemplateInfoSheet(
          title: "New Template",
          name: $newTemplateName,
          notes: $newTemplateNotes,
          onSave: {
            guard !newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
              return
            }
            if let template = try? modelContext.createEmptyTemplate(
              name: newTemplateName,
              notes: newTemplateNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
            ) {
              router.templates.navigate(path: [.edit(template: template)])
            }
            resetNewTemplateForm()
          },
          onCancel: {
            resetNewTemplateForm()
          }
        )
        .presentationDetents([.medium])
      }
    }
  }

  private func deleteTemplates(offsets: IndexSet) {
    let templatesToDelete = offsets.map { templates[$0] }
    templatesToDelete.forEach { template in
      try? modelContext.deleteTemplate(template)
    }
  }

  private func resetNewTemplateForm() {
    newTemplateName = ""
    newTemplateNotes = ""
  }
}

private struct TemplateRowView: View {
  @Bindable var template: WorkoutTemplate

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(template.name)
          .font(.headline)

        if template.isFavorite {
          Image(systemName: "star.fill")
            .foregroundStyle(.yellow)
            .padding(8)
        }
      }

      HStack(spacing: 8) {
        Text("\(template.exerciseCount) exercises")
        Text("Updated \(template.updatedAt, format: .relative(presentation: .named))")
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)

      if let notes = template.notes, !notes.isEmpty {
        Text(notes)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 8)
  }
}

private struct TemplateInfoSheet: View {
  @Environment(\.dismiss) private var dismiss
  let title: String
  @Binding var name: String
  @Binding var notes: String
  var onSave: () -> Void
  var onCancel: () -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section("Details") {
          TextField("Template name", text: $name)
          TextField("Notes", text: $notes, axis: .vertical)
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) {
            onCancel()
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave()
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}

extension String {
  fileprivate func nilIfEmpty() -> String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}

#Preview {
  TemplateListView()
    .modelContainer(AppContainer.preview.modelContainer)
}
