//
//  QuitGameButton.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/7/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class QuitGameButton: UIButton {

	class func quitGameButton() -> QuitGameButton {
		var btn = self.buttonWithType(UIButtonType.Custom) as QuitGameButton
		var icon = UIImage( named:"quit-game-button-icon")
		btn.setImage( icon, forState: UIControlState.Normal )

		return btn
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
		layer.cornerRadius = 22
		layer.borderWidth = 1
		layer.backgroundColor = UIColor(white: 0.19, alpha: 0.2).CGColor
		layer.borderColor = self.tintColor!.colorWithAlphaComponent(0.2).CGColor
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: 44, height: 44)
	}

}
