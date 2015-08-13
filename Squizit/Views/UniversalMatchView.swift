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

	private var panning:Bool = false {
		didSet {
			// reset position to be centered in view
			currentPanTranslation = CGPoint(x: bounds.width/2 - drawingSize.width/2, y: bounds.height/2 - drawingSize.height/2)
			updateLayout()
		}
	}

	var drawingSize:CGSize {
		if let drawingView = drawingView {
			return drawingView.controller!.viewport.size
		} else {
			return CGSize.zeroSize
		}
	}

	func fittedDrawingSize(availableSize:CGSize) -> (size:CGSize,scale:CGFloat) {
		if let drawingView = drawingView, controller = drawingView.controller {

			let naturalSize = controller.viewport.size
			var scaledSize = naturalSize
			var scale = CGFloat(1)

			if naturalSize.width > availableSize.width {
				scale = availableSize.width / scaledSize.width
				scaledSize.width = naturalSize.width * scale
				scaledSize.height = naturalSize.height * scale
			}

			if naturalSize.height > availableSize.height {
				scale *= availableSize.height / scaledSize.height
				scaledSize.width = naturalSize.width * scale
				scaledSize.height = naturalSize.height * scale
			}

			return (size:scaledSize,scale:scale)
		}

		return (size:CGSize.zeroSize,scale:0)
	}

	var drawingView:UniversalMatchView? {
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
		tgr.numberOfTouchesRequired = 1
		tgr.numberOfTapsRequired = 2
		addGestureRecognizer(tgr)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		updateLayout()
	}

	private dynamic func onPan(pgr:UIPanGestureRecognizer) {
		if let drawingView = drawingView where panning {
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
		if let drawingView = drawingView {
			if !panning {

				let naturalSize = drawingSize

				// compute max scale to fit drawingView in view
				let scaling = fittedDrawingSize(bounds.size)

				// centering offset
				let offset = CGPoint(x: (bounds.width-scaling.size.width)/2, y: (bounds.height-scaling.size.height)/2).integerPoint()

				// set
				drawingView.frame = CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height)
				drawingView.layer.transform = CATransform3DConcat(CATransform3DMakeScale(scaling.scale, scaling.scale, 1), CATransform3DMakeTranslation(offset.x, offset.y, 1))
			} else {
				updatePan()
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

		// no animation happens because self.panning performs layout by calling setNeedsLayout
		UIView.animateWithDuration(0.2) {
			self.panning = !self.panning
		}
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

	var showDirtyRectUpdates:Bool = true {
		didSet {
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
				controller.draw(ctx)
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
