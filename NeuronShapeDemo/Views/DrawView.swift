//
//  DrawView.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import Foundation
import SwiftUI
import NumSwift

@Observable
public final class DrawViewModel: @unchecked Sendable {
  var clear: Bool
  let gridSize: CGSize
  let pixelSize: Int
  
  public init(clear: Bool = false,
              gridSize: CGSize = .init(width: 28, height: 28),
              pixelSize: Int = 8) {
    self.clear = clear
    self.gridSize = gridSize
    self.pixelSize = pixelSize
  }
}

public struct DrawView: View {
  var viewModel: DrawViewModel
  var onSubmit: ([Float]) -> ()
  
  @State private var drawingCanvasViewModel: DrawingCanvasViewModel = .init(gridSize: .zero)
  
  private var size: CGSize {
    .init(width: viewModel.gridSize.width,
          height: viewModel.gridSize.height)
  }
  
  public var body: some View {
    VStack {
      DrawingCanvas(viewModel: drawingCanvasViewModel, onSubmit: onSubmit)
      .frame(width: size.width,
             height: size.height)
      .onAppear {
        drawingCanvasViewModel.gridSize = viewModel.gridSize
      }
      .scaleEffect(10)
      
      Spacer()
      
      HStack(spacing: 20) {
        Button {
          drawingCanvasViewModel.state = .clear
        } label: {
          Image(systemName: "trash")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.red)
            .fontWeight(.bold)
            .frame(width: 21)
        }
        
        Button {
          drawingCanvasViewModel.state = .submit
        } label: {
          Image(systemName: "checkmark")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.green)
            .fontWeight(.bold)
            .frame(width: 21)
        }
      }

    }
    .frame(maxHeight: 200)

  }
  
}

enum DrawingCanvasState {
  case clear, ready, submit
}

@Observable
class DrawingCanvasViewModel {
  var state: DrawingCanvasState
  var gridSize: CGSize
  var paths: [Path]
  
  init(state: DrawingCanvasState = .ready,
       gridSize: CGSize,
       paths: [Path] = []) {
    self.state = state
    self.gridSize = gridSize
    self.paths = paths
  }
}

struct DrawingCanvas: View {
  @State private var currentPath = Path()
  
  @State var viewModel: DrawingCanvasViewModel
  var onSubmit: ([Float]) -> ()
  private let lineWidth: CGFloat = 1.0
  
  var canvasPallete: some View {
    Canvas { context, size in
      for path in viewModel.paths {
        context.stroke(path, with: .color(.white), lineWidth: lineWidth)
      }
      context.stroke(currentPath, with: .color(.white), lineWidth: lineWidth)
    }
    .frame(width: viewModel.gridSize.width,
           height: viewModel.gridSize.width)
    .gesture(DragGesture()
      .onChanged { value in
        currentPath.addLine(to: value.location)
      }
      .onEnded { value in
        viewModel.paths.append(currentPath)
        currentPath = Path()
      }
    )
  }

  var body: some View {
    canvasPallete
    .background(Color.black)
    .onChange(of: viewModel.state) { new, old in
      switch new {
      case .clear:
        viewModel.paths = []
      case .submit:
        let renderer = ImageRenderer(content: canvasPallete)
        if let image = renderer.uiImage?.asGrayScaleTensor() {
          let array: [Float] = Array(image.storage)
          onSubmit(array)
        }
        viewModel.paths = []
      default:
        break
      }
      
      viewModel.state = .ready
    }
    .border(Color.gray, width: 1)
  }
}


#Preview {
    DrawView(viewModel: .init(gridSize: .init(width: 28, height: 28),
                              pixelSize: 6)) { _ in
      
    }
}
