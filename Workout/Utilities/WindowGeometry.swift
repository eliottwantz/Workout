//
//  WindowGeometry.swift
//  Workout
//
//  Created by Eliott on 2025-04-13.
//

import SwiftUI

private struct MainWindowSizeKey: EnvironmentKey {
  static let defaultValue: CGSize = .zero
}

private struct MainWindowSafeAreaInsetsKey: EnvironmentKey {
  static let defaultValue: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension EnvironmentValues {
  var mainWindowSize: CGSize {
    get { self[MainWindowSizeKey.self] }
    set { self[MainWindowSizeKey.self] = newValue }
  }

  var mainWindowSafeAreaInsets: EdgeInsets {
    get { self[MainWindowSafeAreaInsetsKey.self] }
    set { self[MainWindowSafeAreaInsetsKey.self] = newValue }
  }
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
