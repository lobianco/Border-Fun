//
//  CALayer+Pause.swift
//
//  Copyright © 2021 Anthony Lobianco. All rights reserved.
//

import UIKit

extension CALayer {
    var isPaused: Bool {
        speed == 0.0
    }

    func pause() {
        guard isPaused == false else {
            return
        }

        speed = 0.0
    }

    func resume() {
        guard isPaused else {
            return
        }

        speed = 1.0
    }
}
