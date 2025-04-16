//
//  RestTimePickerView.swift
//  Workout
//
//  Created by Eliott on 2025-04-05.
//

import SwiftUI

struct RestTimePickerView: View {
  @Binding var restTime: Int
  @Environment(\.dismiss) private var dismiss
  @Environment(\.userAccentColor) private var userAccentColor

  private let restTimeOptions = [60, 90, 120, 150, 180, 240, 300]

  var body: some View {
    NavigationStack {
      List {
        ForEach(restTimeOptions, id: \.self) { seconds in
          Button {
            restTime = seconds
            dismiss()
          } label: {
            HStack {
              Text(seconds.formattedRestTime)
              Spacer()
              if restTime == seconds {
                Image(systemName: "checkmark")
                  .foregroundColor(userAccentColor)
              }
            }
          }
          .foregroundColor(.primary)
        }
      }
      .navigationTitle("Rest Time")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}
