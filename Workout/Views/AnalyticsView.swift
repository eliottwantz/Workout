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
  @State private var selectedPeriod: Period = .month

  enum Period: String, CaseIterable, Identifiable {
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    case all = "All Time"
    var id: String { rawValue }
    var dateInterval: DateInterval {
      let now = Date()
      let calendar = Calendar.current
      switch self {
      case .month:
        return DateInterval(start: calendar.date(byAdding: .month, value: -1, to: now)!, end: now)
      case .threeMonths:
        return DateInterval(start: calendar.date(byAdding: .month, value: -3, to: now)!, end: now)
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

  // Computed property to update data when either selectedExercise or selectedPeriod changes
  private var currentData: [PerformancePoint]? {
    guard let selectedExercise else { return nil }
    return analyticsData(for: selectedExercise, period: selectedPeriod)
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

      if let data = currentData {
        if data.isEmpty {
          ContentUnavailableView {
            Label("No data", systemImage: "chart.xyaxis.line")
          } actions: {
          }
        } else {
          VStack {
            ChartView(data: data, period: selectedPeriod)
          }
          .frame(maxHeight: .infinity)
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

  @State private var selectedElement: PerformancePoint?
  @State private var dragLocation: CGPoint = .zero
  @AppStorage(DisplayWeightInLbsKey) private var displayWeightInLbs: Bool = false // Access the setting

  private var trendColor: Color {
    guard let first = data.first, let last = data.last else { return .gray }
    return last.weight >= first.weight ? .green : .red
  }

  var body: some View {
    // Compute x-axis start date according to requirements
    let xStart: Date = {
      if let firstDate = data.first?.date {
        return max(firstDate, period.dateInterval.start)
      } else {
        return period.dateInterval.start
      }
    }()

    // Compute y-axis domain based on the selected unit
    let yDomain: ClosedRange<Double> = {
        let conversionFactor = displayWeightInLbs ? 2.20462 : 1.0
        let weights = data.map { $0.weight * conversionFactor } // Convert weights first
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? (displayWeightInLbs ? 2.2 : 1.0) // Use 1kg or ~2.2lbs if no data
        // Add some padding based on the converted scale
      let padding = (maxWeight - minWeight) * 0.75 // 75% padding
        // Ensure padding doesn't make minWeight negative if minWeight is close to 0
        let finalMin = max(0, minWeight - padding) 
        return finalMin...(maxWeight + padding)
    }()

    VStack(spacing: 12) {
      Chart { // Use the Chart content builder
        // Existing LineMark and PointMark
        ForEach(data) { point in
          // Convert weight for plotting if displaying in lbs
          let plotWeight = displayWeightInLbs ? point.weight * 2.20462 : point.weight
          LineMark(
            x: .value("Date", point.date),
            y: .value("Weight", plotWeight) // Use converted weight for plotting
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(trendColor)
          PointMark(
            x: .value("Date", point.date),
            y: .value("Weight", plotWeight) // Use converted weight for plotting
          )
          .foregroundStyle(trendColor)
        }

        // Add the vertical rule mark conditionally here
        if let selected = selectedElement {
           // Convert selected weight for RuleMark positioning if displaying in lbs
           let selectedPlotWeight = displayWeightInLbs ? selected.weight * 2.20462 : selected.weight
          RuleMark(x: .value("Date", selected.date))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4])) // Dotted line style
            .foregroundStyle(.gray.opacity(0.5)) // Subtle gray color
            .annotation(position: .top, alignment: .leading) { 
                 // Annotation content can go here if desired (empty for now)
            }
            // Position the RuleMark based on the potentially converted weight
            .foregroundStyle(.clear) // Make the rule mark itself invisible if only used for annotation line
            .zIndex(-1) // Ensure it's behind other marks if needed
            // We position the annotation line using the selectedPlotWeight implicitly via the RuleMark's y position
        }
      } // End Chart content builder
      .chartXScale(domain: xStart...period.dateInterval.end)
      .chartYScale(domain: yDomain) // Apply the calculated Y-axis domain
      .chartYAxis { // Customize Y-axis labels
          AxisMarks(values: .automatic) { value in
              AxisGridLine()
              AxisTick()
              AxisValueLabel {
                  if let numericValue = value.as(Double.self) {
                      let unit = displayWeightInLbs ? "lbs" : "kg"
                      Text(String(format: "%.0f %@", numericValue, unit)) // Format with unit
                  }
              }
          }
      }
      .chartOverlay { proxy in
        GeometryReader { geometry in
          let plotAreaOrigin = geometry[proxy.plotAreaFrame].origin // Calculate origin once

          ZStack(alignment: .topLeading) { // Use ZStack to layer gesture area and tooltip
              Rectangle() // Gesture area
                  .fill(Color.clear).contentShape(Rectangle())
                  .gesture(
                    DragGesture(minimumDistance: 0)
                      .onChanged { value in
                        dragLocation = value.location // Keep dragLocation if needed elsewhere
                        let xPosition = value.location.x - plotAreaOrigin.x // Use calculated origin
                        let plotWidth = proxy.plotAreaSize.width
                        guard plotWidth > 0, !data.isEmpty else { selectedElement = nil; return }
                        let percent = min(max(xPosition / plotWidth, 0), 1)
                        let start = xStart.timeIntervalSinceReferenceDate
                        let end = period.dateInterval.end.timeIntervalSinceReferenceDate
                        let time = start + percent * (end - start)
                        let date = Date(timeIntervalSinceReferenceDate: time)
                        // Find the closest data point
                        if let nearest = data.min(by: { abs($0.date.timeIntervalSince1970 - date.timeIntervalSince1970) < abs($1.date.timeIntervalSince1970 - date.timeIntervalSince1970) }) {
                          selectedElement = nearest
                        }
                      }
                      .onEnded { _ in
                        selectedElement = nil
                      }
                  )

              // Tooltip rendering
              if let selected = selectedElement {
                 // Convert selected weight for positioning if displaying in lbs
                 let selectedPlotWeight = displayWeightInLbs ? selected.weight * 2.20462 : selected.weight
                 // Use the potentially converted weight to find the position
                 if let positionInPlot = proxy.position(for: (selected.date, selectedPlotWeight)) {
                    let finalX = plotAreaOrigin.x + positionInPlot.x
                    let finalY = plotAreaOrigin.y + positionInPlot.y

                    VStack(alignment: .leading, spacing: 4) {
                      Text(selected.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.primary)
                      // Display weight in tooltip using original value + conversion
                      Text(displayWeightInLbs ? String(format: "%.1f lbs", selected.weight * 2.20462) : String(format: "%.1f kg", selected.weight))
                        .font(.headline)
                        .foregroundColor(trendColor)
                    }
                    .padding(8)
                    .background(.regularMaterial) // Changed from .thinMaterial to .regularMaterial
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    // Offset the tooltip from the top-left corner of the ZStack (GeometryReader)
                    // ... existing code ...
                    .offset(x: finalX + 12, y: finalY - 40) // Adjust offset as needed
                }
              }
          } // End ZStack
        } // End GeometryReader
      } // End chartOverlay

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
    .padding()
  }
}

#Preview {
  NavigationStack {
    AnalyticsView()
      .modelContainer(AppContainer.preview.modelContainer)
  }
}
