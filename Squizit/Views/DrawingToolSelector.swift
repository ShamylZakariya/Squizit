//
//  DrawingToolSelector.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/20/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class InactiveTileBackgroundView : UIView {

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.opaque = false
	}

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		self.opaque = false
	}

	override func tintColorDidChange() {
		setNeedsDisplay()
	}

	override func drawRect(rect: CGRect) {
		tintColor.colorWithAlphaComponent(0.5).set()
		let border = UIBezierPath(ovalInRect: self.bounds.rectByInsetting(dx: 1, dy: 1).rectByOffsetting(dx: 0.5, dy: 0.5))
		border.lineWidth = 1
		border.setLineDash([3,3], count: 2, phase: 0)
		border.stroke()
	}

}

/**
	Emits UIControlEvents.ValueChanged when selectedToolIndex changes
*/
class DrawingToolSelector : UIControl {

	enum Orientation {
		case Vertical
		case Horizontal
	}

	private var _tiles:[UIView] = []
	private var _inactiveTileBackgrounds:[InactiveTileBackgroundView] = []
	private var _highlighter:UIView!

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	var margin:CGFloat = 40 {
		didSet {
			setNeedsLayout()
		}
	}

	var buttonSize:CGFloat = 88 {
		didSet {
			setNeedsLayout()
		}
	}

	var orientation:Orientation = .Vertical {
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

		var bg = InactiveTileBackgroundView(frame: CGRectZero)
		bg.userInteractionEnabled = false
		addSubview(bg)
		_inactiveTileBackgrounds.append(bg)

		var tile = UIImageView(frame: CGRectZero)
		tile.image = icon.imageWithRenderingMode(.AlwaysTemplate)
		tile.userInteractionEnabled = true
		tile.multipleTouchEnabled = false
		tile.contentMode = UIViewContentMode.Center

		var tgr = UITapGestureRecognizer(target: self, action: "tileTapped:")
		tgr.numberOfTapsRequired = 1
		tile.addGestureRecognizer(tgr)

		addSubview(tile)
		_tiles.append(tile)

		setNeedsLayout()
	}

	// MARK: UIView/Control Overrides

	override func layoutSubviews() {
		if _tiles.isEmpty {
			return
		}

		switch orientation {
			case .Vertical:
				layoutVertical()

			case .Horizontal:
				layoutHorizontal()
		}

		UIView.performWithoutAnimation { () -> Void in
			self.updateHighlightState()
		}
	}

	override func tintColorDidChange() {
		_highlighter.layer.backgroundColor = tintColor.CGColor
	}

	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		for tile in _tiles {
			if tile.frame.contains(point) {
				return true
			}
		}

		return false
	}

	// MARK: Private

	func layoutVertical() {
		let size = buttonSize
		let height = self.bounds.height
		let contentHeight = CGFloat(_tiles.count) * size + (CGFloat(_tiles.count) - 1.0) * margin;
		var x = bounds.width / 2 - size/2
		var y = height/2 - contentHeight/2

		for (i,tile) in enumerate(_tiles) {
			tile.frame = CGRect(x: x, y: y, width: size, height: size).integerRect
			_inactiveTileBackgrounds[i].frame = tile.frame
			y += margin + size
		}
	}

	func layoutHorizontal() {
		let size = buttonSize
		let width = self.bounds.width
		let contentWidth = CGFloat(_tiles.count) * size + (CGFloat(_tiles.count) - 1.0) * margin;
		var x = width/2 - contentWidth/2
		var y = bounds.height/2 - size/2

		for (i,tile) in enumerate(_tiles) {
			tile.frame = CGRect(x: x, y: y, width: size, height: size).integerRect
			_inactiveTileBackgrounds[i].frame = tile.frame
			x += margin + size
		}
	}

	func updateHighlightState() {
		if let idx = selectedToolIndex {
			_highlighter.frame = _tiles[idx].frame
			_highlighter.alpha = 1
			_highlighter.layer.cornerRadius = min( _highlighter.frame.width, _highlighter.frame.height ) / 2

			for ( i,bg ) in enumerate(_inactiveTileBackgrounds) {
				bg.alpha = i==idx ? 0 : 1
			}

		} else {
			_highlighter.alpha = 0
			for bg in _inactiveTileBackgrounds {
				bg.alpha = 1
			}
		}
	}

	func tileTapped( tgr:UITapGestureRecognizer ) {

		for (i,tile) in enumerate(_tiles) {
			if tile == tgr.view {
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
			for (i,tile) in enumerate(_tiles) {
				if i == idx {
					tile.tintColor = UIColor.blackColor()
				} else {
					tile.tintColor = nil
				}
			}
		} else {
			for tile in _tiles {
				tile.tintColor = nil
			}
		}

		sendActionsForControlEvents( UIControlEvents.ValueChanged )
	}

	private func commonInit() {
		_highlighter = UIView(frame: CGRectZero)
		_highlighter.opaque = false
		_highlighter.alpha = 1
		addSubview(_highlighter)
	}

}