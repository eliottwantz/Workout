//
//  StartedWorkoutBottomSheetView.swift
//  Workout
//
//  Created by Copilot on 2025-04-10.
//

import SwiftData
import SwiftUI

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

extension View {
  /// Adds a bottom sheet to the view.
  func startedWorkoutBottomSheet() -> some View {
    modifier(StartedWorkoutBottomSheetViewModifier())
  }

  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

private struct StartedWorkoutBottomSheetViewModifier: ViewModifier {
  @Environment(\.startedWorkoutViewModel) private var viewModel

  func body(content: Content) -> some View {

    content
      .padding(.bottom, viewModel.workout != nil ? 80 : 0)
      .overlay(
        Group {
          if let workout = viewModel.workout {
            StartedWorkoutBottomSheetView(workout: workout)
          }
        }
      )
  }
}

private struct StartedWorkoutBottomSheetView: View {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.userAccentColor) private var userAccentColor

  private var collapsedHeight: CGFloat = 120
  @State var offset: CGFloat = 0
  @State private var isExpanded: Bool = true

  @Bindable var workout: Workout

  init(workout: Workout) {
    self.workout = workout
  }

  var body: some View {
    @Bindable var viewModel = viewModel

    GeometryReader { geometry in

      let height = geometry.frame(in: .global).height
      let topOffset = -height + collapsedHeight

      Color(UIColor.systemBackground)
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .offset(y: height - collapsedHeight)
        .offset(y: offset)

      VStack {
        if isExpanded {
          HStack {
            Button {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.stop()
              }
              withAnimation(.snappy(duration: 0.3)) {
                offset = 0
              }
            } label: {
              Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
            }

            Spacer()
            Capsule()
              .frame(width: 40, height: 5)
              .foregroundStyle(.gray)
            Spacer()

            // For symmetry
            Image(systemName: "xmark")
              .font(.title2)
              .foregroundColor(.clear)
              .padding()
          }
          .frame(maxWidth: .infinity)
          .padding(.top, isExpanded ? 50 : 8)
          .background(Color(UIColor.systemBackground))
          .onTapGesture { isExpanded = false }
        }

        if isExpanded {
          StartedWorkoutView(workout: workout)
            .padding(.bottom, 47)
        } else {
          HStack {
            Text("This is the collapsed content")
              .font(.title)
          }
        }

      }
      .frame(maxHeight: .infinity, alignment: .top)
      .frame(maxWidth: .infinity)
      //        .background(userAccentColor.opacity(0.2))
      .background(isExpanded ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
      .cornerRadius(30, corners: [.topLeft, .topRight])
      .offset(y: height - collapsedHeight)
      .offset(y: offset)
      .onChange(of: isExpanded) { oldValue, newValue in
        withAnimation(.snappy(duration: 0.3)) {
          print("onChange isExpanded: \(newValue)")
          if newValue {
            offset = topOffset
          } else {
            offset = 0
          }
          print("onChange isExpanded offset: \(offset)")
        }
      }
      .onTapGesture {
        guard !isExpanded else { return }
        isExpanded = true
      }
      .gesture(
        DragGesture()
          .onChanged { value in
            guard isExpanded else { return }
            print("onChanged value: \(value.translation.height)")
            let translation = max(value.translation.height, 0)
            offset = topOffset + translation
            print("onChanged offset: \(offset)")
          }
          .onEnded { value in
            guard isExpanded else { return }
            withAnimation(.snappy(duration: 0.3)) {

              print("onEnded value: \(value.translation.height)")
              print("onEnded offset: \(offset)")

              let translation = max(value.translation.height, 0)
              let velocity = value.predictedEndTranslation.height

              if translation + velocity > (geometry.size.height * 0.5) {
                isExpanded = false
                offset = 0
              } else {
                isExpanded = true
                offset = topOffset
              }
            }
          }
      )
      .onAppear {
        withAnimation(.snappy(duration: 0.3)) {
          offset = topOffset
        }
      }
    }
    .ignoresSafeArea(edges: .all)
  }

}

#Preview {
  @Previewable @State var startedWorkoutViewModel = StartedWorkoutViewModel()
  let workouts = try? AppContainer.preview.modelContainer.mainContext.fetch(FetchDescriptor<Workout>())
  if let workouts = workouts, let workout = workouts.first {

    VStack {
      WorkoutDetailView(workout: workout)
        .startedWorkoutBottomSheet()
    }
    .environment(\.startedWorkoutViewModel, startedWorkoutViewModel)
    .modelContainer(AppContainer.preview.modelContainer)
  } else {
    Text("Failed no workout")
  }
}
