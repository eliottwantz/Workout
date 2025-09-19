//
//  WindowGeometry.swift
//  Workout
//
//  Created by Eliott on 2025-04-13.
//

import SwiftUI
import UIKit

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

extension UIApplication {
  static var main: UIScreen? {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen
  }

  static var height: CGFloat {
    main?.bounds.height ?? 0
  }

  static var width: CGFloat {
    main?.bounds.width ?? 0
  }

  static var size: CGSize {
    main?.bounds.size ?? .zero
  }

  static var safeAreaInsets: UIEdgeInsets {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets
      ?? .zero
  }

  static var displayCornerRadius: CGFloat {
    main?.displayCornerRadius ?? 41
  }
}

// MARK: - Corner Radius Extension
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

private struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

/// https://github.com/kylebshr/ScreenCorners
extension UIScreen {
  private static let cornerRadiusKey: String = {
    let components = ["Radius", "Corner", "display", "_"]
    return components.reversed().joined()
  }()

  /// The corner radius of the display. Uses a private property of `UIScreen`,
  /// and may report 0 if the API changes.
  public var displayCornerRadius: CGFloat {
    guard let cornerRadius = value(forKey: Self.cornerRadiusKey) as? CGFloat else {
      assertionFailure("Failed to detect screen corner radius")
      return 0
    }

    return cornerRadius
  }
}
