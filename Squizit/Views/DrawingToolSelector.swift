//
//  DrawingToolSelector.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/20/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class ToolIconView : UIView {

	var imageView:UIImageView!
	var active:Bool = false {
		didSet {
			imageView.alpha = active ? 1.0 : 0.5
			setNeedsDisplay()
		}
	}

	init(frame: CGRect, icon:UIImage) {
		super.init(frame: frame)
		self.opaque = false
		imageView = UIImageView(image: icon.imageWithRenderingMode(.AlwaysTemplate))
		imageView.contentMode = UIViewContentMode.ScaleAspectFit
		addSubview(imageView)
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	override func tintColorDidChange() {
		setNeedsDisplay()
	}

	override func layoutSubviews() {
		imageView.frame = self.bounds
	}

	override func drawRect(rect: CGRect) {
		if !active {
			let backdrop = UIBezierPath(ovalInRect: self.bounds.rectByInsetting(dx: 1, dy: 1).rectByOffsetting(dx: 0.5, dy: 0.5))
			tintColor.colorWithAlphaComponent(0.5).set()
			backdrop.lineWidth = 1
			backdrop.stroke()
		}
	}
}

/**
	Emits UIControlEvents.ValueChanged when selectedToolIndex changes
*/
class DrawingToolSelector : UIControl {

	private var _tools:[ToolIconView] = []
	private var _highlighter:UIView!

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	override var enabled:Bool {
		didSet {
			UIView.animateWithDuration(0.3, animations: { [unowned self] in
				self.layer.opacity = self.enabled ? 1 : 0.3
				})
		}
	}

	var toolSeparation:CGFloat = 20 {
		didSet {
			setNeedsLayout()
		}
	}

	var toolSize:CGFloat = 45 {
		didSet {
			setNeedsLayout()
		}
	}

	var selectedToolIndex:Int? {
		didSet {
			selectedToolIndexDidChange()
		}
	}

	func addTool( name:String, icon:UIImage ) {

		var tool = ToolIconView(frame: CGRectZero, icon: icon)
		tool.userInteractionEnabled = true
		tool.multipleTouchEnabled = false
		addSubview(tool)
		_tools.append(tool)

		var tgr = UITapGestureRecognizer(target: self, action: "toolWasTapped:")
		tgr.numberOfTapsRequired = 1
		tool.addGestureRecognizer(tgr)

		setNeedsLayout()
	}

	// MARK: UIView/Control Overrides

	override func layoutSubviews() {
		if _tools.isEmpty {
			return
		}

		layoutTools()

		UIView.performWithoutAnimation { () -> Void in
			self.updateHighlightState()
		}
	}

	override func tintColorDidChange() {
		_highlighter.layer.backgroundColor = tintColor.CGColor
	}

	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		if enabled {
			for tool in _tools {
				if tool.frame.contains(point) {
					return true
				}
			}
		}

		return false
	}

	override func intrinsicContentSize() -> CGSize {
		let toolsWidth = CGFloat(_tools.count) * toolSize
		let toolsSeparation = CGFloat(_tools.count-1) * toolSeparation
		return CGSize(width: toolsWidth + toolsSeparation, height: toolSize)
	}

	// MARK: Private

	func layoutTools() {
		let width = self.bounds.width
		let maxButtonSize:CGFloat = (width - ((CGFloat(_tools.count)-1)*toolSeparation)) / CGFloat(_tools.count)
		let size = round(min( min(bounds.height,toolSize), maxButtonSize ))
		let contentWidth = CGFloat(_tools.count) * size + (CGFloat(_tools.count) - 1.0) * toolSeparation;
		var x = width/2 - contentWidth/2
		var y = bounds.height/2 - size/2

		for tool in _tools {
			let frame = CGRect(x: round(x), y: round(y), width: size, height: size)
			tool.frame = frame
			x += toolSeparation + size
		}
	}

	func updateHighlightState() {
		if let idx = selectedToolIndex {
			_highlighter.frame = _tools[idx].frame
			_highlighter.alpha = 1
			_highlighter.layer.cornerRadius = min( _highlighter.frame.width, _highlighter.frame.height ) / 2

			for ( i,tool ) in enumerate(_tools) {
				tool.active = i==idx
			}

		} else {
			_highlighter.alpha = 0
			for tool in _tools {
				tool.active = false
			}
		}
	}

	func toolWasTapped( tgr:UITapGestureRecognizer ) {

		if !enabled {
			return
		}

		for (i,tool) in enumerate(_tools) {
			if tool == tgr.view {
				selectedToolIndex = i
				return
			}
		}

		// this shouldn't happen...
		selectedToolIndex = nil
	}

	func selectedToolIndexDidChange() {

		let duration:NSTimeInterval = 0.5
		let delay:NSTimeInterval = 0
		let damping:CGFloat = 0.7
		let initialSpringVelocity:CGFloat = 0
		let options:UIViewAnimationOptions = UIViewAnimationOptions(0)

		UIView.animateWithDuration(duration,
			delay: delay,
			usingSpringWithDamping: damping,
			initialSpringVelocity: initialSpringVelocity,
			options: options,
			animations: { [unowned self] () -> Void in
				self.updateHighlightState()
			},
			completion: nil)

		if let idx = selectedToolIndex {
			for (i,tool) in enumerate(_tools) {
				if i == idx {
					tool.tintColor = UIColor.blackColor()
				} else {
					tool.tintColor = nil
				}
			}
		} else {
			for tool in _tools {
				tool.tintColor = nil
			}
		}

		sendActionsForControlEvents( UIControlEvents.ValueChanged )
	}

	private func commonInit() {
		_highlighter = UIView(frame: CGRectZero)
		_highlighter.opaque = false
		_highlighter.alpha = 1
		_highlighter.layer.shadowColor = UIColor.blackColor().CGColor
		_highlighter.layer.shadowOffset = CGSize(width: 0, height: 1)
		_highlighter.layer.shadowOpacity = 0.25
		_highlighter.layer.shadowRadius = 2
		addSubview(_highlighter)
	}

}