//
//  GameControlButton
//  Squizit
//
//  Created by Shamyl Zakariya on 9/7/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class GameControlButton : UIButton {

	class func quitGameButton() -> GameControlButton {
		var btn = self.buttonWithType(UIButtonType.Custom) as! GameControlButton
		var icon = UIImage( named:"quit-game-button")?.imageWithAlpha(0.5).imageWithRenderingMode(.AlwaysTemplate)
		btn.setImage( icon, forState: UIControlState.Normal )

		return btn
	}

	class func finishTurnButton() -> GameControlButton {
		var btn = self.buttonWithType(UIButtonType.Custom) as! GameControlButton
		var icon = UIImage( named:"finish-turn-button")?.imageWithAlpha(0.5).imageWithRenderingMode(.AlwaysTemplate)
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
		layer.cornerRadius = 22.5
		layer.backgroundColor = SquizitTheme.matchButtonBackgroundColor().CGColor
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: 45, height: 45)
	}
}
