//
//  NetworkView.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import SwiftUI

public enum NetworkRunState: Int {
  case predict, train, importModel, idle
}

struct NetworkView: View {
  @Environment(\.network) var network
  @Environment(\.displayScale) var displayScale

  @State var viewModel: NetworkViewModel
  
  var body: some View {
    VStack {
      Text(viewModel.status.ready && viewModel.status.loading == false ? "👍" : "🛑")
        .font(.largeTitle)
      
      if viewModel.status.loading {
        ProgressView()
          .controlSize(.large)
          .foregroundColor(Color.white)
      } else {
        DrawView(viewModel: viewModel.drawViewModel) { result in
          viewModel.drawnImage = result
          viewModel.networkRunState = .predict
        }
      }
      
      Button(action: {
        viewModel.networkRunState = .train
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
      .disabled(viewModel.status.ready == false || viewModel.status.loading)
      .frame(width: 80, height: 40)
      .padding(.top, 16)
      
      Button(action: {
        viewModel.networkRunState = .importModel
      }, label: {
        ZStack {
          RoundedRectangle(cornerRadius: 25.0, style: .continuous)
            .foregroundStyle(viewModel.status.ready == false || viewModel.status.loading ? Color.gray : Color.purple)
          Image(systemName: "square.and.arrow.down.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 25)
            .foregroundColor(Color.white)
        }
      })
      .disabled(viewModel.status.ready == false || viewModel.status.loading)
      .frame(width: 80, height: 40)
      .padding(.top, 16)

      Text(viewModel.text)
        .font(.title)
        .fontDesign(.rounded)
        .padding(.top, 28)
      
      Text(viewModel.subtext)
        .font(.subheadline)
        .fontDesign(.rounded)
    }
    .task(id: viewModel.networkRunState) {
      switch viewModel.networkRunState {
      case .predict:
        await network.perform(action: .predict)
      case .train:
        await network.perform(action: .train)
      case .importModel:
        await network.perform(action: .importModel)
      case .idle:
        break
      }
    }
  }
}

#Preview {
  NetworkView(viewModel: .init(status: .init(loading: false, ready: true),
                               text: "Loss: 0.2222",
                               subtext: "Acc. 20.0 %",
                               drawViewModel: .init(pixelSize: 12)))
    .preferredColorScheme(.dark)
}
