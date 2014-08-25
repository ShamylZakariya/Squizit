//
//  MatchShieldView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/22/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class MatchShieldView : UIView {

	private var _pattern = SquizitTheme.gameBackgroundColorPattern()
	private var _color = UIColor(white: 0.12, alpha: 0.8)

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	// MARK: UIView overrides

	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		return false
	}

	override func drawRect(rect: CGRect) {
		_pattern.set()
		UIRectFillUsingBlendMode(self.bounds, kCGBlendModeNormal)

		_color.set()
		UIRectFillUsingBlendMode(self.bounds, kCGBlendModeNormal)
	}

	// MARK: Private

	private func commonInit() {
		opaque = true
		contentMode = UIViewContentMode.Redraw
		self.layer.shadowOffset = CGSize(width: 0, height: 0)
		self.layer.shadowColor = UIColor.blackColor().CGColor
		self.layer.shadowOpacity = 0.5
		self.layer.shadowRadius = 5
	}


}