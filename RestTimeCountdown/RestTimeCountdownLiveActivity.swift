//
//  RestTimeCountdownLiveActivity.swift
//  RestTimeCountdown
//
//  Created by Eliott on 2025-04-18.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct RestTimeCountdownAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var displayWeightInLbs: Bool
    var userAccentColor: Color
    var exercise: String
    var set: Int
    var totalSets: Int
    var setForCurrentExercise: Int
    var setsForCurrentExercise: Int
    var reps: Int
    var weight: Double
    var endTime: Date
    var restTime: Int
    var isResting: Bool
    var timerInterval: ClosedRange<Date>

    // Next set details
    var nextExercise: String?
    var nextReps: Int?
    var nextWeight: Double?
    var setForNextExercise: Int?
    var setsForNextExercise: Int?
  }

  let timerId: String
}

struct RestTimeCountdownLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RestTimeCountdownAttributes.self) { context in
      LockeScreenView(attributes: context.attributes, state: context.state)
        .activitySystemActionForegroundColor(context.state.userAccentColor.contrastColor)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            if !context.state.isResting {

              VStack(alignment: .leading, spacing: 8) {
                Text(context.state.exercise)
                  .font(.title)
                  .fontWeight(.bold)
                  .lineLimit(1)
                  .multilineTextAlignment(.center)

                CurrentSetIndicators(
                  color: context.state.userAccentColor,
                  totalSets: context.state.setsForCurrentExercise,
                  currentSet: context.state.setForCurrentExercise
                )
                .padding(.leading)
              }

              Spacer()

              VStack(alignment: .trailing) {
                if context.state.isResting {
                  LiveActivityCountdownTimer(
                    timerInterval: context.state.timerInterval,
                    color: context.state.userAccentColor,
                    lineWidth: 8,
                    size: 100
                  )
                } else {
                  VStack(alignment: .trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                      Text(
                        context.state.weight.formattedWeight(
                          inLbs: context.state.displayWeightInLbs)
                      )
                      .font(.title2)
                      .bold()
                      .foregroundStyle(context.state.userAccentColor)
                      Text("\(context.state.reps) reps")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.secondary)
                    }
                  }
                }
              }

            } else {
              Group {
                HStack(spacing: 12) {
                  LiveActivityCountdownTimer(
                    timerInterval: context.state.timerInterval,
                    color: context.state.userAccentColor
                  )

                  Image(systemName: "arrowshape.forward.fill")
                    .foregroundStyle(context.state.userAccentColor)
                    .font(.title)

                }

                Group {
                  if let nextExercise = context.state.nextExercise,
                    let nextReps = context.state.nextReps,
                    let nextWeight = context.state.nextWeight,
                    let setForNextExercise = context.state.setForNextExercise,
                    let setsForNextExercise = context.state.setsForNextExercise
                  {

                    VStack(alignment: .trailing, spacing: 4) {
                      Text(nextExercise)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(1)

                      HStack(spacing: 8) {
                        Text("\(nextReps) reps")
                          .font(.subheadline)
                          .bold()
                          .foregroundStyle(context.state.userAccentColor)
                        Text("at")
                          .font(.subheadline)
                        Text(nextWeight.formattedWeight(inLbs: context.state.displayWeightInLbs))
                          .font(.subheadline)
                          .bold()
                          .foregroundStyle(context.state.userAccentColor)
                      }

                      Text("Set \(context.state.set+1) out of \(context.state.totalSets)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                      Spacer()

                      CurrentSetIndicators(
                        color: context.state.userAccentColor,
                        totalSets: setsForNextExercise,
                        currentSet: setForNextExercise
                      )
                      .padding(.trailing)
                    }
                  } else {
                    Text("Workout Completed! 🏆")
                      .font(.title2)
                      .foregroundStyle(context.state.userAccentColor)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
              }
            }
          }
          .frame(maxWidth: .infinity)
        }
      } compactLeading: {
        Text("\(context.state.setForCurrentExercise)/\(context.state.setsForCurrentExercise)")
          .foregroundStyle(context.state.userAccentColor)
      } compactTrailing: {
        if context.state.isResting {
          Text("00:00")
            .hidden()
            .overlay(alignment: .leading) {
              Text(timerInterval: context.state.timerInterval, countsDown: true)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(context.state.userAccentColor)
                .multilineTextAlignment(.center)
            }
        } else {
          Text(context.state.weight.formattedWeight(inLbs: context.state.displayWeightInLbs))
            .font(.subheadline)
            .foregroundStyle(context.state.userAccentColor)
        }
      } minimal: {
        if context.state.isResting {
          ProgressView(timerInterval: context.state.timerInterval) {
          } currentValueLabel: {
          }
          .progressViewStyle(.circular)
          .tint(context.state.userAccentColor)
        } else {
          Text("\(context.state.setForCurrentExercise)/\(context.state.setsForCurrentExercise)")
            .foregroundStyle(context.state.userAccentColor)
        }
      }
      .keylineTint(context.state.userAccentColor)
    }
  }
}

private struct LockeScreenView: View {
  @Environment(\.colorScheme) private var colorScheme
  let attributes: RestTimeCountdownAttributes
  let state: RestTimeCountdownAttributes.ContentState

  private var isDarkTheme: Bool {
    colorScheme == .dark
  }

  var body: some View {
    ZStack {
      HStack(alignment: .center) {
        if !state.isResting {
          VStack(alignment: .leading, spacing: 8) {
            Text(state.exercise)
              .font(.title)
              .fontWeight(.bold)
              .lineLimit(2)

            CurrentSetIndicators(
              color: state.userAccentColor,
              totalSets: state.setsForCurrentExercise,
              currentSet: state.setForCurrentExercise
            )
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          VStack(alignment: .trailing, spacing: 4) {
            Text(state.weight.formattedWeight(inLbs: state.displayWeightInLbs))
              .font(.title2)
              .fontWeight(.bold)
              .foregroundStyle(state.userAccentColor)
            Text("\(state.reps) reps")
              .font(.headline)
              .foregroundStyle(.primary)

            Spacer()

            Text("\(state.set)/\(state.totalSets) sets")
              .font(.headline)
              .foregroundStyle(.secondary)
          }
        } else {
          VStack(spacing: 4) {
            if let nextExercise = state.nextExercise {
              Text(nextExercise)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)
            }

            HStack(spacing: 8) {
              LiveActivityCountdownTimer(
                timerInterval: state.timerInterval,
                color: state.userAccentColor
              )

              Group {
                if let nextReps = state.nextReps,
                  let nextWeight = state.nextWeight,
                  let setForNextExercise = state.setForNextExercise,
                  let setsForNextExercise = state.setsForNextExercise
                {

                  VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                      Text("\(nextReps) reps")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(state.userAccentColor)
                      Text("at")
                        .font(.subheadline)
                      Text(nextWeight.formattedWeight(inLbs: state.displayWeightInLbs))
                        .font(.headline)
                        .bold()
                        .foregroundStyle(state.userAccentColor)
                    }

                    Text("Set \(state.set+1) out of \(state.totalSets)")
                      .font(.subheadline)
                      .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                      Image(systemName: "arrowshape.forward.fill")
                        .foregroundStyle(state.userAccentColor)
                        .font(.title)

                      CurrentSetIndicators(
                        color: state.userAccentColor,
                        totalSets: setsForNextExercise,
                        currentSet: setForNextExercise
                      )
                    }

                  }
                } else {
                  Text("Workout Completed! 🏆")
                    .font(.title2)
                    .foregroundStyle(state.userAccentColor)
                }
              }
              .frame(maxWidth: .infinity, alignment: .trailing)
            }

          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding()
    .background(state.userAccentColor.opacity(isDarkTheme ? 0.35 : 0.2))
  }
}

struct CurrentSetIndicators: View {
  let color: Color
  let totalSets: Int
  let currentSet: Int

  var body: some View {
    HStack(spacing: 8) {
      let total = totalSets
      let current = currentSet
      let maxVisible = 5
      let (start, end): (Int, Int) = {
        if total <= maxVisible {
          return (1, total)
        } else if current <= 2 {
          return (1, maxVisible)
        } else if current >= total - 1 {
          return (total - maxVisible + 1, total)
        } else {
          return (current - 1, min(current + 2, total))
        }
      }()
      ForEach(start...end, id: \.self) { idx in
        ZStack {
          Circle()
            .stroke(idx == current ? color : Color.primary.opacity(0.8), lineWidth: 2)
            .frame(width: 24, height: 24)
            .background(
              Circle()
                .fill(idx == current ? color : Color.clear)
                .frame(width: 24, height: 24)
            )
          Text("\(idx)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(idx == current ? color.contrastColor : Color.primary.opacity(0.8))
        }
      }
    }
  }
}

extension RestTimeCountdownAttributes {
  fileprivate static var preview: RestTimeCountdownAttributes {
    RestTimeCountdownAttributes(timerId: "abcde")
  }
}

extension RestTimeCountdownAttributes.ContentState {
  fileprivate static var sample: RestTimeCountdownAttributes.ContentState {
    RestTimeCountdownAttributes.ContentState(
      displayWeightInLbs: true,
      userAccentColor: .yellow,
      exercise: "Bench Press",
      set: 1,
      totalSets: 10,
      setForCurrentExercise: 1,
      setsForCurrentExercise: 4,  // Example: Bench Press has 4 sets
      reps: 10,
      weight: 30.0,
      endTime: .now.addingTimeInterval(TimeInterval(60)),
      restTime: 120,
      isResting: true,
      timerInterval: .now...Date().addingTimeInterval(60)
    )
  }
}

//#Preview("Notification", as: .content, using: RestTimeCountdownAttributes.preview) {
//  RestTimeCountdownLiveActivity()
//} contentStates: {
//  RestTimeCountdownAttributes.ContentState.sample
//}
//
//#Preview("Compact", as: .dynamicIsland(.compact), using: RestTimeCountdownAttributes.preview) {
//  RestTimeCountdownLiveActivity()
//} contentStates: {
//  RestTimeCountdownAttributes.ContentState.sample
//}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: RestTimeCountdownAttributes.preview) {
  RestTimeCountdownLiveActivity()
} contentStates: {
  RestTimeCountdownAttributes.ContentState.sample
}
//
//#Preview("Minimal", as: .dynamicIsland(.minimal), using: RestTimeCountdownAttributes.preview) {
//  RestTimeCountdownLiveActivity()
//} contentStates: {
//  RestTimeCountdownAttributes.ContentState.sample
//}
