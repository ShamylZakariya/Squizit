//
//  RootView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

let ParallaxBackground = false

class RootView : UIView {

	private var _parallaxBackgroundView:UIView?
	private var _parallaxMotionOffset:CGFloat = 60

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		backgroundColor = SquizitTheme.rootScreenBackgroundColor()

		if ParallaxBackground {

			_parallaxBackgroundView = UIView(frame:CGRect.zeroRect)
			_parallaxBackgroundView!.backgroundColor = SquizitTheme.rootScreenBackgroundColor()
			_parallaxBackgroundView!.alpha = 0

			insertSubview(_parallaxBackgroundView!, atIndex: 0)

			var horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
			horizontal.minimumRelativeValue = -_parallaxMotionOffset
			horizontal.maximumRelativeValue = _parallaxMotionOffset

			var vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
			vertical.minimumRelativeValue = -_parallaxMotionOffset
			vertical.maximumRelativeValue = _parallaxMotionOffset

			var effect = UIMotionEffectGroup()
			effect.motionEffects = [horizontal, vertical]
			_parallaxBackgroundView!.addMotionEffect(effect)
		}
	}

	override func layoutSubviews() {
		if let pbv = _parallaxBackgroundView {
			pbv.frame = self.bounds.rectByInsetting(dx: -_parallaxMotionOffset, dy: -_parallaxMotionOffset)
		}
	}

	override func awakeFromNib() {

		if let pbv = _parallaxBackgroundView {
			UIView.animateWithDuration(0.5, animations: {
				() -> Void in
				pbv.alpha = 1
			})
		}

	}

}