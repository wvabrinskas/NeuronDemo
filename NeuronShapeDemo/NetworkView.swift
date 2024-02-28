//
//  NetworkView.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import SwiftUI

struct NetworkView: View {
  @Environment(\.network) var network
  @Environment(\.displayScale) var displayScale

  @State var viewModel: NetworkViewModel
  
  var body: some View {
    VStack {
      if viewModel.status.training {
        ProgressView()
          .controlSize(.large)
          .foregroundColor(Color.white)
      } else {
        DrawView(result: $viewModel.drawnImage,
                 viewModel: viewModel.drawViewModel)
        .border(.white, width: 1)
      }
      
      Button(action: {
        network.train()
      }, label: {
        ZStack {
          RoundedRectangle(cornerRadius: 25.0, style: .continuous)
          Image(systemName: "hammer.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 25)
            .foregroundColor(Color.white)
        }
      })
      .disabled(viewModel.status.ready == false || viewModel.status.training)
      .frame(width: 80, height: 40)
      .padding(.top, 16)
      
      Button(action: {
        network.importModel()
      }, label: {
        ZStack {
          RoundedRectangle(cornerRadius: 25.0, style: .continuous)
            .foregroundStyle(Color.purple)
          Image(systemName: "square.and.arrow.down.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 25)
            .foregroundColor(Color.white)
        }
      })
      .disabled(viewModel.status.ready == false || viewModel.status.training)
      .frame(width: 80, height: 40)
      .padding(.top, 16)

      Text(viewModel.text)
        .font(.title)
        .padding(.top, 28)
      
      Text(viewModel.subtext)
        .font(.subheadline)
    }
    .onChange(of: viewModel.drawnImage) { oldValue, newValue in
      network.predict()
    }
    .onChange(of: viewModel.status) { oldValue, newValue in
      print(newValue)
    }
  }
}

#Preview {
  NetworkView(viewModel: .init(status: .init(training: false, ready: true),
                               text: "Loss: 0.2222",
                               subtext: "Acc. 20.0 %"))
    .preferredColorScheme(.dark)
}
