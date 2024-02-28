//
//  View+Extensinos.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import Foundation
import SwiftUI

public extension View {
  func fullscreen() -> some View {
    self.frame(maxWidth: .infinity, maxHeight: .infinity)
      .preferredColorScheme(.dark)
  }
}
