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
			DrawingInputController.drawing = drawing
		}
	}

	var DrawingInputController = DrawingInputController()

	private var tracking:Bool = false

	required init(coder aDecoder: NSCoder!) {
		super.init( coder: aDecoder )

		backgroundColor = UIColor.whiteColor()
		contentMode = .Redraw


		drawing.backgroundColor = UIColor.yellowColor()
		DrawingInputController.drawing = drawing
		DrawingInputController.view = self
	}

	override func drawRect(rect: CGRect) {
		DrawingInputController.draw(UIGraphicsGetCurrentContext())
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let size = drawing.size
		let viewCenter = CGPointMake( self.bounds.midX, self.bounds.midY )
		let topLeftCorner = CGPointMake( floor(viewCenter.x - size.width/2), floor(viewCenter.y - size.height/2) )

		DrawingInputController.transform = CGAffineTransformMakeTranslation(topLeftCorner.x, topLeftCorner.y)
	}

	override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {

		if touches.count > 1 {
			return
		}

		if let touch = touches.anyObject() as? UITouch {
			tracking = true
			DrawingInputController.touchBegan(touch.locationInView(self))
		}
	}

	override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
		if !tracking {
			return
		}

		if let touch = touches.anyObject() as? UITouch {
			DrawingInputController.touchMoved(touch.locationInView(self))
		}
	}

	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
		tracking = false
		DrawingInputController.touchEnded()
	}

	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
		touchesEnded(touches, withEvent: event)
	}

}