//
//  Path+Extensions.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 10/25/24.
//

import UIKit
import SwiftUI
import Neuron
import NumSwift

extension View {
  func snapshot(when: Bool, result: ([Float]) -> ()) -> Self {
    guard when else { return self }
    
    let controller = UIHostingController(rootView: self)
    let view = controller.view
    
    let targetSize = controller.view.intrinsicContentSize
    view?.bounds = CGRect(origin: .zero, size: targetSize)
    view?.backgroundColor = .black
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    
    let image = renderer.image { _ in
      view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
    
    result(Array(image.asRGBTensor().storage))
    
    return self
  }
}
