//
//  StartedWorkoutBottomSheetView.swift
//  Workout
//
//  Created by Copilot on 2025-04-10.
//

import SwiftUI

@Observable
class StartedWorkoutViewModel {
  var isExpanded: Bool = true
  var workout: Workout?

  var isPresented: Bool {
    workout != nil
  }

  func start(workout: Workout) {
    withAnimation {
      self.workout = workout
      self.isExpanded = true
    }
  }

  func stop() {
    withAnimation {
      self.workout = nil
      self.isExpanded = false
    }
  }
}

private struct StartedWorkoutViewModelKey: EnvironmentKey {
  static let defaultValue = StartedWorkoutViewModel()
}

extension EnvironmentValues {
  var startedWorkoutViewModel: StartedWorkoutViewModel {
    get { self[StartedWorkoutViewModelKey.self] }
    set { self[StartedWorkoutViewModelKey.self] = newValue }
  }
}

struct RoundedCorner: Shape {
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
      StartedWorkoutBottomSheetView(parentView: self)
  }

  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct StartedWorkoutBottomSheetView<ParentView: View>: View {
  @Environment(\.startedWorkoutViewModel) private var viewModel
  @Environment(\.userAccentColor) private var userAccentColor

  var parentView: ParentView
  private var collapsedHeight: CGFloat = 120
  @State var offset: CGFloat = 0
  @State var lastOffset: CGFloat = 0
  @GestureState var gestureOffset: CGFloat = 0
  
  init(parentView: ParentView) {
    self.parentView = parentView
  }

  var body: some View {
    @Bindable var viewModel = viewModel
    
    ZStack {
      parentView
        .padding(.bottom, viewModel.isPresented ? 80 : 0)
      
      if let workout = viewModel.workout {
        
        GeometryReader { geometry in
          
          let height = geometry.frame(in: .global).height
          
          Color(UIColor.secondarySystemBackground)
            .cornerRadius(30, corners: [.topLeft, .topRight])
            .offset(y: height - collapsedHeight)
            .offset(y: -offset > 0 ? -offset <= (height - collapsedHeight) ? offset : -(height - collapsedHeight) : 0)
          
          VStack {
            HStack {
              Capsule()
                .frame(width: 40, height: 5)
                .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, viewModel.isExpanded ? 50 : 8)
            .onTapGesture {
              withAnimation(.snappy(duration: 0.3)) {
                if viewModel.isExpanded {
                  offset = 0
                  lastOffset = offset
                  viewModel.isExpanded = false
                } else {
                  offset = -height + collapsedHeight
                  lastOffset = offset
                  viewModel.isExpanded = true
                }
              }
            }
            
            if viewModel.isExpanded {
              StartedWorkoutView(workout: workout)
                .padding(.bottom, 30)
            } else {
              HStack {
                Text("This is the collapsed content")
                  .font(.title)
              }
              .onTapGesture {
                withAnimation(.snappy(duration: 0.3)) {
                  if viewModel.isExpanded {
                    offset = 0
                    lastOffset = offset
                    viewModel.isExpanded = false
                  } else {
                    offset = -height + collapsedHeight
                    lastOffset = offset
                    viewModel.isExpanded = true
                  }
                }
              }
            }
            
          }
          .frame(maxHeight: .infinity, alignment: .top)
          .frame(maxWidth: .infinity)
          .background(userAccentColor.opacity(0.2))
          .cornerRadius(30, corners: [.topLeft, .topRight])
          .offset(y: height - collapsedHeight)
          .offset(y: -offset > 0 ? -offset <= (height - collapsedHeight) ? offset : -(height - collapsedHeight) : 0)
          .gesture(
            DragGesture()
              .updating($gestureOffset) { value, gestureOffset, _ in
                gestureOffset = value.translation.height
              }
              .onChanged { value in
                print("onChanged value: \(value.translation.height)")
                offset = lastOffset + value.translation.height
                print("onChanged offset: \(offset)")
              }
              .onEnded { value in
                print("onEnded value: \(value.translation.height)")
                print("onEnded offset: \(offset)")
                withAnimation(.snappy) {
                  
                  let threshold: CGFloat = 2 / 3 * collapsedHeight
                  if value.translation.height > 0 {  // moving from top to bottom
                    if value.translation.height > threshold {
                      offset = 0
                    } else {
                      offset = lastOffset
                    }
                  } else {  // moving from bottom to top
                    if -value.translation.height > threshold {
                      offset = -height + collapsedHeight
                    } else {
                      offset = lastOffset
                    }
                  }
                  
                  lastOffset = offset
                  if lastOffset == 0 {
                    viewModel.isExpanded = false
                  } else {
                    viewModel.isExpanded = true
                  }
                  
                }
                
                print("after onEnded offset: \(offset)")
                print("IsExpended after onEnded: \(viewModel.isExpanded)")
              }
          )
          .onAppear {
            withAnimation(.snappy) {
              offset = -height + collapsedHeight
              lastOffset = offset
            }
          }
        }
        .ignoresSafeArea(edges: .all)
        
      }
    }
  }

}

#Preview {
  @Previewable @State var startedWorkoutViewModel = StartedWorkoutViewModel()

  VStack {
    WorkoutListView()
      .startedWorkoutBottomSheet()
  }
  .environment(\.startedWorkoutViewModel, startedWorkoutViewModel)
  .modelContainer(AppContainer.preview.modelContainer)
}
