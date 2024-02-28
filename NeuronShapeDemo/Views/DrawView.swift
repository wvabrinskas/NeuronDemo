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
public final class DrawViewModel {
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
  @Binding var result: [Float]
  var viewModel: DrawViewModel
  
  @State private var points: [CGPoint] = []
  @State private var values: [Float] = []
  @State private var debounce: Int = 1
  
  private let debounceAmount = 20
  
  private var size: CGSize {
    .init(width: viewModel.gridSize.width * CGFloat(viewModel.pixelSize),
          height: viewModel.gridSize.height * CGFloat(viewModel.pixelSize))
  }
  
  public var body: some View {
    
    ZStack {
      Rectangle()
        .foregroundColor(.black)
        .frame(width: size.width, height: size.height)
        .gesture(DragGesture()
          .onChanged( { value in
            addNewPoint(value)
          })
            .onEnded( { value in
              viewModel.clear = true
            }))
      
      ForEach(0..<Int(viewModel.gridSize.width + 1), id: \.self) { x in
        Color.white
          .opacity(0.5)
          .frame(width: 1)
          .offset(x: CGFloat(viewModel.pixelSize) * CGFloat(x) - (size.width / 2), y: 0)
      }
      
      ForEach(0..<Int(viewModel.gridSize.height + 1), id: \.self) { x in
        Color.white
          .opacity(0.5)
          .frame(width: 1)
          .offset(x: CGFloat(viewModel.pixelSize) * CGFloat(x) - (size.height / 2), y: 0)
          .rotationEffect(.degrees(90))
      }
      
      ForEach(0..<values.count, id: \.self) { v in
        Color.white
          .opacity(CGFloat(values[v]))
          .frame(width: CGFloat(viewModel.pixelSize), height: CGFloat(viewModel.pixelSize))
          .position(.init(x: CGFloat(v).truncatingRemainder(dividingBy: viewModel.gridSize.height) * CGFloat(viewModel.pixelSize),
                          y: (CGFloat(v) / viewModel.gridSize.width) * CGFloat(viewModel.pixelSize)))
      }

    }
    .onAppear {
      values = [Float](repeating: 0, count: Int(viewModel.gridSize.width * viewModel.gridSize.height))
    }
    .frame(width: size.width,
           height: size.height)
    
    .onChange(of: values) { oldValue, newValue in
      if debounce % debounceAmount == 0 {
        result = newValue
        debounce = 1
      } else {
        debounce += 1
      }
      
      if values.indexOfMax.1 == 0 {
        viewModel.clear = false
      }
    }
    .onChange(of: viewModel.clear) { oldValue, newValue in
      if newValue {
        values = [Float](repeating: 0, count: Int(viewModel.gridSize.width * viewModel.gridSize.height))
      }
    }
  }
  
  private func addNewPoint(_ value: DragGesture.Value) {
    
    let x = Int(floor(round(value.location.x))) / viewModel.pixelSize
    let y = Int(floor(round(value.location.y))) / viewModel.pixelSize
    
    guard x >= 0, y >= 0, x < Int(viewModel.gridSize.width), y < Int(viewModel.gridSize.height) else { return }
    
    let totalRows = Int(viewModel.gridSize.height)
    let index = (y * totalRows) + x
    
    values[index] = 1.0
  }
  
}

#Preview {
  DrawView(result: .constant([]), viewModel: .init())
}
