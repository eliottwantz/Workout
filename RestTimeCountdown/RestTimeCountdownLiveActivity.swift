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
  }

  let exercise: String
  let set: Int
  let totalSets: Int
  let reps: Int
  let weight: Double
  let timerId: String
  let endTime: Date
  let restTime: Int
  let timerInterval: ClosedRange<Date>
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
            VStack(alignment: .leading, spacing: 8) {
              Text(context.attributes.exercise)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(1)
                .multilineTextAlignment(.center)

              CurrentSetIndicators(
                color: context.state.userAccentColor,
                totalSets: context.attributes.totalSets,
                currentSet: context.attributes.set
              )
            }

            Spacer()

            VStack(alignment: .trailing) {
              LiveActivityCountdownTimer(
                timerInterval: context.attributes.timerInterval,
                color: context.state.userAccentColor,
                lineWidth: 8,
                size: 100
              )
            }
          }
          .frame(maxWidth: .infinity)
        }

      } compactLeading: {
        Text("\(context.attributes.set)/\(context.attributes.totalSets)")
          .foregroundStyle(context.state.userAccentColor)
      } compactTrailing: {
        Text("00:00")
          .hidden()
          .overlay(alignment: .leading) {
            Text(timerInterval: context.attributes.timerInterval, countsDown: true)
              .font(.caption)
              .monospacedDigit()
              .foregroundStyle(context.state.userAccentColor)
              .multilineTextAlignment(.center)
          }
      } minimal: {
        ProgressView(timerInterval: context.attributes.timerInterval) {
        } currentValueLabel: {
        }
        .progressViewStyle(.circular)
        .tint(context.state.userAccentColor)
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
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 8) {
            Text(attributes.exercise)
              .font(.title)
              .fontWeight(.bold)
              .lineLimit(1)
              .multilineTextAlignment(.center)

            CurrentSetIndicators(
              color: state.userAccentColor,
              totalSets: attributes.totalSets,
              currentSet: attributes.set
            )
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          LiveActivityCountdownTimer(
            timerInterval: attributes.timerInterval,
            color: state.userAccentColor
          )
        }
      }
      .padding()
      .background(state.userAccentColor.opacity(isDarkTheme ? 0.35 : 0.2))
    }
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
      let maxVisible = 4
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
    RestTimeCountdownAttributes(
      exercise: "Bench Press",
      set: 1,
      totalSets: 10,
      reps: 10,
      weight: 30.0,
      timerId: "abcde",
      endTime: .now.addingTimeInterval(TimeInterval(60)),
      restTime: 120,
      timerInterval: .now...Date().addingTimeInterval(60)
    )
  }
}

extension RestTimeCountdownAttributes.ContentState {
  fileprivate static var sample: RestTimeCountdownAttributes.ContentState {
    RestTimeCountdownAttributes.ContentState(
      displayWeightInLbs: true, userAccentColor: .yellow)
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
