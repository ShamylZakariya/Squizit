//
//  Themes.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/21/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit


class SquizitTheme {

	init() {}

	class func cubeBackgroundImage() -> UIImage {
		return UIImage(named: "cube-pattern")
	}

	class func leatherBackgroundImage() -> UIImage {
		return UIImage(named: "leather-pattern")
	}

	class func paperBackgroundImage() -> UIImage {
		return UIImage(named: "paper-pattern")
	}

	class func rootScreenBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.cubeBackgroundImage() )
	}

	class func paperBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.paperBackgroundImage() )
	}

	class func matchBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	class func matchShieldBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

}

class SquizitThemeButton : UIButton {

	override func setTitle(title: String!, forState state: UIControlState) {
		super.setTitle(title.uppercaseString, forState: state)
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		update()
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		update()
	}

	override var enabled:Bool {
		didSet {
			update()
		}
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		update()
	}

	private func update() {
		titleLabel.font = UIFont(name: "Avenir-Light", size: UIFont.buttonFontSize())
		layer.cornerRadius = 0
		layer.borderWidth = 1
		layer.backgroundColor = UIColor(white: 0.19, alpha: 0.2).CGColor
		layer.borderColor = self.tintColor.colorWithAlphaComponent(0.2).CGColor
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: UIViewNoIntrinsicMetric, height: 65)
	}

}