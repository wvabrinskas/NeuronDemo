//
//  ContentView.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import SwiftUI

struct ContentView: View {
  @Environment(\.network) var network
  
  var body: some View {
    VStack {
      NetworkView(viewModel: network.viewModel)
    }
    .fullscreen()
  }
}

#Preview {
  ContentView()
}
