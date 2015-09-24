//
//  SaveToGalleryViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/26/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

protocol SaveToGalleryDelegate : class {

	// invoked when user dismisses the save dialog without saving
	func didDismissSaveToGallery()

	// invoked when user wants to save, passing array of names if user wanted to mark down player names, or nil otherwise
	func didSaveToGalleryWithNames( names:[String]? )

}

class SaveToGalleryViewController : UIViewController, UITextFieldDelegate {

	@IBOutlet weak var dialogView: UIView!
	@IBOutlet weak var playerOneNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var playerTwoNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var playerThreeNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var addToGalleryButton: SquizitThemeButton!
	@IBOutlet weak var discardButton: SquizitThemeButton!

	@IBOutlet weak var playerThreeNameInputFieldTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var playerThreeNameInputFieldHeightConstraints: NSLayoutConstraint!
	@IBOutlet weak var dialogWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var dialogVerticalCenteringConstraint: NSLayoutConstraint!

	weak var delegate:SaveToGalleryDelegate?

	// FIXME: SaveToGalleryTransitionManager doesn't actually work
	//private let _saveToGalleryTransitionManager = SaveToGalleryTransitionManager()

	var nameCount:Int = 3 {
		didSet {
			if nameCount < 2 || nameCount > 3 {
				assertionFailure("SaveToGalleryViewController.nameCount only supports 2 or 3 player names")
			}
		}
	}

	// MARK: UIViewController Overrides

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		//self.transitioningDelegate = _saveToGalleryTransitionManager
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()


		dialogView.opaque = false
		dialogView.backgroundColor = SquizitTheme.dialogBackgroundColor()

		addToGalleryButton.bordered = false
		discardButton.bordered = false
		discardButton.destructive = true

		playerOneNameInputField.delegate = self
		playerTwoNameInputField.delegate = self
		playerThreeNameInputField.delegate = self

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
	}

	private var _visible:Bool = false
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		_visible = true

		switch nameCount {
			case 2:
				playerOneNameInputField.nextField = playerTwoNameInputField
				playerTwoNameInputField.nextField = playerOneNameInputField
				playerThreeNameInputField.hidden = true
				playerThreeNameInputFieldHeightConstraints.constant = 0
				playerThreeNameInputFieldTopConstraint.constant = 0

			case 3:
				playerOneNameInputField.nextField = playerTwoNameInputField
				playerTwoNameInputField.nextField = playerThreeNameInputField
				playerThreeNameInputField.nextField = playerOneNameInputField
				playerThreeNameInputField.hidden = false

			default:
				break;
		}

		view.setNeedsUpdateConstraints()

		//
		// FIXME: When I make SaveToGalleryTransitionManager work, I can delete the faux transition animation
		//

		// pre-setup for faux transition animation
		dialogView.alpha = 0
		dialogView.transform = CGAffineTransformMakeScale(1.1, 1.1)

		UIView.animateWithDuration(0.3, delay: 0.25, options: .AllowUserInteraction, animations: {
			self.dialogView.alpha = 1
		}, completion: nil)

		UIView.animateWithDuration(0.6,
			delay: 0.25,
			usingSpringWithDamping: 0.4,
			initialSpringVelocity: 0.3,
			options: .AllowUserInteraction,
			animations: { [unowned self] in

				self.dialogView.transform = CGAffineTransformIdentity

			},
			completion: nil)
	}

	private var _didAddMotionEffect:Bool = false

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if !_didAddMotionEffect {
			_didAddMotionEffect = true
			addParallaxEffect()
		}
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	// MARK: IBActions

	@IBAction func addToGallery(sender: AnyObject) {

		// collect names
		var names:[String] = []
		var namesEnteredByUser = 0

		var fields:[UITextField] = []
		switch nameCount {
			case 2:	fields = [playerOneNameInputField,playerTwoNameInputField]
			case 3:	fields = [playerOneNameInputField,playerTwoNameInputField,playerThreeNameInputField]
			default: break;
		}

		for nameField in fields {
			var name = sanitize(nameField.text)
			if name.isEmpty {
				name = NSLocalizedString("Anonymous", comment: "AnonymousPlayerIdentifier")
			} else {
				namesEnteredByUser++
			}

			names.append( name )
		}

		delegate?.didSaveToGalleryWithNames( namesEnteredByUser > 0 ? names : nil )
	}

	@IBAction func discard(sender: AnyObject) {
		delegate?.didDismissSaveToGallery()
	}

	// MARK: Keyboard Handling

	dynamic private func keyboardWillShow( note:NSNotification ) {
		if let info:Dictionary = note.userInfo,
			keyboardRect = info[UIKeyboardFrameEndUserInfoKey]?.CGRectValue,
			duration = info[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval {
				dialogVerticalCenteringConstraint.constant = keyboardRect.height/2
				UIView.animateWithDuration(duration) {
					self.view.layoutIfNeeded()
				}
			}
	}

	dynamic private func keyboardWillHide( note:NSNotification ) {
		if let info:Dictionary = note.userInfo,
			duration = info[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval {
				dialogVerticalCenteringConstraint.constant = 0
				UIView.animateWithDuration(duration) {
					self.view.layoutIfNeeded()
				}
			}
	}

	// MARK: UITextFieldDelegate

	func textFieldShouldEndEditing(textField: UITextField) -> Bool {
		textField.text = sanitize(textField.text)
		return true
	}

	func textFieldShouldReturn(textField: UITextField) -> Bool {

		if let tf = textField as? SquizitThemeNameInputField {
			tf.nextField?.becomeFirstResponder()
		} else {
			textField.resignFirstResponder()
		}

		return true
	}

	// MARK: Private

	private func sanitize( name:String? ) -> String {
		guard let name = name else {
			return ""
		}
		return name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).capitalizedStringWithLocale(NSLocale.currentLocale())
	}

	private func addParallaxEffect() {
		let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
		horizontal.minimumRelativeValue = -15
		horizontal.maximumRelativeValue = 15

		let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
		vertical.minimumRelativeValue = -15
		vertical.maximumRelativeValue = 15

		let effect = UIMotionEffectGroup()
		effect.motionEffects = [horizontal, vertical]
		dialogView.addMotionEffect(effect)
	}
}