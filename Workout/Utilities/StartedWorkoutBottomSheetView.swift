//
//  StartedWorkoutBottomSheetView.swift
//  Workout
//
//  Created by Copilot on 2025-04-10.
//

import SwiftUI
import SwiftData


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
  private var bottomPadding: CGFloat
  @State var offset: CGFloat = 0
  @State var lastOffset: CGFloat = 0
  @GestureState var gestureOffset: CGFloat = 0
  @State private var isExpanded: Bool = true
  
  var isPresented: Bool {
    viewModel.workout != nil
  }
  
  init(parentView: ParentView) {
    self.parentView = parentView
    self.bottomPadding = collapsedHeight - 47
  }

  var body: some View {
    @Bindable var viewModel = viewModel
    
    ZStack {
      parentView
        .padding(.bottom, isPresented ? 80 : 0)
      
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
            .padding(.top, isExpanded ? 50 : 8)
            .onTapGesture {
              withAnimation(.snappy(duration: 0.3)) {
                if isExpanded {
                  offset = 0
                  lastOffset = offset
                  isExpanded = false
                } else {
                  offset = -height + collapsedHeight
                  lastOffset = offset
                  isExpanded = true
                }
              }
            }
            
            if isExpanded {
              StartedWorkoutView(workout: workout)
                .padding(.bottom, 30)
            } else {
              HStack {
                Text("This is the collapsed content")
                  .font(.title)
              }
              .onTapGesture {
                withAnimation(.snappy(duration: 0.3)) {
                  if isExpanded {
                    offset = 0
                    lastOffset = offset
                    isExpanded = false
                  } else {
                    offset = -height + collapsedHeight
                    lastOffset = offset
                    isExpanded = true
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
                    isExpanded = false
                  } else {
                    isExpanded = true
                  }
                  
                }
                
                print("after onEnded offset: \(offset)")
                print("IsExpended after onEnded: \(isExpanded)")
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
