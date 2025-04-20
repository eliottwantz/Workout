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
    // Dynamic stateful properties about your activity go here!
    var displayWeightInLbs: Bool
    var userAccentColor: Color
    var timerInterval: ClosedRange<Date>
  }

  // Fixed non-changing properties about your activity go here!
  let nextExercise: String
  let nextSet: Int
  let totalSets: Int
  let nextReps: Int
  let nextWeight: Double
  let timerId: String
}


struct RestTimeCountdownLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RestTimeCountdownAttributes.self) { context in
      // Lock screen/banner UI goes here
      LockeScreenView(attributes: context.attributes, state: context.state, timerInterval: context.state.timerInterval)
        .activityBackgroundTint(context.state.userAccentColor.opacity(0.8))
        .activitySystemActionForegroundColor(context.state.userAccentColor.contrastColor)

    } dynamicIsland: { context in
      return DynamicIsland {
        // Expanded UI goes here.  Compose the expanded UI through
        // various regions, like leading/trailing/center/bottom
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading) {
            HStack(spacing: 4) {
              Text("Set \(context.attributes.nextSet)/\(context.attributes.totalSets)")
                .font(.subheadline)
              Text("•")
                .font(.subheadline)
              Text("\(context.attributes.nextReps) reps")
                .font(.subheadline)
              Text("•")
                .font(.subheadline)
              Text("\(context.attributes.nextWeight.formattedWeight(inLbs: context.state.displayWeightInLbs))")
                .font(.subheadline)
            }
          }
          .padding(.top)
        }
        DynamicIslandExpandedRegion(.trailing) {
          HStack {
            Text(timerInterval: context.state.timerInterval)
              .font(.system(size: 30, weight: .bold, design: .rounded))
              .monospacedDigit()
              .contentTransition(.numericText())
              .foregroundColor(context.state.userAccentColor.foregroundColor)
              .frame(maxWidth: 100)
          }
          .padding(.top)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack {
            HStack(alignment: .firstTextBaseline) {
              Text("NEXT: ")
              Text(context.attributes.nextExercise)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            }

            ProgressView(timerInterval: context.state.timerInterval) {
            } currentValueLabel: {
            }
            .progressViewStyle(.linear)
            .tint(context.state.userAccentColor.foregroundColor)
            .scaleEffect(x: 1, y: 1.5, anchor: .center)
          }
        }
      } compactLeading: {
        Text("\(context.attributes.nextSet)/\(context.attributes.totalSets)")
        .foregroundStyle(context.state.userAccentColor.foregroundColor)
      } compactTrailing: {
        ProgressView(timerInterval: context.state.timerInterval) {
        } currentValueLabel: {
        }
        .progressViewStyle(.circular)
        .tint(context.state.userAccentColor.foregroundColor)
      } minimal: {
        ProgressView(timerInterval: context.state.timerInterval) {
        } currentValueLabel: {
        }
        .progressViewStyle(.circular)
        .tint(context.state.userAccentColor.foregroundColor)
        .scaleEffect(x: 1.5, y: 1.5, anchor: .center)
      }
      .keylineTint(context.state.userAccentColor)
    }
  }
}

private struct LockeScreenView: View {
  let attributes: RestTimeCountdownAttributes
  let state: RestTimeCountdownAttributes.ContentState
  let timerInterval: ClosedRange<Date>

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 5) {
        HStack(alignment: .firstTextBaseline) {
          Text(attributes.nextExercise)
            .font(.title)
            .fontWeight(.bold)
            .lineLimit(1)
            .multilineTextAlignment(.center)
          Text("coming up next")
            .font(.caption)
            .lineLimit(1)
            .multilineTextAlignment(.center)
        }

        HStack(spacing: 4) {
          Text("Set \(attributes.nextSet)/\(attributes.totalSets)")
            .font(.subheadline)
          Text("•")
            .font(.subheadline)
          Text("\(attributes.nextReps) reps")
            .font(.subheadline)
          Text("•")
            .font(.subheadline)
          Text("\(attributes.nextWeight.formattedWeight(inLbs: state.displayWeightInLbs))")
            .font(.subheadline)
        }
      }

      VStack(spacing: 2) {
        Text(timerInterval: timerInterval)
          .font(.system(size: 30, weight: .bold, design: .rounded))
          .monospacedDigit()
          .contentTransition(.numericText())
          .foregroundColor(state.userAccentColor.foregroundColor)

        ProgressView(timerInterval: timerInterval) {
        } currentValueLabel: {
        }
        .progressViewStyle(.linear)
        .tint(state.userAccentColor.foregroundColor)
        .scaleEffect(x: 1, y: 1.5, anchor: .center)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

    }
    .foregroundStyle(state.userAccentColor.contrastColor)
    .padding(.vertical, 20)
    .padding(.horizontal, 20)
  }
}

extension RestTimeCountdownAttributes {
  fileprivate static var preview: RestTimeCountdownAttributes {
    RestTimeCountdownAttributes(
      nextExercise: "Squat", nextSet: 2, totalSets: 3, nextReps: 10, nextWeight: 30.0, timerId: "abcde")
  }
}

extension RestTimeCountdownAttributes.ContentState {
  fileprivate static var sample: RestTimeCountdownAttributes.ContentState {
    RestTimeCountdownAttributes.ContentState(displayWeightInLbs: true, userAccentColor: .blue, timerInterval: .now...Date().addingTimeInterval(60))
  }
}

#Preview("Notification", as: .content, using: RestTimeCountdownAttributes.preview) {
  RestTimeCountdownLiveActivity()
} contentStates: {
  RestTimeCountdownAttributes.ContentState.sample
}

#Preview("Compact", as: .dynamicIsland(.compact), using: RestTimeCountdownAttributes.preview) {
  RestTimeCountdownLiveActivity()
} contentStates: {
  RestTimeCountdownAttributes.ContentState.sample
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: RestTimeCountdownAttributes.preview) {
  RestTimeCountdownLiveActivity()
} contentStates: {
  RestTimeCountdownAttributes.ContentState.sample
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: RestTimeCountdownAttributes.preview) {
  RestTimeCountdownLiveActivity()
} contentStates: {
  RestTimeCountdownAttributes.ContentState.sample
}
