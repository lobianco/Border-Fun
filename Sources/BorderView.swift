//
//  BorderView.swift
//
//  Copyright © 2021 Anthony Lobianco. All rights reserved.
//

import Foundation
import UIKit

// the angle that the gradient will travel. look at a unit circle and find the line
// with the given angle. the gradient will travel from the edge of the circle towards
// the center along that line.
//
enum GradientAngle {
    case slope90 // top to bottom
    case slope135 // top left to bottom right
    case slope180 // left to right
    case slope225 // bottom left to top right
    case slope270 // bottom to top
    case slope360 // right to left
}

final class BorderView: ForeverAnimatingView {
    
    // MARK: Public Properties
    
    var gradientColors: [UIColor] = Metrics.defaultGradientColors {
        didSet {
            reloadGradient()
        }
    }
    
    var gradientAngle: GradientAngle = Metrics.gradientAngle {
        didSet {
            reloadGradient()
        }
    }
    
    var animationDuration: Int = Metrics.gradientAnimationDuration {
        didSet {
            reloadGradient()
        }
    }
    
    var maskLayer: CAShapeLayer? {
        layer.mask as? CAShapeLayer
    }
    
    // MARK: Lifecycle
    
    override class var layerClass: AnyClass {
        CAGradientLayer.classForCoder()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        drawGradient()
        createMask()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private Methods
    
    private func reloadGradient() {
        layer.removeAnimation(forKey: #keyPath(CAGradientLayer.locations))
        drawGradient()
    }
    
    private func drawGradient() {
        guard let layer = layer as? CAGradientLayer else {
            return
        }
        
        // gradient colors
        let orderedColors = gradientColors
        
        // number of colors onscreen simultaneously. value should be 1 < x <= orderedColors.count
        let colorGradation = Metrics.gradientColorGradation
        assert(colorGradation > 1 && colorGradation <= orderedColors.count)
        
        // the animation loop will use this many gradient stops
        let totalStops = (orderedColors.count * colorGradation) + (colorGradation % orderedColors.count)
        
        // total animation duration, accounting for the color padding on each end of the animation
        // to create the illusion of an infinite animation cycle.
        //
        let totalDuration = (animationDuration * (totalStops / orderedColors.count))
        let locationInterval = (1.0 / Double(colorGradation - 1))
        
        var startPoints: [Double] = []
        var endPoints: [Double] = []
        var colors: [UIColor] = []
        
        for index in 0..<totalStops {
            // increment and decrement the start and end points, respectively, using the
            // calculated interval
            //
            
            let nextStartPoint = index == 0 ? 1.0 : startPoints[index - 1] - locationInterval
            startPoints.append(nextStartPoint)
            
            let nextEndPoint = index == 0 ? 0.0 : endPoints[index - 1] + locationInterval
            endPoints.append(nextEndPoint)
            
            let nextColor = orderedColors[index % orderedColors.count]
            colors.append(nextColor)
        }
        
        // startPoints was populated in reverse
        let startLocations = startPoints.reversed().map({ NSNumber(value: $0) })
        let endLocations = endPoints.map({ NSNumber(value: $0) })
        let edgePoints = Self.gradientPoints(for: gradientAngle)
        
        layer.colors = colors.map({ $0.cgColor })
        layer.startPoint = edgePoints.0
        layer.endPoint = edgePoints.1
        layer.locations = startLocations
        
        if UIAccessibility.isReduceMotionEnabled == false {
            // this will create an infinite "scrolling" effect on the gradient layer
            let gradientAnimation = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.locations))
            gradientAnimation.fromValue = startLocations
            gradientAnimation.toValue = endLocations
            gradientAnimation.duration = TimeInterval(totalDuration)
            gradientAnimation.fillMode = .forwards
            gradientAnimation.repeatCount = .greatestFiniteMagnitude
            gradientAnimation.isRemovedOnCompletion = false
            
            layer.add(gradientAnimation, forKey: #keyPath(CAGradientLayer.locations))
        }
    }
    
    private func createMask() {
        let maskLayer = CAShapeLayer()
        maskLayer.fillColor = nil
        maskLayer.strokeColor = UIColor.black.cgColor
        maskLayer.lineWidth = Metrics.borderWidth

        // comment out this line to get a better idea of the animation in action.
        layer.mask = maskLayer
    }
}

private extension BorderView {
    static func gradientPoints(for angle: GradientAngle) -> (CGPoint, CGPoint) {
        // look at a unit circle and find the line with the given angle. the
        // gradient will travel from the edge of the circle towards the center
        // along that line.
        //
        
        var startPoint: CGPoint
        var endPoint: CGPoint
        
        switch angle {
        case .slope90:
            startPoint = CGPoint(x: 0.5, y: 0)
            endPoint = CGPoint(x: 0.5, y: 1)
        case .slope135:
            startPoint = CGPoint(x: 0, y: 0)
            endPoint = CGPoint(x: 1, y: 1)
        case .slope180:
            startPoint = CGPoint(x: 0, y: 0.5)
            endPoint = CGPoint(x: 1, y: 0.5)
        case .slope225:
            startPoint = CGPoint(x: 0, y: 1)
            endPoint = CGPoint(x: 1, y: 0)
        case .slope270:
            startPoint = CGPoint(x: 0.5, y: 1)
            endPoint = CGPoint(x: 0.5, y: 0)
        case .slope360:
            startPoint = CGPoint(x: 1, y: 0.5)
            endPoint = CGPoint(x: 0, y: 0.5)
        }
        
        return (startPoint, endPoint)
    }
}

// MARK: - ForeverAnimatingView

/// A view that will restore running animations when app transitions to and from the background.
class ForeverAnimatingView: UIView {
    // MARK: Private Properties
    
    private var persistentAnimations: [String: CAAnimation] = [:]
    
    // MARK: Public Methods
    
    func pauseAnimations() {
        // make sure speed is 1 in order to retrieve animations from the layer
        layer.speed = 1.0
        
        layer.animationKeys()?.forEach({ key in
            if let animation = layer.animation(forKey: key) {
                persistentAnimations[key] = animation
            }
        })
        
        layer.pause()
    }
    
    func restoreAnimations() {
        Array(persistentAnimations.keys).forEach { key in
            if let persistentAnimation = persistentAnimations[key] {
                layer.add(persistentAnimation, forKey: key)
            }
        }
        
        persistentAnimations.removeAll()
        
        layer.resume()
    }
}

// MARK: - Metrics

private enum Metrics {
    // width of the border
    static let borderWidth: CGFloat = 20

    // duration in seconds that it takes to cycle through the ordered colors once
    static let gradientAnimationDuration: Int = 5
    
    // number of colors onscreen simultaneously. value should be 1 < x <= gradientColors.count
    static let gradientColorGradation: Int = 2

    // the direction that the gradient will animate
    static let gradientAngle: GradientAngle = .slope225
    
    // colors to use in the gradient animation
    static let defaultGradientColors: [UIColor] = [
        UIColor(redInt: 104, greenInt: 35, blueInt: 140),
        UIColor(redInt: 215, greenInt: 46, blueInt: 210),
        UIColor(redInt: 86, greenInt: 186, blueInt: 196),
        UIColor(redInt: 31, greenInt: 61, blueInt: 120)
    ]
}
