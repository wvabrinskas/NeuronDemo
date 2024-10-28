//
//  Environment+Extensions.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import Foundation
import SwiftUI

struct NetworkKey: EnvironmentKey {
  static let defaultValue = NetworkProvider()
}

extension EnvironmentValues {
  var network: NetworkProvider {
    get { self[NetworkKey.self] }
    set { self[NetworkKey.self] = newValue }
  }
}
