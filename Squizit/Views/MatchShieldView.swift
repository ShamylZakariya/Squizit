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

	override init(frame: CGRect) {
		shieldColor = UIColor.blackColor()
		marginColor = UIColor.clearColor()

		super.init(frame: frame)

		contentMode = UIViewContentMode.Redraw
		opaque = false
	}

	required init(coder aDecoder: NSCoder) {
		shieldColor = UIColor.blackColor()
		marginColor = UIColor.clearColor()

		super.init(coder: aDecoder)

		contentMode = UIViewContentMode.Redraw
		opaque = false
	}

	var topMargin:CGFloat = 0 {
		didSet {
			update()
		}
	}

	var bottomMargin:CGFloat = 0 {
		didSet {
			update()
		}
	}

	var shieldColor:UIColor {
		didSet {
			setNeedsDisplay()
		}
	}

	var marginColor:UIColor {
		didSet {
			setNeedsDisplay()
		}
	}

	private func update() {
		setNeedsDisplay()
	}

	// MARK: UIView overrides

	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		return false
	}

	override func drawRect(rect: CGRect) {
		let bounds = self.bounds
		var y:CGFloat = 0
		var height = bounds.height

		if topMargin > 0 {
			marginColor.set()
			UIBezierPath(rect: CGRect(x: 0, y: 0, width: bounds.width, height: topMargin)).fill()
			y += topMargin
			height -= topMargin
		}

		if bottomMargin > 0 {
			marginColor.set()
			UIBezierPath(rect: CGRect(x: 0, y: y+height-bottomMargin, width: bounds.width, height: bottomMargin)).fill()
			height -= bottomMargin
		}

		shieldColor.set()
		UIBezierPath( rect: CGRect(x: 0, y: y, width: bounds.width, height: height)).fill()
	}

}