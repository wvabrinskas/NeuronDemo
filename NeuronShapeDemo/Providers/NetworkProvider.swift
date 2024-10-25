//
//  NetworkProvider.swift
//  NeuronShapeDemo
//
//  Created by William Vabrinskas on 2/26/24.
//

import Foundation
import Neuron
import NeuronDatasets
import NumSwift
import Logger

public protocol NetworkProviding {
    var viewModel: NetworkViewModel { get }
    func predict()
    func train()
    func importModel()
}

public final class NetworkProvider: NetworkProviding, Logger {
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
    }
    
    public lazy var viewModel: NetworkViewModel = .init(drawViewModel: .init(gridSize: CGSize(width: inputSize.columns,
                                                                                              height: inputSize.rows),
                                                                             pixelSize: 12))
    
    private let inputSize: TensorSize =  .init(rows: 28, columns: 28, depth: 1)
    
    private let datasetType: DatasetType = .quickDraw
    
    private enum ImportModel: String {
        case demoShapeClassifier = "demo-shape-classifier"
    }
    
    public init() {
        buildNetwork()
    }
    
    public func predict() {
        guard viewModel.status.ready else {
            log(type: .error, message: "Model is not ready yet")
            return
        }
        
        Task.detached { [self] in
            guard viewModel.drawnImage.isEmpty == false,
                  let classifier else { return }
            let grayScaleImage = Tensor(viewModel.drawnImage.reshape(columns: inputSize.columns))
            
            guard let prediction = classifier.optimizer.predict([grayScaleImage]).first else { return }
            
            let max = prediction.value.flatten().indexOfMax
            let index = max.0
            let confidence = max.1
            
            await getPrediction(indexOfMax: index, confidence: confidence)
        }
    }
    
    @MainActor
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
    }
    
    public func train() {
        guard let classifier, let dataset else {
            log(type: .error, message: "Classifier or dataset is not set")
            return
        }
        
        Task.detached {
            self.viewModel.status.training = true
            classifier.fit(dataset.training, dataset.validation)
        }
    }
    
    public func importModel() {
        viewModel.status.ready = false
        
        guard let url = Bundle.main.url(forResource: ImportModel.demoShapeClassifier.rawValue,
                                        withExtension: "smodel") else {
            log(type: .error, message: "Could not find model to import")
            viewModel.status.ready = true
            return
        }
        
        let sequential = Sequential.import(url)
        buildNetwork(importing: sequential)
    }
    
    // MARK: Private
    private func buildMNIST() async {
        let data = MNIST()
        let result = await data.build()
        dataset = (result.training, result.val)
    }
    
    private func buildQuickDrawData() async {
        /*
         1. The current dataset isn't particularly great because it expects perfect shapes each time.
         We could expand this to use the QuickDrawDataset from Google in the NeuronDatasets library.
         
         2. Use the QuickDrawDataset to pull in multiple different hand drawn shapes
         This might mean creating multiple copies of the QuickDrawDataset to pull in the different drawings.
         You will also have to change the number of output nodes
         
         3. Update the network to use convolutional layers for image recognition
         */
        
      let dataset = QuickDrawDataset(objectsToGet: .square, .circle, .triangle,
                                       trainingCount: 5000,
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
        
        Task { @MainActor in
            self.viewModel.status.ready = true
            log(type: .success, message: "Ready!")
        }
        
    }
    
    private func buildNetwork(importing: Sequential? = nil) {
        log(type: .message, message: "Building network...")
        Task.detached {
            let initializer: InitializerType = .xavierUniform
            
            let network = Sequential {
                [
                    //          Flatten(inputSize: self.inputSize),
                    //          Dense(512, initializer: initializer),
                    //          ReLu(),
                    //          Dense(64, initializer: initializer),
                    //          ReLu(),
                    //          Dense(ShapeType.allCases.count, initializer: initializer),
                    //          Softmax()
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
            
            let reporter = MetricsReporter(frequency: 1,
                                           metricsToGather: [.loss,
                                                             .accuracy,
                                                             .valAccuracy,
                                                             .valLoss,
                                                             .batchTime])
            
            optimizer.metricsReporter = reporter
            
            optimizer.metricsReporter?.receive = { metrics in
                //        let accuracy = metrics[.accuracy] ?? 0
                //        let loss = metrics[.loss] ?? 0
                //        print("batchTime: ", metrics[.batchTime] ?? 0)
                //        print("training -> ", "loss: ", loss, "accuracy: ", accuracy)
                //        Task { @MainActor in
                //          self.viewModel.text = String(format: "Loss: %.3f", loss)
                //          self.viewModel.subtext = String(format: "Acc.: %.1f %", accuracy)
                //        }
            }
            
            let classifier = Classifier(optimizer: optimizer,
                                        epochs: 40,
                                        batchSize: 64,
                                        accuracyThreshold: .init(value: 0.95, averageCount: 5),
                                        killOnAccuracy: true,
                                        threadWorkers: 8,
                                        log: false)
            
            classifier.onEpochCompleted = {
                let accuracy = optimizer.metricsReporter?.valAccuracy ?? 0
                let loss = optimizer.metricsReporter?.valLoss ?? 0
                
                Task { @MainActor in
                    self.viewModel.text = String(format: "Loss: %.3f", loss)
                    self.viewModel.subtext = String(format: "Acc.: %.1f %", accuracy)
                }
            }
            
            classifier.onAccuracyReached = {
                self.viewModel.status.training = false
            }
            
            self.classifier = classifier
            
            Task { @MainActor in
                if self.dataset == nil {
                    switch self.datasetType {
                    case .generatedShapes:
                        self.buildData()
                    case .quickDraw:
                        await self.buildQuickDrawData()
                    case .mnist:
                        await self.buildMNIST()
                    }
                    
                    self.viewModel.status.ready = true
                    self.log(type: .success, message: "Ready!")
                }
                
            }
            
        }
    }
}
