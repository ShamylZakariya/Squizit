//
//  DrawingTestsViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/8/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class DrawingTestView : UIView {

	var drawing:Drawing?
	var controller:DrawingInputController?
	var _tracking:Bool = false

	override init(frame:CGRect) {
		super.init( frame: frame )
		backgroundColor = UIColor.yellowColor()
	}

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		backgroundColor = UIColor.yellowColor()
	}

	override func drawRect(rect: CGRect) {

		let ctx = UIGraphicsGetCurrentContext()
		CGContextClipToRect(ctx, rect)

		if let vp = controller?.viewport {
			UIColor.whiteColor().set()
			UIRectFill(vp)
		}

		UIColor.redColor().colorWithAlphaComponent(0.5).set()
		UIRectFrameUsingBlendMode(rect, kCGBlendModeNormal)

		controller!.draw(ctx)
	}

	override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {

		if touches.count > 1 {
			return
		}

		let location = touches.anyObject()!.locationInView(self)
		controller!.touchBegan(location)
		_tracking = true
	}

	override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {

		if !_tracking {
			return
		}

		let location = touches.anyObject()!.locationInView(self)
		controller!.touchMoved(location)
	}

	override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {

		if !_tracking {
			return
		}

		controller!.touchEnded()
		_tracking = false
	}

	override func touchesCancelled(touches: NSSet, withEvent event: UIEvent) {
		touchesEnded(touches, withEvent: event)
	}

}

class DrawingTestsViewController : UIViewController {

	var drawingView:DrawingTestView = DrawingTestView(frame: CGRect.zeroRect)

	override func viewDidLoad() {

		NSLog( "DrawingTestsViewController" )

		self.title = "Drawing Tests..."

		drawingView.drawing = Drawing()
		drawingView.drawing!.debugRender = true

		let controller = DrawingInputController()
		controller.drawing = drawingView.drawing!
		controller.view = drawingView
		controller.viewport = CGRect(x: 0, y: 0, width: 768, height: 1024).rectByInsetting(dx: 100, dy: 100)
		controller.fill = Fill.Brush
		drawingView.controller = controller

		view.addSubview(drawingView)

		var tgr = UITapGestureRecognizer(target: self, action: "eraseDrawing:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 1
		drawingView.addGestureRecognizer(tgr)

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "DEBUG", style: UIBarButtonItemStyle.Plain, target: self, action: "toggleDebugRendering:")

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "UNFO", style: UIBarButtonItemStyle.Plain, target: self, action: "undo:")
	}

	override func viewWillLayoutSubviews() {
		drawingView.frame = view.bounds
	}

	dynamic func undo( sender:AnyObject ) {
		drawingView.controller!.undo()
	}

	dynamic func eraseDrawing( sender:AnyObject ) {
		drawingView.drawing!.clear()
		drawingView.setNeedsDisplay()
	}

	dynamic func toggleDebugRendering( sender:AnyObject ) {
		drawingView.drawing!.debugRender = !drawingView.drawing!.debugRender
		drawingView.setNeedsDisplay()
	}

}