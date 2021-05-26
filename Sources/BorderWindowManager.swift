//
//  ViewController.swift
//
//  Copyright © 2021 Anthony Lobianco. All rights reserved.
//

import UIKit

// MARK: WindowManagerDelegate

protocol WindowManagerDelegate: AnyObject {
    func windowManagerDidShowWindow(sender: BorderWindowManager)
    func windowManagerDidHideWindow(sender: BorderWindowManager)
}

// MARK: WindowManager

final class BorderWindowManager {

    // MARK: Private Properties

    private let windowLevel: UIWindow.Level = UIWindow.Level.alert + 100

    // lazily evaluates to a UIWindow that lives at a very high window level,
    // with an initial alpha of 0 so it can be animated into place, and with
    // user interaction disabled so it does not consume any touches.
    //
    private lazy var window: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = nil
        window.isHidden = true
        window.rootViewController = rootViewController
        window.isUserInteractionEnabled = false
        window.windowLevel = windowLevel
        return window
    }()

    private let rootViewController: BorderViewController = BorderViewController()

    // MARK: Public Properties

    fileprivate(set) var isShowing: Bool = false
    weak var delegate: WindowManagerDelegate?
    var boderCornerRadius: CGFloat {
        get {
            rootViewController.cornerRadius
        }
        set {
            rootViewController.cornerRadius = newValue
        }
    }

    // MARK: Public Methods

    func showWindow() {
        window.isHidden = false
        rootViewController.showBorder()
        isShowing = true
        delegate?.windowManagerDidShowWindow(sender: self)
    }

    func hideWindow(completion: (() -> Void)? = nil) {
        // `completion` will not be called if `showWindow()` is called before `hideWindow()` completes, which is what we want.
        rootViewController.hideBorder(completion: {
            self.window.isHidden = true
            self.isShowing = false
            completion?()
            self.delegate?.windowManagerDidHideWindow(sender: self)
        })
    }
}

