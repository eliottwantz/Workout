//
//  AnalyticsView.swift
//  Workout
//
//  Created by Eliott on 2025-04-15.
//

import Charts
import SwiftData
import SwiftUI

struct AnalyticsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \ExerciseDefinition.name) private var exerciseDefinitions: [ExerciseDefinition]
  @State private var selectedExercise: ExerciseDefinition?
  @State private var selectedPeriod: Period = .threeMonths

  enum Period: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case year = "Year"
    case all = "All Time"
    var id: String { rawValue }
    var dateInterval: DateInterval {
      let now = Date()
      let calendar = Calendar.current
      switch self {
      case .week:
        return DateInterval(start: calendar.date(byAdding: .weekOfYear, value: -1, to: now)!, end: now)
      case .month:
        return DateInterval(start: calendar.date(byAdding: .month, value: -1, to: now)!, end: now)
      case .threeMonths:
        return DateInterval(start: calendar.date(byAdding: .month, value: -3, to: now)!, end: now)
      case .sixMonths:
        return DateInterval(start: calendar.date(byAdding: .month, value: -6, to: now)!, end: now)
      case .year:
        return DateInterval(start: calendar.date(byAdding: .year, value: -1, to: now)!, end: now)
      case .all:
        return DateInterval(start: .distantPast, end: now)
      }
    }
  }

  // Optional: allow direct navigation from ExerciseDefinitionDetailView
  var exerciseToShow: ExerciseDefinition?
  init(exerciseToShow: ExerciseDefinition? = nil) {
    self._selectedExercise = State(initialValue: exerciseToShow)
  }

  var body: some View {
    VStack(spacing: 0) {
      // Exercise Picker
      Picker("Exercise", selection: $selectedExercise) {
        ForEach(exerciseDefinitions) { def in
          Text(def.name).tag(Optional(def))
        }
      }
      .pickerStyle(.menu)
      .padding(.horizontal)

      // Period Picker
      Picker("Period", selection: $selectedPeriod) {
        ForEach(Period.allCases) { period in
          Text(period.rawValue).tag(period)
        }
      }
      .pickerStyle(.segmented)
      .padding()

      if let selectedExercise {
        let data = analyticsData(for: selectedExercise, period: selectedPeriod)
        if data.isEmpty {
          ContentUnavailableView {
            Label("No data", systemImage: "chart.xyaxis.line")
          } actions: {
          }
        } else {
          ChartView(data: data, period: selectedPeriod)
        }
      } else {
        ContentUnavailableView {
          Label("Select an exercise", systemImage: "dumbbell")
        } actions: {
        }
      }
    }
    .navigationTitle("Analytics")
  }

  // Aggregate best set per workout date for the selected exercise definition
  private func analyticsData(for def: ExerciseDefinition, period: Period) -> [PerformancePoint] {
    let interval = period.dateInterval
    let exercises = (def.exercises ?? []).filter { interval.contains($0.workoutDate) }
    // For each workout date, get the best set (max weight)
    let grouped = Dictionary(grouping: exercises, by: { $0.workoutDate })
    var points: [PerformancePoint] = []
    for (date, exercisesOnDate) in grouped {
      // Find the best set (max weight) among all sets for this date
      let bestSet =
        exercisesOnDate
        .flatMap { $0.orderedSets }
        .max(by: { $0.weight < $1.weight })
      if let bestSet {
        points.append(PerformancePoint(date: date, weight: bestSet.weight, reps: bestSet.reps))
      }
    }
    return points.sorted { $0.date < $1.date }
  }
}

struct PerformancePoint: Identifiable {
  let id = UUID()
  let date: Date
  let weight: Double
  let reps: Int
}

struct ChartView: View {
  let data: [PerformancePoint]
  let period: AnalyticsView.Period

  private var trendColor: Color {
    guard let first = data.first, let last = data.last else { return .gray }
    return last.weight >= first.weight ? .green : .red
  }

  var body: some View {
    VStack(spacing: 12) {
      Chart(data) {
        LineMark(
          x: .value("Date", $0.date),
          y: .value("Weight", $0.weight)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(trendColor)
        PointMark(
          x: .value("Date", $0.date),
          y: .value("Weight", $0.weight)
        )
        .foregroundStyle(trendColor)
      }
      .frame(height: 260)
      .padding(.horizontal)

      if let first = data.first, let last = data.last, first.weight != 0 {
        let percent = ((last.weight - first.weight) / first.weight) * 100
        HStack(spacing: 8) {
          Image(systemName: percent >= 0 ? "arrow.up" : "arrow.down")
            .foregroundColor(percent >= 0 ? .green : .red)
          Text(String(format: "%+.1f%%", percent))
            .foregroundColor(percent >= 0 ? .green : .red)
          Text("change in max weight")
            .foregroundColor(.secondary)
        }
        .font(.headline)
      }
    }
  }
}

#Preview {
  AnalyticsView()
    .modelContainer(AppContainer.preview.modelContainer)
}
