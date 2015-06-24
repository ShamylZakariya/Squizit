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

	private var drawing:Drawing?
	private var controller:DrawingInputController?
	private var tracking:Bool = false

	override init(frame:CGRect) {
		super.init( frame: frame )
	}

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
	}

	override func drawRect(rect: CGRect) {

		let ctx = UIGraphicsGetCurrentContext()
		CGContextClipToRect(ctx, rect)

		if let vp = controller?.viewport {
			UIColor.whiteColor().set()
			UIRectFill(vp)
		}

		if drawing!.debugRender {
			UIColor.redColor().colorWithAlphaComponent(0.5).set()
			UIRectFrameUsingBlendMode(rect, kCGBlendModeNormal)
		}

		controller!.draw(ctx)
	}

	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {

		if touches.count > 1 {
			return
		}

		let touch = touches.first as! UITouch
		let location = touch.locationInView(self)
		controller!.touchBegan(location)
		tracking = true
	}

	override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {

		if !tracking {
			return
		}

		let touch = touches.first as! UITouch
		let location = touch.locationInView(self)
		controller!.touchMoved(location)
	}

	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {

		if !tracking {
			return
		}

		controller!.touchEnded()
		tracking = false
	}

	override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
		touchesEnded(touches, withEvent: event)
	}

}

class DrawingTestsViewController : UIViewController {

	private var drawingView:DrawingTestView = DrawingTestView(frame: CGRect.zeroRect)
	private var currentPanTranslation:CGPoint = CGPoint.zeroPoint

	override func viewDidLoad() {

		NSLog( "DrawingTestsViewController" )

		title = "Drawing Tests..."
		view.backgroundColor = UIColor.yellowColor()

		let drawingFrame = CGRect(x: 0, y: 0, width: 1024, height: 1024)
		drawingView.drawing = Drawing()
		drawingView.drawing!.debugRender = true
		drawingView.frame = drawingFrame
		view.addSubview(drawingView)

		let controller = DrawingInputController()
		controller.drawing = drawingView.drawing!
		controller.view = drawingView
		controller.viewport = drawingFrame
		controller.fill = Fill.Brush
		drawingView.controller = controller


		var tgr = UITapGestureRecognizer(target: self, action: "onEraseDrawing:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 1
		view.addGestureRecognizer(tgr)

		var pgr = UIPanGestureRecognizer(target: self, action: "onPan:")
		pgr.minimumNumberOfTouches = 2
		view.addGestureRecognizer(pgr)

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "DEBUG", style: UIBarButtonItemStyle.Plain, target: self, action: "onToggleDebugRendering:")
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "UNDO", style: UIBarButtonItemStyle.Plain, target: self, action: "onUndo:")
	}

	override func viewWillLayoutSubviews() {
	}

	// MARK: - Actions

	dynamic private func onUndo( sender:AnyObject ) {
		drawingView.controller!.undo()
	}

	dynamic private func onEraseDrawing( sender:AnyObject ) {
		drawingView.drawing!.clear()
		drawingView.setNeedsDisplay()
	}

	dynamic private func onToggleDebugRendering( sender:AnyObject ) {
		drawingView.drawing!.debugRender = !drawingView.drawing!.debugRender
		drawingView.setNeedsDisplay()
	}

	dynamic private func onPan(pgr:UIPanGestureRecognizer) {
		var translation = pgr.translationInView(view)
		translation.x = round(translation.x)
		translation.y = round(translation.y)

		switch pgr.state {
		case .Began:
			let affine = CATransform3DGetAffineTransform(drawingView.layer.transform)
			currentPanTranslation.x = affine.tx
			currentPanTranslation.y = affine.ty
			drawingView.layer.transform = CATransform3DMakeTranslation(currentPanTranslation.x + translation.x, currentPanTranslation.y + translation.y, 0)

		case .Changed:
			drawingView.layer.transform = CATransform3DMakeTranslation(currentPanTranslation.x + translation.x, currentPanTranslation.x + translation.y, 0)

		case .Possible, .Ended,.Cancelled,.Failed:
			break;
		}
	}

}