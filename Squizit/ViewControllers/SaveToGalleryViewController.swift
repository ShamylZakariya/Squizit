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


	@IBOutlet weak var questionLabel: UILabel!
	@IBOutlet weak var playerOneNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var playerTwoNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var playerThreeNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var addToGalleryButton: SquizitThemeButton!
	@IBOutlet weak var discardButton: SquizitThemeButton!

	weak var delegate:SaveToGalleryDelegate?

	var nameCount:Int = 3 {
		didSet {
			if nameCount < 2 || nameCount > 3 {
				assertionFailure("SaveTogalleryViewController only supports 2 or 3 player names")
			}
		}
	}

	// MARK: UIViewController Overrides

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = SquizitTheme.dialogBackgroundColor()
		discardButton.destructive = true
		questionLabel.font = UIFont(name: "Baskerville-Italic", size: UIFont.labelFontSize())

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		switch nameCount {
			case 2:
				playerOneNameInputField.nextField = playerTwoNameInputField
				playerTwoNameInputField.nextField = playerOneNameInputField
				playerThreeNameInputField.hidden = true

			case 3:
				playerOneNameInputField.nextField = playerTwoNameInputField
				playerTwoNameInputField.nextField = playerThreeNameInputField
				playerThreeNameInputField.nextField = playerOneNameInputField
				playerThreeNameInputField.hidden = false

			default:
				break;
		}

	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		layout()
	}

	// MARK: IBActions

	@IBAction func addToGallery(sender: AnyObject) {

		// first tap opens the name entry fields
		if !self.open {
			self.open = true
		} else {

			// collect names
			var names:[String] = []
			var nameCount = 0
			for nameField in [playerOneNameInputField,playerTwoNameInputField,playerThreeNameInputField] {
				var name = nameField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
				if countElements(name) == 0 {
					name = NSLocalizedString("Anonymous", comment: "AnonymousPlayerIdentifier")
				} else {
					nameCount++
				}

				names.append( name )
			}

			delegate?.didSaveToGalleryWithNames( nameCount > 0 ? names : nil )
		}
	}

	@IBAction func discard(sender: AnyObject) {
		delegate?.didDismissSaveToGallery()
	}

	// MARK: Keyboard Handling

	dynamic private func keyboardWillShow( note:NSNotification ) {
		if let info:Dictionary = note.userInfo {
			if let keyboardRect = info[UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {
				keyboardHeight = keyboardRect.height
			}
		}
	}

	dynamic private func keyboardWillHide( note:NSNotification ) {
		keyboardHeight = 0
	}

	private var keyboardHeight:CGFloat = 0 {
		didSet {
			animateLayout()
		}
	}

	// MARK: UITextFieldDelegate

	func textFieldShouldReturn(textField: UITextField!) -> Bool {

		if let tf = textField as? SquizitThemeNameInputField {
			tf.nextField?.becomeFirstResponder()
		} else {
			textField.resignFirstResponder()
		}

		return true
	}

	// MARK: Private

	private func animateLayout() {
		UIView.animateWithDuration(0.7,
			delay: 0,
			usingSpringWithDamping: 0.7,
			initialSpringVelocity: 0.0,
			options: UIViewAnimationOptions(0),
			animations: { () -> Void in
				self.layout()
			},
			completion: nil)
	}

	private func layout() {
		let dialogSize = self.dialogSize
		self.view.superview?.bounds = CGRect(x: 0, y: 0, width: dialogSize.width, height: dialogSize.height)
		view.superview?.layer.cornerRadius = 0

		if keyboardHeight > 0 {
			let screenHeight = UIScreen.mainScreen().bounds.height
			if let superview = self.view.superview {
				var frame = superview.frame
				frame.origin.y = (screenHeight - keyboardHeight)/2 - dialogSize.height/2
				superview.frame = frame
			}
		}

		let alpha:CGFloat = open ? 1.0 : 0.0
		questionLabel.alpha = alpha
		playerOneNameInputField.alpha = alpha
		playerTwoNameInputField.alpha = alpha
		playerThreeNameInputField.alpha = alpha
	}

	private var dialogSize:CGSize {

		let width:CGFloat = 300.0
		let heightWhen3NamesAreVisible:CGFloat = 468.0;
		let heightWhenClosed:CGFloat = 306.0
		let playerThreeNameInputFieldHeight:CGFloat = playerThreeNameInputField.intrinsicContentSize().height

		if !open {
			return CGSize( width: width, height: heightWhenClosed )
		}

		switch nameCount {
			case 2: return CGSize( width: width, height: heightWhen3NamesAreVisible - playerThreeNameInputFieldHeight )
			case 3: return CGSize( width: width, height: heightWhen3NamesAreVisible )
			default: return CGSizeZero
		}
	}

	private var open:Bool = false {
		didSet {
			animateLayout()
		}
	}
}