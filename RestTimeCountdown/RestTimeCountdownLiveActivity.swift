//
//  RestTimeCountdownLiveActivity.swift
//  RestTimeCountdown
//
//  Created by Eliott on 2025-04-18.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct RestTimeCountdownLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RestTimeCountdownAttributes.self) { context in
      // Lock screen/banner UI goes here
      LockeScreenView(attributes: context.attributes, state: context.state)
        .activityBackgroundTint(context.state.userAccentColor.opacity(0.8))
        .activitySystemActionForegroundColor(context.state.userAccentColor.contrastColor)

    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded UI goes here.  Compose the expanded UI through
        // various regions, like leading/trailing/center/bottom
        DynamicIslandExpandedRegion(.leading) {
          Text("Leading")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("Trailing")
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text("Bottom")
          // more content
        }
      } compactLeading: {
        Text("L")
      } compactTrailing: {
        Text("T")
      } minimal: {
        Text("M")
      }
      //            .widgetURL(URL(string: "http://www.apple.com"))
      .keylineTint(Color.red)
    }
  }
}

private struct LockeScreenView: View {
  let attributes: RestTimeCountdownAttributes
  let state: RestTimeCountdownAttributes.ContentState

  var body: some View {
    let timerInterval = attributes.startTime...Date().addingTimeInterval(TimeInterval(attributes.restTime))
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 5) {
        HStack(alignment: .firstTextBaseline) {
          Text("NEXT: ")
          Text(attributes.nextExercise)
            .font(.title)
            .fontWeight(.bold)
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
          .foregroundColor(state.userAccentColor)

        ProgressView(timerInterval: timerInterval) {
        } currentValueLabel: {
        }
        .progressViewStyle(.linear)
        .tint(state.userAccentColor)
        .scaleEffect(x: 1, y: 1.5, anchor: .center)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

    }
    .padding(.vertical, 20)
    .padding(.horizontal, 20)
  }
}

extension RestTimeCountdownAttributes {
  fileprivate static var preview: RestTimeCountdownAttributes {
    RestTimeCountdownAttributes(
      nextExercise: "Squat", nextSet: 2, totalSets: 3, nextReps: 10, nextWeight: 30.0, timerId: "abcde",
      restTime: 120, startTime: .now)
  }
}

extension RestTimeCountdownAttributes.ContentState {
  fileprivate static var sample: RestTimeCountdownAttributes.ContentState {
    RestTimeCountdownAttributes.ContentState(displayWeightInLbs: true, userAccentColor: .blue)
  }
}

#Preview("Notification", as: .content, using: RestTimeCountdownAttributes.preview) {
  RestTimeCountdownLiveActivity()
} contentStates: {
  RestTimeCountdownAttributes.ContentState.sample
}
