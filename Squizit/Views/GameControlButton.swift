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
		let btn = GameControlButton(type: .Custom)
		let icon = UIImage( named:"quit-game-button")?.imageWithAlpha(0.5).imageWithRenderingMode(.AlwaysTemplate)
		btn.setImage( icon, forState: UIControlState.Normal )

		return btn
	}

	class func finishTurnButton() -> GameControlButton {
		let btn = GameControlButton(type: .Custom)
		let icon = UIImage( named:"finish-turn-button")?.imageWithAlpha(0.5).imageWithRenderingMode(.AlwaysTemplate)
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

	override func layoutSubviews() {
		super.layoutSubviews()
		update()
	}

	override var enabled:Bool {
		didSet {
			UIView.animateWithDuration(0.3, animations: { [unowned self] in
				self.layer.opacity = self.enabled ? 1 : 0.5
			})
		}
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		update()
	}

	private func update() {
		layer.cornerRadius = min(bounds.width,bounds.height)/2
		backgroundColor = UIColor.clearColor()
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: 45, height: 45)
	}
}
