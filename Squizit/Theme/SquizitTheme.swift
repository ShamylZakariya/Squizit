//
//  Themes.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/21/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit


class SquizitTheme {

	init() {

		//
		//	UINavbar
		//

		UINavigationBar.appearance().barStyle = UIBarStyle.Black
		UINavigationBar.appearance().translucent = true
		UINavigationBar.appearance().titleTextAttributes = [
			NSFontAttributeName: UIFont(name: "Baskerville-Bold", size: 21) as! AnyObject,
			NSForegroundColorAttributeName: UIColor.whiteColor() as AnyObject
		]

		//
		//	UIBarButtonItem
		//

		UIBarButtonItem.appearance().setTitleTextAttributes([
			NSFontAttributeName: UIFont(name: "Baskerville", size: 18) as! AnyObject
		], forState: UIControlState.Normal)

		//
		//	Swift doesn't support appearanceWhenContainedIn... so we need to bridge to ObjC
		//

		SquizitTheme_ConfigureAppearanceProxies()
	}

	class func leatherBackgroundImage() -> UIImage {
		return UIImage(named: "leather-pattern")!
	}

	class func paperBackgroundImage( scale:CGFloat = 0 ) -> UIImage {
		let paperImageName = "paper-pattern"
		if scale == 0 {
			return UIImage(named: paperImageName)!
		}

		let tc = UITraitCollection(displayScale: scale)
		return UIImage(named: paperImageName, inBundle: nil, compatibleWithTraitCollection: tc)!
	}

	class func thumbnailPaperBackgroundImage() -> UIImage {
		return UIImage(named: "thumbnail-paper-pattern")!
	}

	class func rootScreenBackgroundImage() -> UIImage {
		return UIImage(named: "universal-cube-pattern")!
	}

	// background color of paper surface (e.g., background of drawing canvas)
	class func paperBackgroundColor( scale:CGFloat = 0 ) -> UIColor {
		return UIColor( patternImage: self.paperBackgroundImage( scale: scale ) )
	}

	// background color for when a match is exported
	class func exportedMatchBackgroundColor() -> UIColor {
		return UIColor.whiteColor()
	}

	class func exportWatermarkImage() -> UIImage {
		return UIImage(named:"export-watermark")!
	}

	class func leatherBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	// background color for the match view
	class func matchBackgroundColor() -> UIColor {
		return UIColor( white: 0.2, alpha: 1)
	}

	class func matchButtonBackgroundColor() -> UIColor {
		return matchBackgroundColor().colorWithAlphaComponent(0.3)
	}

	// background color for the shields displayed during matches
	class func matchShieldBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	// background color for the match view
	class func howToPlayBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	// background color for gallery collection view
	class func galleryBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	// background color for gallery drawing thumbnails
	class func thumbnailBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.thumbnailPaperBackgroundImage() )
	}

	class func tintColor() -> UIColor {
		return UIColor.whiteColor()
	}

	class func alertTintColor() -> UIColor {
		return dialogBackgroundColor()
	}

	class func dialogBackgroundColor() -> UIColor {
		return UIColor(white: 0.137, alpha: 1)
	}

}

class SquizitThemeButton : UIButton {

	var bordered:Bool = true {
		didSet {
			update()
		}
	}

	// if a button is destructive, its label text will be a reddish/fuscia-ish color - otherwise it will be the current tintColor
	var destructive:Bool = false {
		didSet {
			self.tintColor = destructive ? UIColor(red: 1, green: 0.27, blue: 0.47, alpha: 1) : nil
		}
	}

	override func setTitle(title: String!, forState state: UIControlState) {
		super.setTitle(title.uppercaseString, forState: state)
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		update()
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		update()
	}

	override var enabled:Bool {
		didSet {
			UIView.animateWithDuration(0.3, animations: { [unowned self] in
				self.layer.opacity = self.enabled ? 1 : 0.3
			})
		}
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		update()
	}

	private func update() {
		titleLabel!.font = UIFont(name: "Avenir-Light", size: UIFont.buttonFontSize())
		layer.cornerRadius = 0

		if bordered {
			layer.borderWidth = 1
			layer.backgroundColor = UIColor(white: 0.19, alpha: 0.2).CGColor
			layer.borderColor = self.tintColor!.colorWithAlphaComponent(0.2).CGColor
		} else {
			layer.borderWidth = 0
		}
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: super.intrinsicContentSize().width + 44, height: 44)
	}
}

class SquizitGameTextButton : UIButton {

	class func create(title:String) ->SquizitGameTextButton {
		var button = SquizitGameTextButton.buttonWithType(.Custom) as! SquizitGameTextButton
		button.setTitle(title, forState: .Normal)
		return button
	}

	override func setTitle(title: String!, forState state: UIControlState) {
		super.setTitle(title.uppercaseString, forState: state)
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		update()
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		update()
	}

	override var enabled:Bool {
		didSet {
			UIView.animateWithDuration(0.3, animations: { [unowned self] in
				self.layer.opacity = self.enabled ? 1 : 0.3
				})
		}
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		update()
	}

	private func update() {
		titleLabel!.font = UIFont(name: "Avenir-Light", size: UIFont.buttonFontSize())
		layer.cornerRadius = 0
		backgroundColor = SquizitTheme.matchButtonBackgroundColor()
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: super.intrinsicContentSize().width + 22, height: 44)
	}
}

class SquizitThemeNameInputField : UITextField {

	@IBOutlet var nextField:SquizitThemeNameInputField?

	override func drawRect(rect: CGRect) {
		super.drawRect(rect)

		let bounds = self.bounds
		self.tintColor.colorWithAlphaComponent(0.2).set()
		UIBezierPath(rect: CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)).fill()
	}

	override func awakeFromNib() {
		applyTheme()
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		applyTheme()
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: UIViewNoIntrinsicMetric, height: 29)
	}

	override var placeholder:String? {
		didSet {
			applyTheme()
		}
	}

	private func applyTheme() {
		self.layer.cornerRadius = 0
		background = nil
		backgroundColor = UIColor.clearColor()
		opaque = false
		borderStyle = UITextBorderStyle.None
		textColor = tintColor
		font = UIFont(name: "Baskerville-Italic", size: UIFont.labelFontSize() )
		textAlignment = NSTextAlignment.Center

		attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [
			NSForegroundColorAttributeName: tintColor.colorWithAlphaComponent(0.5)
		])
	}
}

class SquizitThemeSearchField : UITextField {

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		commonInit()
	}

	override init(frame: CGRect) {
		super.init( frame: frame )
		commonInit()
	}

	private func commonInit() {

		var clearButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
		var closeImage = UIImage(named: "gallery-clear-search-button")!.imageWithRenderingMode(.AlwaysTemplate)
		clearButton.setImage(closeImage, forState: .Normal)
		clearButton.frame = CGRect(x: 0, y: 0, width: closeImage.size.width, height: closeImage.size.height)
		clearButton.addTarget(self, action: "clearButtonTapped:", forControlEvents: .TouchUpInside)

		rightView = clearButton
		rightViewMode = .WhileEditing
	}

	var fontSize:CGFloat = 24 {
		didSet {
			applyTheme()
		}
	}

	override func awakeFromNib() {
		applyTheme()
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		applyTheme()
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: UIViewNoIntrinsicMetric, height: fontSize * 2)
	}

	override var placeholder:String? {
		didSet {
			applyTheme()
		}
	}

	private func applyTheme() {
		self.layer.cornerRadius = 0
		background = nil
		backgroundColor = UIColor.clearColor()
		opaque = false
		borderStyle = UITextBorderStyle.None
		textColor = tintColor
		font = UIFont(name: "Baskerville-Italic", size: fontSize )
		textAlignment = NSTextAlignment.Center

		attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [
			NSForegroundColorAttributeName: tintColor.colorWithAlphaComponent(0.5)
		])
	}

	private dynamic func clearButtonTapped( sender:AnyObject ) {

		if let shouldClear = self.delegate?.textFieldShouldClear?(self) {
			if shouldClear {
				var didSet = false
				if let shouldChange = self.delegate?.textField?(self, shouldChangeCharactersInRange: NSRangeFromString( self.text ), replacementString: "") {
					if shouldChange {
						self.text = ""
						didSet = true
					}
				} else {
					self.text = ""
					didSet = true
				}

				if didSet {
					self.sendActionsForControlEvents(UIControlEvents.EditingChanged)
				}
			}
		}
	}
}

class SquizitThemeLabel : UIView {

	private var _label:UILabel!

	var label:UILabel {
		return _label
	}

	var margins:(CGFloat,CGFloat) = (60,10)

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		commonInit()
	}

	override init(frame: CGRect) {
		super.init( frame: frame )
		commonInit()
	}

	override func layoutSubviews() {
		let bounds = self.bounds
		let labelBounds = CGRect(x:0,y:0,width:bounds.width - 2*margins.0, height:CGFloat.max)
		_label.preferredMaxLayoutWidth = labelBounds.width

		let rect = _label.textRectForBounds(labelBounds, limitedToNumberOfLines: 0)
		_label.frame = CGRect(center: CGPoint(x:bounds.midX, y: bounds.midY), size: rect.size )

		self.layoutIfNeeded()
	}

	override func drawRect(rect: CGRect) {

		let textRect = _label.frame
		let midY = round(bounds.midY) + 0.5

		var stroke = UIBezierPath()
		stroke.moveToPoint(CGPoint(x:0, y:midY))
		stroke.addLineToPoint(CGPoint(x:margins.0, y:midY))

		stroke.moveToPoint(CGPoint(x:bounds.maxX - margins.0, y:midY))
		stroke.addLineToPoint(CGPoint(x:bounds.maxX, y:midY))

		_label.textColor.colorWithAlphaComponent(0.5).set()
		stroke.lineWidth = 1
		stroke.stroke()
	}

	override func intrinsicContentSize() -> CGSize {
		self.layoutIfNeeded()
		let rect = _label.textRectForBounds(_label.bounds, limitedToNumberOfLines: 0)
		return CGSize(width:UIViewNoIntrinsicMetric, height: rect.height + 2*margins.1)
	}

	private func commonInit() {
		opaque = false
		backgroundColor = UIColor.clearColor()

		_label = UILabel(frame: CGRect.zeroRect)
		_label.numberOfLines = 0
		_label.lineBreakMode = .ByWordWrapping
		_label.textColor = UIColor.whiteColor()
		addSubview(_label)
	}

}