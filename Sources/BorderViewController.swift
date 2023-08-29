//
//  ViewController.swift
//
//  Copyright © 2021 Anthony Lobianco. All rights reserved.
//

import UIKit

final class BorderViewController: UIViewController {
    // MARK: Private Properties

    private let showAnimator: UIViewPropertyAnimator = UIViewPropertyAnimator(
        duration: Metrics.showAnimationDuration,
        dampingRatio: Metrics.showAnimationDampingRatio,
        animations: nil
    )
    private let hideAnimator: UIViewPropertyAnimator = UIViewPropertyAnimator(
        duration: Metrics.hideAnimationDuration,
        curve: .easeOut,
        animations: nil
    )
    private let borderOffset: CGFloat = Metrics.antiAliasingBorderOffset // to mitigate jagged edges around the corners of the border
    private var borderView: BorderView?

    // MARK: Public Properties

    var cornerRadius: CGFloat = Metrics.defaultCornerRadius {
        didSet {
            applyDefaultMaskLayerValues()
        }
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        drawBorder()
    }
    
    // MARK: Public Methods
    
    func showBorder() {
        guard showAnimator.isRunning == false else {
            return
        }
        
        if hideAnimator.isRunning == false {
            // we're being animated in from a cold state (e.g. not interrupting
            // an already-running outbound animation). start animation at an
            // expanded state. we wouldn't want to apply this transform if this
            // animation was interrupting an outbound animation because we want
            // the animations to begin from their current state.
            //
            applyHideTransform()
        }
        
        hideAnimator.stopAnimation(true)
        
        showAnimator.addAnimations {
            self.applyShowTransform()
        }
        
        showAnimator.startAnimation()
    }
    
    func hideBorder(completion: (() -> Void)?) {
        guard hideAnimator.isRunning == false else {
            return
        }

        showAnimator.stopAnimation(true)
        
        hideAnimator.addAnimations {
            self.applyHideTransform()
        }
        
        // this won't be called if the animation is interrupted, which is what we want
        hideAnimator.addCompletion { _ in
            completion?()
            
            // reset view transform and mask values after the outgoing animation completes.
            // this is necessary because if we leave the non-identity values assigned, then
            // the calculations made in the rotation function below won't be accurate because
            // they rely on a non-transformed view.
            //
            self.applyShowTransform()
            self.applyDefaultMaskLayerValues()
        }
        
        hideAnimator.startAnimation()
    }
    
    func drawBorder() {
        let viewBounds = adjustedRectForBorderView(with: view.bounds)
        let borderView = BorderView(frame: viewBounds)
        view.addSubview(borderView)
        self.borderView = borderView
        applyDefaultMaskLayerValues()
    }
    
    // MARK: Private Methods
    
    private func applyShowTransform() {
        view.transform = CGAffineTransform.identity
        view.alpha = 1
    }
    
    private func applyHideTransform() {
        view.transform = CGAffineTransform(scaleX: CGFloat(1.03), y: CGFloat(1.02))
        
        // no need to go all the way to 0 because view will start and end the animations
        // offscreen and a smaller range of alpha animation looks better.
        //
        view.alpha = 0.2
    }
    
    private func applyDefaultMaskLayerValues() {
        borderView?.maskLayer?.path = pathForMaskLayer(with: view.bounds)
        borderView?.maskLayer?.frame = adjustedRectForMaskLayer(with: view.bounds)
    }
    
    private func adjustedRectForBorderView(with bounds: CGRect) -> CGRect {
        // expand the bounds of the border view a bit so that it is placed slightly offscreen,
        // to mitigate jagged edges near the corners after applying the rounding mask.
        //
        bounds.insetBy(dx: -borderOffset, dy: -borderOffset)
    }
    
    private func adjustedRectForMaskLayer(with bounds: CGRect) -> CGRect {
        // offset the bounds that the mask layer will use, since it will be positioned relative
        // to the border view's bounds.
        //
        bounds.insetBy(dx: borderOffset, dy: borderOffset)
    }
    
    private func pathForMaskLayer(with bounds: CGRect) -> CGPath {
        // use the view's default bounds when calculating the rounded path to make the corners
        // match the screen's corners.
        //
        UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
    
    // MARK: Rotation
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        assert(view.transform.isIdentity, "shouldn't be able to enter this scope with a non-identity transform")
        
        // calculate new bounds
        let futureBounds = CGRect(origin: view.bounds.origin, size: size)
        let newViewBounds = adjustedRectForBorderView(with: futureBounds)
        let newMaskFrame = adjustedRectForMaskLayer(with: futureBounds)
        let newMaskPath = pathForMaskLayer(with: futureBounds)
        
        // first, update the mask layer's frame (no animation required)
        borderView?.maskLayer?.frame = newMaskFrame
        
        coordinator.animate(alongsideTransition: { context in
            // then animate the border view's new frame
            self.borderView?.frame = newViewBounds
            
            // finally, create an explicit animation to update the mask layer's path
            let maskAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
            maskAnimation.fromValue = self.borderView?.maskLayer?.path
            maskAnimation.toValue = newMaskPath
            maskAnimation.duration = context.transitionDuration
            maskAnimation.timingFunction = CAMediaTimingFunction(from: context.completionCurve)
            
            self.borderView?.maskLayer?.path = newMaskPath
            self.borderView?.maskLayer?.add(maskAnimation, forKey: #keyPath(CAShapeLayer.path))
        }, completion: nil)
    }
}

// MARK: - Metrics

private enum Metrics {
    // to mitigate aliasing around the edges
    static let antiAliasingBorderOffset: CGFloat = 2.0

    // duration of the presentation animation
    static let showAnimationDuration: TimeInterval = 1.0

    // oscillation deceleration during the presentation animation
    static let showAnimationDampingRatio: CGFloat = 0.55

    // duration of the presentation animation
    static let hideAnimationDuration: TimeInterval = 0.4

    // this is just an initial guess. different iOS devices have different corner radii and the user will be able
    // to adjust this value with a stepper.
    //
    static let defaultCornerRadius: CGFloat = 56
}
