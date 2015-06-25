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
		var btn = self.buttonWithType(UIButtonType.Custom) as! QuitGameButton
		var icon = UIImage( named:"quit-game-button")?.imageWithRenderingMode(.AlwaysTemplate)
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
		alpha = 0.5
		layer.cornerRadius = 22.5
		layer.backgroundColor = UIColor(white: 0.19, alpha: 0.3).CGColor
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: 45, height: 45)
	}

}
