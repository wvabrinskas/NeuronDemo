//
//  UIImage+Extensions.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 10/25/24.
//

import UIKit
import Neuron
import NumSwift


extension UIImage {
  
  func asRGBTensor(zeroCenter: Bool = false) -> Tensor {
    guard let pixelData = self.cgImage?.dataProvider?.data else { return Tensor() }
    
    let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
    
    var rArray: [Float] = []
    var gArray: [Float] = []
    var bArray: [Float] = []
    
    for y in 0..<Int(self.size.height) {
      for x in 0..<Int(self.size.width) {
        let pos = CGPoint(x: x, y: y)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y) * 4) + Int(pos.x) * 4)
        
        var r = Float(data[pixelInfo])
        var g = Float(data[pixelInfo + 1])
        var b = Float(data[pixelInfo + 2])
        
        if zeroCenter {
          r = (r - 127.5) / 127.5
          g = (g - 127.5) / 127.5
          b = (b - 127.5) / 127.5
        } else {
          r = r / 255.0
          g = g / 255.0
          b = b / 255.0
        }
        
        rArray.append(r)
        gArray.append(g)
        bArray.append(b)
      }
    }
    
    return Tensor([rArray.reshape(columns: Int(self.size.width)),
                   gArray.reshape(columns: Int(self.size.width)),
                   bArray.reshape(columns: Int(self.size.width))])
  }

}
