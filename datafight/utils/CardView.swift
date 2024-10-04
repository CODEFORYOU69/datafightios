//
//  CardView.swift
//  datafight
//
//  Created by younes ouasmi on 16/08/2024.
//

import Foundation
import UIKit

@IBDesignable
class CardVu: UIView {

    @IBInspectable var cornerradius: CGFloat = 2
    @IBInspectable var shadowOffsetWidth: Int = 0
    @IBInspectable var shadowOffsetHeight: Int = 3
    @IBInspectable var shadowcolor: UIColor? = UIColor.black
    @IBInspectable var shadowopacity: Float = 0.5

    override func layoutSubviews() {
        layer.cornerRadius = cornerradius
        let shadowPath = UIBezierPath(
            roundedRect: bounds, cornerRadius: cornerradius)

        layer.masksToBounds = false
        layer.shadowColor = shadowcolor?.cgColor
        layer.shadowOffset = CGSize(
            width: shadowOffsetWidth, height: shadowOffsetHeight)
        layer.shadowOpacity = shadowopacity
        layer.shadowPath = shadowPath.cgPath
    }
}
