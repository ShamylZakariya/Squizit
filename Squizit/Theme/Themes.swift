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

}