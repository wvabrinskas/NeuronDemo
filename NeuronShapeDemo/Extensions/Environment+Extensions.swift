//
//  Environment+Extensions.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import Foundation
import SwiftUI

struct NetworkKey: EnvironmentKey {
  static let defaultValue: NetworkProviding = NetworkProvider()
}

extension EnvironmentValues {
  var network: NetworkProviding {
    get { self[NetworkKey.self] }
    set { self[NetworkKey.self] = newValue }
  }
}

