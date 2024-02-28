import UIKit
import Foundation

extension UIImage {
  func resizeImage(targetSize: CGSize) -> UIImage? {
    let size = self.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
      newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
      newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    self.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
  }
}

extension UIView {
  public func asImage() -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
    
    defer { UIGraphicsEndImageContext() }
    
    if let context = UIGraphicsGetCurrentContext() {
      layer.render(in: context)
      let image = UIGraphicsGetImageFromCurrentImageContext()
      return image
    }
    return nil
  }
  
  public static func circle(size: CGSize,
                            color: UIColor = .white,
                            scale: CGFloat = 1.0) -> UIView {
    let backgroundColor = UIColor.black
    let strokeColor = color
    
    let circlePath = UIBezierPath(arcCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                                  radius: CGFloat(size.width / 2),
                                  startAngle: CGFloat(0),
                                  endAngle: CGFloat(Double.pi * 2),
                                  clockwise: true)
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = circlePath.cgPath
    shapeLayer.fillColor = backgroundColor.cgColor
    shapeLayer.strokeColor = strokeColor.cgColor
    shapeLayer.lineWidth = 2 / scale
    
    let scaleTrans = CATransform3DMakeScale(scale, scale, 1.0)
    shapeLayer.anchorPoint = CGPointMake(0, 0)
    shapeLayer.transform = scaleTrans
    
    let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    backgroundView.backgroundColor = backgroundColor
    
    shapeLayer.position = CGPoint(x: backgroundView.frame.midX - (circlePath.bounds.width / 2) * scale,
                                  y: backgroundView.frame.midY - (circlePath.bounds.height / 2) * scale)
    backgroundView.layer.addSublayer(shapeLayer)
        
    return backgroundView
  }
  
  public static func triangle(size: CGSize,
                              color: UIColor = .white,
                              scale: CGFloat = 1.0) -> UIView {
    let backgroundColor = UIColor.black
    let strokeColor = color
    
    let path = CGMutablePath()
    
    path.move(to: CGPoint(x: 0, y: size.height))
    path.addLine(to: CGPoint(x: (size.width / 2), y: size.height / 2 * 0.5))
    path.addLine(to: CGPoint(x: size.width, y: size.height))
    path.addLine(to: CGPoint(x: 0, y: size.height))
    
    let shape = CAShapeLayer()
    shape.path = path
    shape.fillColor = backgroundColor.cgColor
    shape.strokeColor = strokeColor.cgColor
    shape.lineWidth = 2 / scale
    shape.lineJoin = .miter

    let scaleTrans = CATransform3DMakeScale(scale, scale, 1.0)
    shape.transform = scaleTrans
    
    let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    backgroundView.backgroundColor = backgroundColor
    
    shape.anchorPoint = CGPointMake(0.5, 0.5)
    shape.position = CGPoint(x: backgroundView.frame.midX - (path.boundingBox.width / 2) * scale,
                             y: backgroundView.frame.midY - path.boundingBox.height * scale)
    
    backgroundView.layer.addSublayer(shape)

    return backgroundView
  }
  
  public static func rectangle(size: CGSize,
                               color: UIColor = .white,
                               scale: CGFloat = 1.0) -> UIView {
    let backgroundColor = UIColor.black
    let strokeColor = color
    
    let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    backgroundView.backgroundColor = backgroundColor
    
    let rectangle = UIView(frame: CGRect(x: 0, y: 0, width: size.height * scale, height: size.width * scale))
    
    rectangle.center = backgroundView.center
    rectangle.backgroundColor = backgroundColor
    rectangle.layer.borderWidth = 2
    rectangle.layer.borderColor = strokeColor.cgColor
    
    backgroundView.addSubview(rectangle)
    
    return backgroundView
  }
  
  public static func trapezoid(size: CGSize,
                               color: UIColor = .white,
                               scale: CGFloat = 1.0) -> UIView {
    let backgroundColor = UIColor.black
    let strokeColor = color
    
    let path = CGMutablePath()
    
    path.move(to: CGPoint(x: 0,
                          y: size.height - 10))
    
    path.addLine(to: CGPoint(x: size.width,
                             y: size.height - 10))
    
    path.addLine(to: CGPoint(x: size.width * 0.85,
                             y: (size.height - 10) - size.width * 0.5))
    
    path.move(to: CGPoint(x: 0,
                          y: size.height - 10))
    
    path.addLine(to: CGPoint(x: size.width * 0.15,
                             y: (size.height - 10) - size.width * 0.5))
    
    path.addLine(to: CGPoint(x: size.width * 0.85,
                             y: (size.height - 10) - size.width * 0.5))
    
    let shape = CAShapeLayer()
    shape.path = path
    shape.fillColor = backgroundColor.cgColor
    shape.strokeColor = strokeColor.cgColor
    shape.lineJoin = .miter
    shape.lineWidth = 2 / scale
    
    let scaleTrans = CATransform3DMakeScale(scale, scale, 1.0)
    shape.transform = scaleTrans
    shape.anchorPoint = .init(x: 0.5, y: 0.5)
    
    let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    backgroundView.backgroundColor = backgroundColor
    
    shape.position = CGPoint(x: backgroundView.frame.midX - (path.boundingBox.width / 2) * scale,
                             y: backgroundView.frame.midY - path.boundingBox.height * scale)
    
    backgroundView.layer.addSublayer(shape)
  
    return backgroundView
  }
  
  static func grayScaleFrom(_ pixels: [Float], size: (Int, Int)) -> UIImage? {
    let data: [UInt8] = pixels.map { UInt8(ceil(Double($0) * 255)) }
    
    guard data.count >= 8 else {
      print("data too small")
      return nil
    }
    
    let width  = size.0
    let height = size.1
    
    let colorSpace = CGColorSpaceCreateDeviceGray()
    
    guard data.count >= width * height,
          let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: width,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue),
          let buffer = context.data?.bindMemory(to: UInt8.self, capacity: width * height)
    else {
      return nil
    }
    
    for index in 0 ..< width * height {
      buffer[index] = data[index]
    }
    
    let image = context.makeImage().flatMap { UIImage(cgImage: $0) }
    
    return image
  }
}

