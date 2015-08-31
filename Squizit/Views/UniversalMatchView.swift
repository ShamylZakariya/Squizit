//
//  DrawingView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 7/16/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class UniversalMatchViewPresenterView : UIView {

	private var currentPanTranslation = CGPoint.zeroPoint
	private var initialPanTranslation = CGPoint.zeroPoint

	/**
		Set the insets for the presented match view. 
	The match view will be maximally scaled and centered in the implicit rect made from this view's layout adjusted by edge insets
	*/
	var insets:UIEdgeInsets = UIEdgeInsets(top:0,left:0,bottom:0,right:0) {
		didSet {
			setNeedsLayout()
			setNeedsDisplay()
		}
	}

	/**
		Get this view's bounds after applying the insets
	*/
	var insetBounds:CGRect {
		return CGRect(x: bounds.minX + insets.left, y: bounds.minY + insets.top, width: bounds.width - (insets.left+insets.right), height: bounds.height-(insets.top+insets.bottom))
	}


	var onPanningChanged:((panning:Bool)->())?

	/**
		When panning, upscale the drawing to this factor times the fittedDrawingSize.
		The idea being, that when the user wants to pan around the drawing, it should be big, for detail work.
	*/
	var panningScale:CGFloat = 2 {
		didSet {
			updateLayout()
		}
	}

	var panning:Bool = false {
		willSet {
			// if transitioning to panning mode, reset pan
			if !panning && newValue {
				resetPanTranslation()
			}
		}
		didSet {
			// reset position to be centered in view
			currentPanTranslation = CGPoint(x: bounds.width/2 - drawingSize.width/2, y: bounds.height/2 - drawingSize.height/2)
			updateLayout()
			updateDrawingViewLayer()
			onPanningChanged?(panning:self.panning)
		}
	}

	func setPanning(panning:Bool, animated:Bool) {
		if animated {
			UIView.animateWithDuration(0.2) {
				self.panning = panning
			}
		} else {
			self.panning = panning
		}
	}

	func resetPanTranslation() {
		currentPanTranslation = CGPoint.zeroPoint
		initialPanTranslation = CGPoint.zeroPoint
	}

	var drawingSize:CGSize {
		if let drawingView = matchView {
			return drawingView.controller!.viewport.size
		} else {
			return CGSize.zeroSize
		}
	}

	func fittedDrawingSize() -> (size:CGSize,scale:CGFloat) {
		if let drawingView = matchView, controller = drawingView.controller {

			let naturalSize = controller.viewport.size
			var scaledSize = naturalSize
			var scale = CGFloat(1)

			let availableSize = insetBounds.size
			if naturalSize.width > availableSize.width {
				scale = availableSize.width / scaledSize.width
				scaledSize.width = naturalSize.width * scale
				scaledSize.height = naturalSize.height * scale
			}

			if scaledSize.height > availableSize.height {
				scale *= availableSize.height / scaledSize.height
				scaledSize.width = naturalSize.width * scale
				scaledSize.height = naturalSize.height * scale
			}

			return (size:scaledSize,scale:scale)
		}

		return (size:CGSize.zeroSize,scale:0)
	}

	var matchView:UniversalMatchView? {
		didSet {
			if let drawingView = matchView {
				drawingView.layer.anchorPoint = CGPoint(x: 0, y: 0)
				drawingView.layer.shouldRasterize = true
				drawingView.layer.rasterizationScale = 1
				addSubview(drawingView)
				setNeedsLayout()

				drawingView.onRenderPipelineChanged = { [weak self] in
					self?.updateDrawingViewLayer()
				}
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
		tgr.numberOfTouchesRequired = 1
		tgr.numberOfTapsRequired = 2
		addGestureRecognizer(tgr)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		updateLayout()
	}

	// uncomment to render inset rect
	/*
	override func drawRect(rect: CGRect) {
		UIColor.redColor().colorWithAlphaComponent(0.25).set()
		UIRectFill(bounds)

		UIColor.greenColor().colorWithAlphaComponent(0.25).set()
		UIRectFill(insetBounds)

		UIColor.greenColor().set()
		UIRectFrame(insetBounds)
	}
	*/

	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		// forward input events to allow user to start a stroke off-canvas
		matchView?.touchesBegan(touches, withEvent: event)
	}

	override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
		matchView?.touchesMoved(touches, withEvent: event)
	}

	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
		matchView?.touchesEnded(touches, withEvent: event)
	}

	override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
		matchView?.touchesCancelled(touches, withEvent: event)
	}

	private dynamic func onPan(pgr:UIPanGestureRecognizer) {
		if let drawingView = matchView where panning {
			var translation = pgr.translationInView(self)
			translation.x = round(translation.x)
			translation.y = round(translation.y)

			switch pgr.state {
			case .Began:
				// kill stroke that was started
				drawingView.controller!.undo()

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

	private func updateLayout() {
		if let drawingView = matchView {

			let nativeDrawingSize = drawingSize
			drawingView.layer.transform = CATransform3DIdentity
			drawingView.frame = CGRect(x: 0, y: 0, width: nativeDrawingSize.width, height: nativeDrawingSize.height)

			if panning {

				updatePan()

			} else {
				// compute max scale to fit drawingView in view, and centering offset
				let scaling = fittedDrawingSize()
				let insetBounds = self.insetBounds
				let offset = CGPoint(x: insetBounds.midX - (scaling.size.width/2), y: insetBounds.midY - (scaling.size.height/2)).integerPoint()

				drawingView.layer.transform = CATransform3DConcat(CATransform3DMakeScale(scaling.scale, scaling.scale, 1), CATransform3DMakeTranslation(offset.x, offset.y, 1))
			}
		}
	}

	private func updatePan() {
		if let drawingView = matchView {

			let scaledDrawingSize = drawingSize.scale(panningScale)
			let insetBounds = self.insetBounds
			let offset = CGPoint(x: insetBounds.midX - (scaledDrawingSize.width/2), y: insetBounds.midY - (scaledDrawingSize.height/2)).integerPoint()

			drawingView.layer.transform = CATransform3DConcat(
				CATransform3DMakeScale(panningScale, panningScale, CGFloat(1)),
				CATransform3DMakeTranslation(offset.x + currentPanTranslation.x, offset.y + currentPanTranslation.y, 0)
			)
		}
	}

	private func updateDrawingViewLayer() {
		if let drawingView = matchView {
			drawingView.layer.shouldRasterize = true
			drawingView.layer.rasterizationScale = self.panning ? panningScale : 1
		}
	}

	private dynamic func onTogglePanning(tgr:UITapGestureRecognizer) {
		setPanning(!panning, animated: true)
	}
}

/**
	Displays a Match object and forwards user input to the current drawing object to draw lines, etc.
	Given that a match has a number of players, and a currently active player, the UniversalMatchView
	renders a zig-zag pattern at the top, bottom or both top and bottom of the drawing to indicate
	the current player's index.

	UniversalMatchView is meant to be contained in UniversalMatchViewPresenterView, which handles scaling and panning.
*/
class UniversalMatchView : UIView {

	struct Notifications {
		static let DrawingDidChange = "DrawingDidChange"
		static let TurnDidChange = "TurnDidChange"
	}

	struct NotificationUserInfoKeys {
		static let DrawingDidChangeTurnUserInfoKey = "DrawingDidChangeTurnUserInfoKey"
		static let TurnDidChangeTurnUserInfoKey = "DrawingDidChangeTurnUserInfoKey"
	}

	var match:Match? {
		didSet {
			buildControllers()
			updateMaskLayer()
			setNeedsDisplay()
		}
	}

	private(set) var controllers:[DrawingInputController] = []

	/**
	Set the current turn in the match. Given a match with 3 players:
	- player 1 - turn 0 : zigzag on bottom
	- player 2 - turn 1 : zigzags on top and bottom
	- player 3 - turn 2 : zigzags on top
	*/
	var turn:Int = 0 {
		didSet {
			turn = min(max(turn,0),match!.players-1)
			updateMaskLayer()
			setNeedsDisplay()
			NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TurnDidChange, object: self, userInfo: [
				NotificationUserInfoKeys.TurnDidChangeTurnUserInfoKey: turn
			])
		}
	}

	var showDirtyRectUpdates:Bool = false {
		didSet {
			setNeedsDisplay()
		}
	}

	var onRenderPipelineChanged:(()->())?

	var useExperimentalResolutionIndependantRenderPipeline:Bool = false {
		didSet {
			onRenderPipelineChanged?()
			setNeedsDisplay()
		}
	}

	var drawingSurfaceBackgroundColor:UIColor = UIColor.whiteColor() {
		didSet {
			setNeedsDisplay()
		}
	}

	var drawing:Drawing? {
		return match?.drawings[turn]
	}

	var controller:DrawingInputController? {
		return controllers[turn]
	}

	private var maskLayer:CALayer?

	
	override init(frame:CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		commonInit()
	}

	private func commonInit() {}

	override func drawRect(rect: CGRect) {

		if let match = match {

			// clip to dirty rect and fill with drawing background color
			let ctx = UIGraphicsGetCurrentContext()
			CGContextClipToRect(ctx, rect)

			drawingSurfaceBackgroundColor.set()
			UIRectFill(rect)

			// set offset to position current match at 0,0
			CGContextSaveGState(ctx)
			let offset = match.viewports[turn].origin.y
			CGContextTranslateCTM(ctx, 0, -offset)

			// draw all drawings
			for controller in controllers {
				let viewport = controller.viewport.rectByOffsetting(dx: 0, dy: -offset)
				if viewport.intersects(rect) || rect.isEmpty || rect.isNull {
					if useExperimentalResolutionIndependantRenderPipeline {
						controller.drawUsingImmediatePipeline(rect, context: ctx)
					} else {
						controller.drawUsingBitmapPipeline(ctx)
					}
				}
			}

			CGContextRestoreGState(ctx)

			if showDirtyRectUpdates {
				UIColor.redColor().colorWithAlphaComponent(0.5).set()
				UIRectFrameUsingBlendMode(rect, kCGBlendModeNormal)
			}
		}
	}

	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		let offset = CGPoint(x:0, y:currentMatchOffset)
		controller?.touchesBegan(touches, withEvent: event)
		notifyDrawingDidChange()
	}

	override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
		let offset = CGPoint(x:0, y:currentMatchOffset)
		controller?.touchesMoved(touches, withEvent: event)
		notifyDrawingDidChange()
	}

	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
		controller?.touchesEnded(touches, withEvent: event)
		notifyDrawingDidChange()
	}

	override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
		controller?.touchesEnded(touches, withEvent: event)
		notifyDrawingDidChange()
	}

	// MARK: Private

	private func notifyDrawingDidChange() {
		NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DrawingDidChange, object: self, userInfo: [
			NotificationUserInfoKeys.DrawingDidChangeTurnUserInfoKey: turn
		])
	}

	private var currentMatchOffset:CGFloat {
		if let match = match {
			return match.viewports[turn].origin.y
		} else {
			return 0
		}
	}

	private func buildControllers(){
		var controllers:[DrawingInputController] = []

		if let match = match {
			for (i,drawing) in enumerate(match.drawings) {
				let controller = DrawingInputController()
				controller.drawing = drawing
				controller.view = self
				controller.viewport = match.viewports[i]
				controllers.append(controller)
			}
		}

		self.controllers = controllers
	}

	private func updateMaskLayer() {
		if let match = match, controller = controller {
			let viewport = controller.viewport
			if let maskLayer = maskLayer {
				maskLayer.removeFromSuperlayer()
				self.maskLayer = nil
			}

			let renderTopZigzags = turn > 0
			let renderBottomZigzags = turn < (match.players - 1)

			// compute a whole number of triangles roughly 8dp wide fitting in viewport,
			// and then set their height such that the triangles will be right-isosceles
			let triangleWidth = viewport.width / round( viewport.width / 16 )
			let triangleHeight = ceil((triangleWidth/2) / CGFloat(M_SQRT2))
			let triangleCount = Int(viewport.width / triangleWidth)

			if renderTopZigzags || renderBottomZigzags {

				var bezierPath = UIBezierPath(rect: CGRect(x: 0, y: triangleHeight, width: viewport.width, height: viewport.height - 2*triangleHeight))
				bezierPath.moveToPoint(CGPoint(x: 0, y: 0))

				// we will start with top left corner, and go clockwise around

				if renderTopZigzags {
					for i in 0 ..< triangleCount {
						bezierPath.addLineToPoint(CGPoint(x: CGFloat(i) * triangleWidth + triangleWidth/2, y: triangleHeight))
						bezierPath.addLineToPoint(CGPoint(x: CGFloat(i+1) * triangleWidth, y: 0))
					}
				} else {
					bezierPath.addLineToPoint(CGPoint(x: viewport.width, y: 0))
				}

				bezierPath.addLineToPoint(CGPoint(x: viewport.width, y: viewport.height))

				if renderBottomZigzags {

					for i in 0 ..< triangleCount {
						bezierPath.addLineToPoint(CGPoint(x: viewport.width - (CGFloat(i) * triangleWidth + triangleWidth/2), y: viewport.height - triangleHeight))
						bezierPath.addLineToPoint(CGPoint(x: viewport.width - (CGFloat(i+1) * triangleWidth), y: viewport.height))
					}

				} else {
					bezierPath.addLineToPoint(CGPoint(x: 0, y: viewport.height))
				}

				bezierPath.closePath()

				// create a shape layer using this path
				let shapeLayer = CAShapeLayer()
				shapeLayer.path = bezierPath.CGPath
				shapeLayer.fillColor = UIColor.redColor().CGColor
				
				layer.mask = shapeLayer
				maskLayer = shapeLayer
			}
		}
	}
}
