//
//  DrawingTestsViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/8/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class ScalingDrawingContainer : UIView {

	private var currentPanTranslation = CGPoint.zeroPoint
	private var initialPanTranslation = CGPoint.zeroPoint

	private var panning:Bool = false {
		didSet {
			currentPanTranslation = CGPoint(x: bounds.width/2 - drawingSize.width/2, y: bounds.height/2 - drawingSize.height/2)
			setNeedsLayout()
		}
	}

	private var drawingSize:CGSize {
		if let drawingView = drawingView {
			return drawingView.controller!.viewport.size
		} else {
			return CGSize.zeroSize
		}
	}

	var drawingView:DrawingView? {
		didSet {
			if let drawingView = drawingView {
				drawingView.layer.anchorPoint = CGPoint(x: 0, y: 0)
				addSubview(drawingView)
				setNeedsLayout()
			}
		}
	}

	override init(frame:CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		commonInit()
	}

	private func commonInit() {
		var pgr = UIPanGestureRecognizer(target: self, action: "onPan:")
		pgr.minimumNumberOfTouches = 2
		addGestureRecognizer(pgr)

		var tgr = UITapGestureRecognizer(target: self, action: "onTogglePanning:")
		tgr.numberOfTouchesRequired = 2
		tgr.numberOfTapsRequired = 2
		addGestureRecognizer(tgr)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		if let drawingView = drawingView {

			if !panning {

				// compute max scale to fit drawingView in view
				let size = drawingView.controller!.viewport.size
				var scaledSize = size
				var scale = CGFloat(1)

				if size.width > self.bounds.width {
					scale = self.bounds.width / scaledSize.width
					scaledSize.width = size.width * scale
					scaledSize.height = size.height * scale
				}

				if size.height > self.bounds.height {
					scale *= self.bounds.height / scaledSize.height
					scaledSize.width = size.width * scale
					scaledSize.height = size.height * scale
				}

				// centering offset
				let offset = CGPoint(x: (bounds.width-scaledSize.width)/2, y: (bounds.height-scaledSize.height)/2).integerPoint()

				// set
				drawingView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
				drawingView.layer.transform = CATransform3DConcat(CATransform3DMakeScale(scale, scale, 1), CATransform3DMakeTranslation(offset.x, offset.y, 1))
			} else {
				updatePan()
			}
		}
	}

	private dynamic func onPan(pgr:UIPanGestureRecognizer) {
		if let drawingView = drawingView where panning {
			var translation = pgr.translationInView(self)
			translation.x = round(translation.x)
			translation.y = round(translation.y)

			switch pgr.state {
			case .Began:
				initialPanTranslation.x = currentPanTranslation.x
				initialPanTranslation.y = currentPanTranslation.y
				currentPanTranslation.x = initialPanTranslation.x + translation.x
				currentPanTranslation.y = initialPanTranslation.y + translation.y
				updatePan()

			case .Changed, .Ended:
				currentPanTranslation.x = initialPanTranslation.x + translation.x
				currentPanTranslation.y = initialPanTranslation.y + translation.y
				updatePan()

			case .Possible:
				break;

			case .Cancelled,.Failed:
				break;
			}
		}
	}

	private func updatePan() {
		if let drawingView = drawingView {
			let size = drawingView.controller!.viewport.size
			drawingView.frame = CGRect(x: currentPanTranslation.x, y: currentPanTranslation.y, width: size.width, height: size.height)
			drawingView.layer.transform = CATransform3DIdentity
		}
	}

	private dynamic func onTogglePanning(tgr:UITapGestureRecognizer) {
		panning = !panning
	}
}

class DrawingView : UIView {

	private var drawing:Drawing?
	private var controller:DrawingInputController?
	private var tracking:Bool = false

	override init(frame:CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		commonInit()
	}

	private func commonInit() {
		backgroundColor = UIColor(red: 0.7, green: 1, blue: 1, alpha: 1)
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

	private var drawingView = DrawingView(frame: CGRect.zeroRect)
	private var drawingViewContainer = ScalingDrawingContainer(frame: CGRect.zeroRect)

	override func viewDidLoad() {
		title = "Drawing Tests..."
		view.backgroundColor = SquizitTheme.leatherBackgroundColor()

		let drawingFrame = CGRect(x: 0, y: 0, width: 1024, height: 512)
		drawingView.drawing = Drawing()
		drawingView.drawing!.debugRender = true
		drawingView.frame = drawingFrame

		view.addSubview(drawingViewContainer)
		drawingViewContainer.drawingView = drawingView

		let controller = DrawingInputController()
		controller.drawing = drawingView.drawing!
		controller.view = drawingView
		controller.viewport = drawingFrame
		controller.fill = Fill.Brush
		drawingView.controller = controller

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "DEBUG", style: UIBarButtonItemStyle.Plain, target: self, action: "onToggleDebugRendering:")
		self.navigationItem.leftBarButtonItems = [
			UIBarButtonItem(title: "UNDO", style: UIBarButtonItemStyle.Plain, target: self, action: "onUndo:"),
			UIBarButtonItem(title: "CLEAR", style: UIBarButtonItemStyle.Plain, target: self, action: "onClear:"),
		]

	}

	override func viewWillLayoutSubviews() {
		drawingViewContainer.frame = CGRect(x: 0, y: topLayoutGuide.length, width: view.bounds.width, height: view.bounds.height - (topLayoutGuide.length+bottomLayoutGuide.length))
	}

	// MARK: - Actions

	dynamic private func onUndo( sender:AnyObject ) {
		drawingView.controller!.undo()
	}

	dynamic private func onClear( sender:AnyObject ) {
		drawingView.drawing!.clear()
		drawingView.setNeedsDisplay()
	}

	dynamic private func onToggleDebugRendering( sender:AnyObject ) {
		drawingView.drawing!.debugRender = !drawingView.drawing!.debugRender
		drawingView.setNeedsDisplay()
	}

}