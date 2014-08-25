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

	// MARK: Private

	private func commonInit() {
		backgroundColor = SquizitTheme.matchShieldBackgroundColor()
		opaque = true
		contentMode = UIViewContentMode.Redraw
		self.layer.shadowOffset = CGSize(width: 0, height: 0)
		self.layer.shadowColor = UIColor.blackColor().CGColor
		self.layer.shadowOpacity = 0.5
		self.layer.shadowRadius = 5
	}


}