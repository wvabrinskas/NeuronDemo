//
//  NetworkViewModel.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import Foundation
import SwiftUI

public struct Prediction {
  var confidence: Float
  var result: String
}

@Observable
public final class NetworkStatus: Equatable, @unchecked Sendable {
  public static func == (lhs: NetworkStatus, rhs: NetworkStatus) -> Bool {
    lhs.ready == rhs.ready &&
    lhs.training == rhs.training
  }
  
  var training: Bool
  var ready: Bool
  
  public init(training: Bool = false,
              ready: Bool = false) {
    self.training = training
    self.ready = ready
  }
}

@Observable
public final class NetworkViewModel: @unchecked Sendable {
  public var status: NetworkStatus
  public var text: String
  public var subtext: String
  public var prediction: Prediction?
  public var drawnImage: [Float]
  public var drawViewModel: DrawViewModel
  
  public init(status: NetworkStatus = .init(),
              text: String = "",
              subtext: String = "",
              prediction: Prediction? = nil,
              drawnImage: [Float] = [],
              drawViewModel: DrawViewModel = .init()) {
    self.status = status
    self.text = text
    self.prediction = prediction
    self.drawnImage = drawnImage
    self.subtext = subtext
    self.drawViewModel = drawViewModel
  }
}
