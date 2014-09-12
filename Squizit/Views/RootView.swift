//
//  RootView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class RootView : UIView {

	private var _view:UIView = UIView(frame:CGRect.zeroRect)
	private var _motionOffset:CGFloat = 60

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		backgroundColor = UIColor.redColor()
		_view.backgroundColor = SquizitTheme.rootScreenBackgroundColor()
		insertSubview(_view, atIndex: 0)
		addParallaxEffect()
	}

	override func layoutSubviews() {
		_view.frame = self.bounds.rectByInsetting(dx: -_motionOffset, dy: -_motionOffset)
	}

	private func addParallaxEffect() {
		var horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
		horizontal.minimumRelativeValue = -_motionOffset
		horizontal.maximumRelativeValue = _motionOffset

		var vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
		vertical.minimumRelativeValue = -_motionOffset
		vertical.maximumRelativeValue = _motionOffset

		var effect = UIMotionEffectGroup()
		effect.motionEffects = [horizontal, vertical]
		_view.addMotionEffect(effect)
	}
}