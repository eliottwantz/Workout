//
//  WindowGeometry.swift
//  Workout
//
//  Created by Eliott on 2025-04-13.
//

import SwiftUI

extension EnvironmentValues {
  @Entry var mainWindowSize: CGSize = .zero
  @Entry var mainWindowSafeAreaInsets: EdgeInsets = .init()
}

private struct GeometryEnvironmentModifier: ViewModifier {
  func body(content: Content) -> some View {
    GeometryReader { proxy in
      content
        .environment(\.mainWindowSize, proxy.size)
        .environment(\.mainWindowSafeAreaInsets, proxy.safeAreaInsets)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
          print("Main window size: x=\(proxy.size.width), y=\(proxy.size.height)")
        }
    }
  }
}

extension View {
  func withGeometryEnvironment() -> some View {
    modifier(GeometryEnvironmentModifier())
  }
}
