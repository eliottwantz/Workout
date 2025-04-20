//
//  KeyboardIsShownEVK.swift
//  Workout
//
//  Created by Eliott on 2025-04-04.
//

import SwiftUI


extension EnvironmentValues {
  @Entry var keyboardIsShown = false
}

struct HideKeyboardGestureModifier: ViewModifier {
  @Environment(\.keyboardIsShown) var keyboardIsShown

  func body(content: Content) -> some View {
    content
      .gesture(
        TapGesture().onEnded {
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }, including: keyboardIsShown ? .all : .none)
  }
}

extension View {
  func dismissKeyboardOnTap() -> some View {
    modifier(HideKeyboardGestureModifier())
  }
}
