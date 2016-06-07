//
//  RootBorderView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/16/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class RootBorderView : UIView {

	var topLeftColor:UIColor = UIColor(red: 0.49, green: 1, blue: 0, alpha: 1) {
		didSet {
			setNeedsDisplay()
		}
	}

	var bottomRightColor:UIColor = UIColor(red: 1, green: 0, blue: 0.71, alpha: 1) {
		didSet {
			setNeedsDisplay()
		}
	}

	var borderSize:Int = 32 {
		didSet {
			setNeedsDisplay()
		}
	}

	var edgeInsets:UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
		didSet {
			setNeedsDisplay()
		}
	}

	override func drawRect(rect: CGRect) {

		var context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		CGContextTranslateCTM(context, 0.5, 0.5)


		let frame = UIEdgeInsetsInsetRect(bounds, edgeInsets)
		let borderSize = CGFloat(self.borderSize)

		func plot( x:Int, y:Int ) -> CGPoint {
			let px = x >= 0 ? frame.minX + CGFloat(x) * borderSize : frame.maxX + CGFloat(x)*borderSize
			let py = y >= 0 ? frame.minY + CGFloat(y) * borderSize : frame.maxY + CGFloat(y)*borderSize
			return CGPoint( x: px, y: py )
		}

		func m( p:CGPoint ) {
			CGContextMoveToPoint(context, p.x, p.y)
		}

		func l( p:CGPoint ) {
			CGContextAddLineToPoint(context, p.x, p.y)
		}

		m(plot( 1, y: 1))
		l(plot( 2, y: 1))
		l(plot( 2,y: -1))
		l(plot( 1,y: -1))
		l(plot( 1,y: -2))
		l(plot(-1,y: -2))
		l(plot(-1,y: -1))
		l(plot(-2,y: -1))
		l(plot(-2, y: 1))
		l(plot(-1, y: 1))
		l(plot(-1, y: 2))
		l(plot( 1, y: 2))
		CGContextClosePath(context)

		m(plot( 3, y: 1))
		l(plot(-3, y: 1))
		l(plot(-3, y: 3))
		l(plot(-1, y: 3))
		l(plot(-1,y: -3))
		l(plot(-3,y: -3))
		l(plot(-3,y: -1))
		l(plot( 3,y: -1))
		l(plot( 3,y: -3))
		l(plot( 1,y: -3))
		l(plot( 1, y: 3))
		l(plot( 3, y: 3))
		CGContextClosePath(context)

		CGContextSetLineWidth(context, 1)
		CGContextSetLineCap(context, CGLineCap.Square)

		CGContextReplacePathWithStrokedPath(context)
		CGContextClip(context)

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let gradient = CGGradientCreateWithColors(colorSpace, [topLeftColor.CGColor,bottomRightColor.CGColor], [0.0,1.0])
		let topLeft = plot(1,y: 1)
		let bottomRight = plot(-1,y: -1)
		CGContextDrawLinearGradient(context, gradient, topLeft, bottomRight, CGGradientDrawingOptions(rawValue: 0))

		// fix a rendering error on retina where the top left point of the path isn't drawn
		let pointRect = CGRect(center: plot(1,y: 1), radius: 0.5)
		CGContextSetFillColorWithColor(context, topLeftColor.CGColor)
		CGContextFillRect(context, pointRect)

		CGContextRestoreGState(context)
	}

	override func awakeFromNib() {
		contentMode = UIViewContentMode.Redraw
		opaque = false
		backgroundColor = UIColor.clearColor()
	}

}
