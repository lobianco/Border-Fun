//
//  UIColor+Utils.swift
//
//  Copyright © 2021 Anthony Lobianco. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(redInt: Int, greenInt: Int, blueInt: Int, alpha: CGFloat = 1) {
        [redInt, greenInt, blueInt].forEach { value in
            assert(value >= 0 && value <= 255)
        }

        let red = CGFloat(redInt) / 255.0
        let green = CGFloat(greenInt) / 255.0
        let blue = CGFloat(blueInt) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
