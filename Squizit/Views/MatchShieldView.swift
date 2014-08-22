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

		backgroundColor = UIColor.blackColor()
		opaque = false
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		backgroundColor = UIColor.blackColor()
		opaque = false
	}

	private func update() {
		setNeedsDisplay()
	}

	// MARK: UIView overrides

	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		return false
	}

}