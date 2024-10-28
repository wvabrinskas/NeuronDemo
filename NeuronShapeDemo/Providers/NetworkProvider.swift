//
//  NetworkProvider.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import Foundation
@preconcurrency import Neuron
import NeuronDatasets
import NumSwift
import Logger

@MainActor
public protocol NetworkProviding {
  var viewModel: NetworkViewModel { get }
  func perform(action: NetworkAction) async
}

public enum NetworkAction: Equatable {
  case predict
  case train
  case importModel
}

@MainActor
public final class NetworkProvider: NetworkProviding, @preconcurrency Logger, @unchecked Sendable {
  public var logLevel: LogLevel = .high
  
  private var classifier: Classifier?
  private var dataset: (training: [DatasetModel], validation: [DatasetModel])?
  
  private enum DatasetType {
    case generatedShapes, quickDraw, mnist
    
    var outputCount: Int {
      switch self {
      case .generatedShapes:
        return ShapeType.allCases.count
      case .quickDraw:
        return QuickDrawObject.allCases.count
      case .mnist:
        return 10
      }
    }
    
    var importModel: ImportModel {
      switch self {
      case .generatedShapes:
        return .demoShapeClassifier
      case .quickDraw:
        return .demoQuickDrawClassifier
      default:
        return .unknown
      }
    }
  }
  
  public let viewModel: NetworkViewModel = .init(status: .init(ready: true),
                                                 drawViewModel: .init(gridSize: .init(width: 28,
                                                                                      height: 28)))
  
  private var inputSize: TensorSize {
    .init(rows: Int(viewModel.drawViewModel.gridSize.height),
          columns: Int(viewModel.drawViewModel.gridSize.width),
          depth: 1)
  }
  
  private let datasetType: DatasetType = .quickDraw
  
  private enum ImportModel: String {
    case unknown
    case demoShapeClassifier = "demo-shape-classifier"
    case demoQuickDrawClassifier = "demo-quickdraw-classifier"
    
    var url: URL? {
      Bundle.main.url(forResource: rawValue, withExtension: "smodel")
    }
  }
  
  public nonisolated init() {}
  
  public func perform(action: NetworkAction) async {
    switch action {
    case .predict:
      await predict()
    case .train:
      await train()
    case .importModel:
      await importModel()
    }
    
    viewModel.networkRunState = .idle
  }
  
  func predict() async {
    guard viewModel.status.ready else {
      log(type: .error, message: "Model is not ready yet")
      return
    }
    
    guard viewModel.drawnImage.isEmpty == false else { return }
    
    let grayScaleImage = Tensor(viewModel.drawnImage.reshape(columns: inputSize.columns))
    
    let task = Task.detached {
      guard let classifier = await self.classifier,
            let prediction = classifier.optimizer.predict([grayScaleImage]).first else { return }
      
      let max = prediction.value.flatten().indexOfMax
      let index = max.0
      let confidence = max.1
      
      await self.getPrediction(indexOfMax: index, confidence: confidence)
    }
    
    await withTaskCancellationHandler {} onCancel: {
      task.cancel()
    }
  }
  
  func getPrediction(indexOfMax index: UInt, confidence: Float) {
    switch datasetType {
    case .generatedShapes:
      guard let shape = ShapeType(rawValue: Int(index)) else { return }
      
      viewModel.text = shape.string()
      viewModel.subtext = String(format: "%.1f%", confidence * 100)
      viewModel.prediction = .init(confidence: confidence, result: shape.string())
    case .quickDraw:
      let allCases = QuickDrawObject.allCases
      guard let object = allCases[safe: Int(index)] else { return }
      
      viewModel.text = object.rawValue
      viewModel.subtext = String(format: "%.1f%", confidence * 100)
      viewModel.prediction = .init(confidence: confidence, result: object.rawValue)
    case .mnist:
      break
    }
    
    viewModel.networkRunState = .idle
  }
  
  func train() async {
    if classifier == nil || dataset == nil {
      await buildNetwork()
    }
    
    guard let classifier,
          let dataset else {
      self.log(type: .error, message: "Classifier or dataset is not set")
      return
    }
    
    self.viewModel.status.loading = true
    // we cannot run fit using `Task.detatched` because it throws a runtime exec error with Swift 6 Concurrency when calling the metric reporting blocks.
    classifier.fit(dataset.training, dataset.validation)
  }
  
  func importModel() async {
    viewModel.status.ready = false
    
    guard datasetType.importModel != .unknown,
          let url = datasetType.importModel.url else {
      log(type: .error, message: "Could not find model to import")
      viewModel.status.ready = true
      return
    }
    
    let sequential = Sequential.import(url)
    await buildNetwork(importing: sequential)
  }
  
  // MARK: Private
  private func buildMNIST() async {
    let data = MNIST()
    let result = await data.build()
    dataset = (result.training, result.val)
  }
  
  private func buildQuickDrawData() async {
    let dataset = QuickDrawDataset(objectsToGet: .square, .circle, .triangle,
                                   trainingCount: 10000,
                                   validationCount: 500)
    
    let result = await dataset.build()
    
    self.dataset = (result.training, result.val)
    
    self.viewModel.status.ready = true
    log(type: .success, message: "Dataset ready!")
  }
  
  private func buildData() {
    let numberOfTraining = 200
    let numberOfValidation = 10
    
    var training: [DatasetModel] = []
    var validation: [DatasetModel] = []
    
    let size = CGSize(width: inputSize.columns, height: inputSize.rows)
    
    ShapeType.allCases.forEach { type in
      
      for _ in 0..<numberOfTraining {
        if let shape = type.shape(size)?.resizeImage(targetSize: size)?.asGrayScaleTensor() {
          training.append(.init(data: shape, label: type.label()))
        }
      }
      
      for _ in 0..<numberOfValidation {
        if let shape = type.shape(size)?.resizeImage(targetSize: size)?.asGrayScaleTensor() {
          validation.append(.init(data: shape, label: type.label()))
        }
      }
    }
    
    dataset = (training, validation)
    
    viewModel.status.ready = true
    log(type: .success, message: "Dataset Ready!")
    
  }
  
  private func buildNetwork(importing: Sequential? = nil) async {
    log(type: .message, message: "Building network...")
    viewModel.status.loading = true

    let initializer: InitializerType = .xavierUniform
    
    defer {
      self.viewModel.status.ready = true
      self.viewModel.status.loading = false
      self.log(type: .success, message: "Network Ready!")
    }
    
    let network = Sequential {
      [
        Conv2d(filterCount: 16,
               inputSize: self.inputSize,
               padding: .same,
               initializer: initializer),
        ReLu(),
        MaxPool(),
        Conv2d(filterCount: 32,
               padding: .same,
               initializer: initializer),
        ReLu(),
        MaxPool(),
        Flatten(),
        Dense(64, initializer: initializer),
        ReLu(),
        Dense(self.datasetType.outputCount, initializer: initializer),
        Softmax()
      ]
    }
    
    let optimizer = Adam(importing ?? network, learningRate: 0.001)
    
    let reporter = MetricsReporter(frequency: 30,
                                   metricsToGather: [.loss,
                                                     .accuracy,
                                                     .valAccuracy,
                                                     .valLoss,
                                                     .batchTime])
    
    optimizer.metricsReporter = reporter
    
    optimizer.metricsReporter?.receive = { @MainActor [weak self] metrics in
      guard let self else { return }
      
      let accuracy = metrics[.accuracy] ?? 0
      let loss = metrics[.loss] ?? 0
      self.viewModel.text = String(format: "Loss: %.3f", loss)
      self.viewModel.subtext = String(format: "Acc.: %.1f %", accuracy)
  
    }
    
    let classifier = Classifier(optimizer: optimizer,
                                epochs: 40,
                                batchSize: 64,
                                accuracyThreshold: .init(value: 0.97, averageCount: 3),
                                killOnAccuracy: true,
                                threadWorkers: 8,
                                log: false)
    
    classifier.onEpochCompleted = {  [weak self] in
      guard let self else { return }
      
      let accuracy = optimizer.metricsReporter?.valAccuracy ?? 0
      let loss = optimizer.metricsReporter?.valLoss ?? 0
      
      Task { @MainActor in
        self.viewModel.text = String(format: "Loss: %.3f", loss)
        self.viewModel.subtext = String(format: "Acc.: %.1f %", accuracy)
      }
    }
    
    classifier.onAccuracyReached = { [weak self] in
      self?.viewModel.status.loading = false
      self?.log(type: .success, message: "Training complete!")
      self?.log(type: .message, message: "\(classifier.export(compress: true)?.absoluteString)")
    }
    
    self.classifier = classifier
    
    guard importing == nil else {
      return
    }
    
    if self.dataset == nil {
      switch self.datasetType {
      case .generatedShapes:
        self.buildData()
      case .quickDraw:
        await self.buildQuickDrawData()
      case .mnist:
        await self.buildMNIST()
      }
    }
  }
}
