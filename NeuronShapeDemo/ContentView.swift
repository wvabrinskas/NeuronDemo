//
//  ContentView.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import SwiftUI

struct ContentView: View {
  @Environment(\.network) var nework
  
  var body: some View {
    VStack {
      NetworkView(viewModel: nework.viewModel)
    }
    .fullscreen()
  }
}

#Preview {
  ContentView()
}
