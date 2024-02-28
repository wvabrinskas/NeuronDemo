//
//  ShapeModel.swift
//  NeuroCam
//
//  Created by William Vabrinskas on 1/13/21.
//

import Foundation
import UIKit
import SwiftUI
import Neuron

public enum ShapeType: Int, CaseIterable {
  case circle, rectangle, triangle, trapezoid
  
  public func string() -> String {
    switch self {
    case .circle:
      return "Circle"
    case .rectangle:
      return "Rectangle"
    case .triangle:
      return "Triangle"
    case .trapezoid:
      return "Trapezoid"
    }
  }
  
  public func label() -> Tensor {
    var returnArray = [Float](repeating: 0.0, count: ShapeType.allCases.count)
    
    if let index = ShapeType.allCases.firstIndex(of: self) {
      returnArray[index] = 1.0
    }
        
    return Tensor(returnArray)
  }
  
  public func shape(_ size: CGSize,
                    color: UIColor = .white,
                    scale: CGFloat? = nil,
                    radius: Float? = nil) -> UIImage? {
    switch self {
    case .circle:
      return UIView.circle(size: size,
                           color: color,
                           scale: CGFloat.random(in: 0.2...0.9)).asImage()
    case .triangle:
      return UIView.triangle(size: size,
                             color: color,
                             scale: CGFloat.random(in: 0.2...0.9)).asImage()
    case .rectangle:
      return  UIView.rectangle(size: size,
                               color: color,
                               scale: CGFloat.random(in: 0.2...0.9)).asImage()
      
    case .trapezoid:
      return UIView.trapezoid(size: size,
                              color: color,
                              scale: CGFloat.random(in: 0.2...0.9)).asImage()
    }
  }
}

public struct ShapeTrainingModel: Equatable {
  var data: Tensor
  var label: Tensor
}
