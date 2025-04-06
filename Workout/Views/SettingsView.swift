//
//  SettingsView.swift
//  Workout
//
//  Created by Eliott on 2025-04-06.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage("userAccentColor") var storedColor: Color = .yellow

  var body: some View {

    ZStack {
      storedColor

      ColorPicker("Color theme", selection: $storedColor)
        .padding(.horizontal)
        .foregroundStyle(storedColor.contrastColor)
        .fontWeight(.semibold)
        .font(.title)
        .padding()
    }
  }
}

#Preview {
  SettingsView()
}
