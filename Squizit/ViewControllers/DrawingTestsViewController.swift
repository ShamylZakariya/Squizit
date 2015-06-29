//
//  DrawingTestsViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/8/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit


class ScalingDrawingContainerView : UIView {

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

	private func commonInit() {}

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

	var quitGameButton:GameControlButton!
	var finishTurnButton:GameControlButton!
	var drawingToolSelector:DrawingToolSelector!
	var undoButton:SquizitGameTextButton!
	var clearButton:SquizitGameTextButton!
	var drawingContainerView:ScalingDrawingContainerView!
	var drawingView:DrawingView!

	override func viewDidLoad() {
		title = "Drawing Tests..."
		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		quitGameButton = GameControlButton.quitGameButton()
		finishTurnButton = GameControlButton.finishTurnButton()

		drawingToolSelector = DrawingToolSelector(frame: CGRect.zeroRect)
		drawingToolSelector.addTool("Pencil", icon: UIImage(named: "tool-pencil")!)
		drawingToolSelector.addTool("Brush", icon: UIImage(named: "tool-brush")!)
		drawingToolSelector.addTool("Eraser", icon: UIImage(named: "tool-eraser")!)
		drawingToolSelector.addTarget(self, action: "onDrawingToolSelected:", forControlEvents: .ValueChanged)

		undoButton = SquizitGameTextButton.create("Undo")
		undoButton.addTarget(self, action: "onUndo:", forControlEvents: .TouchUpInside)

		clearButton = SquizitGameTextButton.create("Clear")
		clearButton.addTarget(self, action: "onClear:", forControlEvents: .TouchUpInside)

		drawingContainerView = ScalingDrawingContainerView(frame: CGRect.zeroRect)

		drawingView = DrawingView(frame: CGRect.zeroRect)
		drawingView.drawing = Drawing()
		drawingContainerView.drawingView = drawingView



		view.addSubview(drawingContainerView)
		view.addSubview(clearButton)
		view.addSubview(undoButton)
		view.addSubview(drawingToolSelector)
		view.addSubview(finishTurnButton)
		view.addSubview(quitGameButton)


		let controller = DrawingInputController()
		controller.drawing = drawingView.drawing!
		controller.view = drawingView
		controller.viewport = CGRect(x: 0, y: 0, width: 1024, height: 512)
		controller.fill = Fill.Brush
		drawingView.controller = controller


		drawingToolSelector.selectedToolIndex = 0
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		setNeedsStatusBarAppearanceUpdate()
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		println("traitCollectionDidChange previous: \(previousTraitCollection) new:\(traitCollection)")
	}

	override func viewWillLayoutSubviews() {

		// generally, the drawingContainerView will fill the available space.
		// quit is on top left, finish-turn on top right, undo and clear in top-middle
		// and the tool picker in center bottom.
		// but in tight scenarios, like a phone in landscape, the drawingContainer will
		// leave 44dp at top for all controls, which will be positioned across the top

		let layoutRect = CGRect(x: 0, y: topLayoutGuide.length, width: view.bounds.width, height: view.bounds.height - (topLayoutGuide.length+bottomLayoutGuide.length))
		let naturalDrawingSize = drawingContainerView.drawingSize
		let (scaledDrawingSize,scaledDrawingScale) = drawingContainerView.fittedDrawingSize(layoutRect.size)
		let drawingToolSize = drawingToolSelector.intrinsicContentSize()
		let buttonSize = quitGameButton.intrinsicContentSize().height
		let margin = CGFloat(traitCollection.horizontalSizeClass == .Compact ? 8 : 36)

		var textButtonWidth = max(undoButton.intrinsicContentSize().width,clearButton.intrinsicContentSize().width)


		if (scaledDrawingSize.height + 2*drawingToolSize.height) < layoutRect.height {
			// we can perform normal layout
			drawingContainerView.frame = view.bounds
			quitGameButton.frame = CGRect(x: margin, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			finishTurnButton.frame = CGRect(x: layoutRect.maxX - margin - buttonSize, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)

			var textButtonTotalWidth = 2*textButtonWidth + margin
			undoButton.frame = CGRect(x: layoutRect.midX - textButtonWidth - margin/2, y: layoutRect.minY + margin, width: textButtonWidth, height: buttonSize)
			clearButton.frame = CGRect(x: layoutRect.midX + margin/2, y: layoutRect.minY + margin, width: textButtonWidth, height: buttonSize)

			drawingToolSelector.frame = CGRect(x: round(layoutRect.midX - drawingToolSize.width/2), y: round(layoutRect.maxY - drawingToolSize.height - margin), width: drawingToolSize.width, height: drawingToolSize.height)
		} else {
			// compact layout needed
			let toolsHeight = max(drawingToolSize.height,buttonSize)
			let toolBarRect = CGRect(x: margin, y: layoutRect.minY + margin, width: layoutRect.width-(2*margin), height: toolsHeight)

			drawingContainerView.frame = CGRect(x: layoutRect.minX, y: toolBarRect.maxY + margin, width: layoutRect.width, height: (layoutRect.maxY - toolBarRect.maxY) - 2*margin)
			quitGameButton.frame = CGRect(x: margin, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			finishTurnButton.frame = CGRect(x: layoutRect.maxX - margin - buttonSize, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			drawingToolSelector.frame = CGRect(x: round(layoutRect.midX - drawingToolSize.width/2), y: margin, width: drawingToolSize.width, height: drawingToolSize.height)

			// undo button goes between quit button right edge and the drawingToolSelector left edge
			undoButton.frame = CGRect(x: round((quitGameButton.frame.maxX + drawingToolSelector.frame.minX)/2 - textButtonWidth/2),
				y: margin, width: textButtonWidth, height: buttonSize)

			clearButton.frame = CGRect(x: round((drawingToolSelector.frame.maxX + finishTurnButton.frame.minX)/2 - textButtonWidth/2),
				y: margin, width: textButtonWidth, height: buttonSize)
		}
	}

	// MARK: - Actions

	dynamic private func onDrawingToolSelected( sender:DrawingToolSelector ) {
		if let idx = sender.selectedToolIndex {
			var fill = Fill.Pencil
			switch idx {
			case 0: fill = Fill.Pencil
			case 1: fill = Fill.Brush
			case 2: fill = Fill.Eraser
			default: break;
			}

			drawingView.controller!.fill = fill
		}
	}

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