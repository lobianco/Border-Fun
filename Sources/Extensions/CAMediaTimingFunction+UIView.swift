//
//  CAMediaTimingFunction+UIView.swift
//
//  Copyright © 2021 Anthony Lobianco. All rights reserved.
//

import Foundation
import UIKit

extension CAMediaTimingFunction {
    convenience init (from curve: UIView.AnimationCurve) {
        let functionName: CAMediaTimingFunctionName = {
            switch curve {
            case .linear:
                return CAMediaTimingFunctionName.linear
            case .easeIn:
                return CAMediaTimingFunctionName.easeIn
            case .easeOut:
                return CAMediaTimingFunctionName.easeOut
            case .easeInOut:
                return CAMediaTimingFunctionName.easeInEaseOut
            @unknown default:
                assertionFailure("value has not been handled: \(curve)")
                return CAMediaTimingFunctionName.linear
            }
        }()
        self.init(name: functionName)
    }
}
