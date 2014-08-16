//
//  SimplifiedDrawingView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class SimplifiedDrawingView : UIView {


	var drawing:Drawing = Drawing(width: 512, height: 512) {
		didSet {
			drawingInputAdapter.drawing = drawing
		}
	}

	var drawingInputAdapter = DrawingInputAdapter()

	private var tracking:Bool = false

	required init(coder aDecoder: NSCoder!) {
		super.init( coder: aDecoder )

		backgroundColor = UIColor.whiteColor()
		contentMode = .Redraw


		drawing.backgroundColor = UIColor.yellowColor()
		drawingInputAdapter.drawing = drawing
		drawingInputAdapter.view = self
	}

	override func drawRect(rect: CGRect) {
		drawingInputAdapter.draw(UIGraphicsGetCurrentContext())
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let size = drawing.size
		let viewCenter = CGPointMake( self.bounds.midX, self.bounds.midY )
		let topLeftCorner = CGPointMake( floor(viewCenter.x - size.width/2), floor(viewCenter.y - size.height/2) )

		drawingInputAdapter.transform = CGAffineTransformMakeTranslation(topLeftCorner.x, topLeftCorner.y)
	}

	override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {

		if touches.count > 1 {
			return
		}

		if let touch = touches.anyObject() as? UITouch {
			tracking = true
			drawingInputAdapter.touchBegan(touch.locationInView(self))
		}
	}

	override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
		if !tracking {
			return
		}

		if let touch = touches.anyObject() as? UITouch {
			drawingInputAdapter.touchMoved(touch.locationInView(self))
		}
	}

	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
		tracking = false
		drawingInputAdapter.touchEnded()
	}

	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
		touchesEnded(touches, withEvent: event)
	}

}