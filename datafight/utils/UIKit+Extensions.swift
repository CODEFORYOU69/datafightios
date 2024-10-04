//
//  UIKit+Extensions.swift
//  datafight
//
//  Created by younes ouasmi on 04/08/2024.
//

import UIKit

// MARK: - StyleGuide
struct StyleGuide {
    // MARK: - Dimensions
    struct Dimensions {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        static let standardCornerRadius: CGFloat = 8
        static let buttonHeight: CGFloat = 44
        static let iconSize: CGFloat = 24
        static let shadowRadius: CGFloat = 10
    }

    // MARK: - Colors
    struct Colors {
        static let primaryBackground = UIColor(
            red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0)
        static let secondaryBackground = UIColor.white
        static let accentColor = UIColor(
            red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        static let textColor = UIColor(
            red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        static let subtleText = UIColor(
            red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        static let borderColor = UIColor(
            red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    }

    // MARK: - Fonts
    struct Fonts {
        static let title = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let subtitle = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let button = UIFont.systemFont(ofSize: 16, weight: .semibold)
    }

    // MARK: - Styling Methods
    static func applyCardStyle(to view: UIView) {
        view.backgroundColor = Colors.secondaryBackground
        view.layer.cornerRadius = Dimensions.largeCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = Dimensions.shadowRadius
        view.clipsToBounds = false
    }

    static func applyButtonStyle(to button: UIButton) {
        button.backgroundColor = Colors.accentColor
        button.setTitleColor(Colors.secondaryBackground, for: .normal)
        button.layer.cornerRadius = Dimensions.standardCornerRadius
        button.titleLabel?.font = Fonts.button
        button.layer.shadowColor = Colors.accentColor.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8

        // Subtle gradient
        let gradient = CAGradientLayer()
        gradient.colors = [
            Colors.accentColor.cgColor,
            Colors.accentColor.withAlphaComponent(0.8).cgColor,
        ]
        gradient.locations = [0.0, 1.0]
        gradient.frame = button.bounds
        button.layer.insertSublayer(gradient, at: 0)

        // Haptic feedback
        button.addTarget(
            button, action: #selector(UIButton.buttonTapped),
            for: .touchUpInside)
    }

    static func applyTextFieldStyle(to textField: UITextField) {
        textField.borderStyle = .none
        textField.backgroundColor = Colors.secondaryBackground
        textField.textColor = Colors.textColor
        textField.font = Fonts.body

        textField.layer.cornerRadius = Dimensions.standardCornerRadius
        textField.layer.borderWidth = 1
        textField.layer.borderColor = Colors.borderColor.cgColor

        // Inner shadow for depth
        let innerShadow = CALayer()
        innerShadow.frame = textField.bounds
        innerShadow.shadowPath =
            UIBezierPath(
                roundedRect: innerShadow.bounds.insetBy(dx: 2, dy: 2),
                cornerRadius: Dimensions.standardCornerRadius
            ).cgPath
        innerShadow.shadowColor = UIColor.black.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 1)
        innerShadow.shadowOpacity = 0.1
        innerShadow.shadowRadius = 3
        innerShadow.cornerRadius = Dimensions.standardCornerRadius
        textField.layer.addSublayer(innerShadow)

        // Left padding for icon
        textField.leftView = UIView(
            frame: CGRect(x: 0, y: 0, width: 40, height: textField.frame.height)
        )
        textField.leftViewMode = .always
    }

    static func addIconToTextField(_ textField: UITextField, iconName: String) {
        let iconView = UIImageView(
            frame: CGRect(
                x: 10, y: 5, width: Dimensions.iconSize,
                height: Dimensions.iconSize))
        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = Colors.subtleText
        iconView.contentMode = .scaleAspectFit
        textField.leftView?.addSubview(iconView)
    }

    static func applyBackgroundGradient(to view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            Colors.primaryBackground.cgColor,
            Colors.secondaryBackground.cgColor,
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}

// MARK: - UIButton Extension
extension UIButton {
    @objc fileprivate func buttonTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - UIView Extension
extension UIView {
    func addParallaxEffect(amount: CGFloat = 10) {
        let horizontal = UIInterpolatingMotionEffect(
            keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(
            keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        addMotionEffect(group)
    }
}

// MARK: - UILabel Extension
extension UILabel {
    func applyTitleStyle() {
        font = StyleGuide.Fonts.title
        textColor = StyleGuide.Colors.textColor
    }

    func applySubtitleStyle() {
        font = StyleGuide.Fonts.subtitle
        textColor = StyleGuide.Colors.subtleText
    }
}
