//
//  UIView+AnchorPoint.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit

extension UIView {

	// from http://stackoverflow.com/questions/1968017/changing-my-calayers-anchorpoint-moves-the-view
	func setAnchorPoint( newAnchorPoint:CGPoint ) {
		var newPoint:CGPoint = CGPoint(x: bounds.size.width * newAnchorPoint.x, y: bounds.size.height * newAnchorPoint.y)
		var oldPoint:CGPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y:bounds.size.height * layer.anchorPoint.y)

		newPoint = CGPointApplyAffineTransform(newPoint, transform)
		oldPoint = CGPointApplyAffineTransform(oldPoint, transform)

		var position = layer.position

		position.x -= oldPoint.x
		position.x += newPoint.x

		position.y -= oldPoint.y
		position.y += newPoint.y

		layer.position = position
		layer.anchorPoint = newAnchorPoint
	}
	
}

