//
//  RootViewController.swift
//
//  Copyright © 2021 Anthony Lobianco. All rights reserved.
//

import UIKit

final class RootViewController: UIViewController {
    // MARK: Interface Builder

    @IBOutlet var borderButton: UIButton!
    @IBOutlet var simulatorTitleLabel: UILabel!
    @IBOutlet var simulatorSubtitleLabel: UILabel!
    @IBOutlet var cornerRadiusLabel: UILabel!
    @IBOutlet var cornerRadiusStepper: UIStepper!
    @IBOutlet var bottomSpacerView: UIView!

    // MARK: Private Properties

    private let windowManager: BorderWindowManager = BorderWindowManager()

    // MARK: Lifecycle

    init() {
        super.init(nibName: String(describing: Self.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(redInt: 25, greenInt: 35, blueInt: 45)

        borderButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        cornerRadiusStepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
        cornerRadiusStepper.tintColor = .white
        cornerRadiusStepper.layer.borderColor = UIColor.lightGray.cgColor
        cornerRadiusStepper.layer.borderWidth = 1
        cornerRadiusStepper.layer.cornerRadius = 8

        cornerRadiusLabel.text = "Corner radius: \(Int(windowManager.boderCornerRadius))"
        simulatorTitleLabel.text = "(Why the stepper?)"
        simulatorSubtitleLabel.text = "Since there's no way to get the corner radius of an iOS device's screen programmatically, the corner radius values used by the border view must be hardcoded. :("
    }

    // MARK: Private Methods

    @objc
    private func buttonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.isSelected ? windowManager.showWindow() : windowManager.hideWindow()
    }

    @objc
    private func stepperChanged(_ sender: UIStepper) {
        windowManager.boderCornerRadius = CGFloat(sender.value)
        cornerRadiusLabel.text = "Corner radius: \(Int(sender.value))"
    }

    // MARK: Rotation

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        simulatorTitleLabel.isHidden = size.width > size.height
        simulatorSubtitleLabel.isHidden = size.width > size.height
        bottomSpacerView.isHidden = size.width > size.height
    }
}
