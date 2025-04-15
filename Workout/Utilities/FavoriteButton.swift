//
//  FavoriteButton.swift
//  Workout
//
//  Created by Eliott on 2025-04-15.
//

import SwiftUI

struct FavoriteButton: View {
  var isSet: Bool

  var body: some View {
    Label("Toggle Favorite", systemImage: isSet ? "star.fill" : "star")
      .labelStyle(.iconOnly)
      .foregroundStyle(isSet ? .yellow : .gray)
  }
}

struct EditableFavoriteButton: View {
  @Binding var isSet: Bool

  var body: some View {
    Button {
      isSet.toggle()
    } label: {
      Label("Toggle Favorite", systemImage: isSet ? "star.fill" : "star")
        .labelStyle(.iconOnly)
        .foregroundStyle(isSet ? .yellow : .gray)
    }
  }
}

#Preview {
  FavoriteButton(isSet: true)
}
