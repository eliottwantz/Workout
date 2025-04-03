//
//  ContentView.swift
//  Workout
//
//  Created by Eliott on 2025-04-03.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  var body: some View {
    WorkoutListView()
  }
}

#Preview {
  ContentView()
    .modelContainer(AppContainer.preview.modelContainer)
}
