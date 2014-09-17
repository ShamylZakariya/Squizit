//
//  RootBorderView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/16/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class RootBorderView : UIView {

	var topLeftColor:UIColor = UIColor(red: 0.49, green: 1, blue: 0, alpha: 1)
	var bottomRightColor:UIColor = UIColor(red: 1, green: 0, blue: 0.71, alpha: 1)

	var borderSize:Int = 32 {
		didSet {
			setNeedsDisplay()
		}
	}

	override func drawRect(rect: CGRect) {

		var context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		CGContextTranslateCTM(context, 0.5, 0.5)

		let bounds = self.bounds
		let borderSize = CGFloat(self.borderSize)

		func plot( x:Int, y:Int ) -> CGPoint {
			let px = x >= 0 ? CGFloat(x) * borderSize : bounds.width + CGFloat(x)*borderSize
			let py = y >= 0 ? CGFloat(y) * borderSize : bounds.height + CGFloat(y)*borderSize
			return CGPoint( x: px, y: py )
		}

		func m( p:CGPoint ) {
			CGContextMoveToPoint(context, p.x, p.y)
		}

		func l( p:CGPoint ) {
			CGContextAddLineToPoint(context, p.x, p.y)
		}

		m(plot( 1, 1))
		l(plot( 2, 1))
		l(plot( 2,-1))
		l(plot( 1,-1))
		l(plot( 1,-2))
		l(plot(-1,-2))
		l(plot(-1,-1))
		l(plot(-2,-1))
		l(plot(-2, 1))
		l(plot(-1, 1))
		l(plot(-1, 2))
		l(plot( 1, 2))
		CGContextClosePath(context)

		m(plot( 3, 1))
		l(plot(-3, 1))
		l(plot(-3, 3))
		l(plot(-1, 3))
		l(plot(-1,-3))
		l(plot(-3,-3))
		l(plot(-3,-1))
		l(plot( 3,-1))
		l(plot( 3,-3))
		l(plot( 1,-3))
		l(plot( 1, 3))
		l(plot( 3, 3))
		CGContextClosePath(context)

		CGContextSetRGBStrokeColor(context, 1, 0, 1, 1)
		CGContextSetLineWidth(context, 1)
		CGContextReplacePathWithStrokedPath(context)
		CGContextClip(context)

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let gradient = CGGradientCreateWithColors(colorSpace, [topLeftColor.CGColor,bottomRightColor.CGColor], [0.0,1.0])
		let topLeft = plot(1,1)
		let bottomRight = plot(-1,-1)
		CGContextDrawLinearGradient(context, gradient, topLeft, bottomRight, CGGradientDrawingOptions(0))

		CGContextRestoreGState(context)
	}

	override func awakeFromNib() {
		contentMode = UIViewContentMode.Redraw
		opaque = false
		backgroundColor = UIColor.clearColor()
	}

}
