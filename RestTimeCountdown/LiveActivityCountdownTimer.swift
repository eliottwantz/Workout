//  LiveActivityCountdownTimer.swift
//  RestTimeCountdown
//
//  Created by Eliott on 2025-04-20.
//

import SwiftUI

struct LiveActivityCountdownTimer: View {
  let timerInterval: ClosedRange<Date>
  var color: Color
  var lineWidth: CGFloat = 10
  var size: CGFloat = 100

  var body: some View {
    ZStack {
      ProgressView(timerInterval: timerInterval) {
      } currentValueLabel: {
      }
      .progressViewStyle(.circular)
      .tint(color.opacity(0.8))

      // Timer Text - centered thanks to multilineTextAlignment(.center)
      HStack(alignment: .center, spacing: 0) {
        Text(timerInterval: timerInterval, countsDown: true)
          .font(.system(size: size / 4, weight: .bold, design: .rounded))
          .monospacedDigit()
          .contentTransition(.numericText())
          .animation(.linear, value: timerInterval)
          .multilineTextAlignment(.center)
      }
    }
    .frame(width: size, height: size)
    .animation(.easeInOut, value: timerInterval)
  }

}

#Preview {
  VStack(spacing: 20) {
    LiveActivityCountdownTimer(
      timerInterval: Date()...Date().addingTimeInterval(45),
      color: .blue
    )
    .background(Color.blue.opacity(0.8))
  }
}
