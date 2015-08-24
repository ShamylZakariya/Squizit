//
//  UniversalHowToPlayViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit



class UniversalHowToPlayViewController : UIPageViewController, UIPageViewControllerDataSource,UIPageViewControllerDelegate {

	var skipBarButtonItem:UIBarButtonItem!
	var nextBarButtonItem:UIBarButtonItem!
	var doneBarButtonItem:UIBarButtonItem!

	lazy var messages:[String] = {
		return [
			NSLocalizedString("A piece of paper is folded over itself into halves or thirds",comment:"instructions-message-0"),
			NSLocalizedString("The first player draws all the way to the bottom fold - leaving marks to guide the next player",comment:"instructions-message-1"),
			NSLocalizedString("The next player completes the drawing, guided by the marks left at the top by the previous player",comment:"instructions-message-2"),
			NSLocalizedString("The paper is unfolded - we have an Exquisite Corpse",comment:"instructions-message-3")
		]
	}()

	lazy var images:[UIImage] = {
		return [
			UIImage(named:"instructions-1")!,
			UIImage(named:"instructions-2")!,
			UIImage(named:"instructions-3")!,
			UIImage(named:"instructions-4")!
		]
	}()

	override func awakeFromNib() {
		super.awakeFromNib()
		title = "How to Play"
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		setViewControllers([vend(0)], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)

		dataSource = self
		delegate = self

		skipBarButtonItem = UIBarButtonItem(title: "Skip", style: UIBarButtonItemStyle.Plain, target: self, action: "onDoneTapped:")
		nextBarButtonItem = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Done, target: self, action: "onNextTapped:")
		doneBarButtonItem = UIBarButtonItem(title: "Got it", style: UIBarButtonItemStyle.Done, target: self, action: "onDoneTapped:")

		navigationItem.leftBarButtonItem = skipBarButtonItem
		navigationItem.rightBarButtonItem = nextBarButtonItem
	}

	// MARK: - UIPageViewControllerDataSource

	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let pageVc = viewController as! ManagedIndexedViewViewController
		if pageVc.index > 0 {
			return vend(pageVc.index-1)
		}

		return nil
	}

	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		let pageVc = viewController as! ManagedIndexedViewViewController
		if pageVc.index < count-1 {
			return vend(pageVc.index+1)
		}

		return nil
	}

	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
		return count
	}

	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
		return currentIndex
	}

	// MARK: - UIPageViewControllerDelegate

	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
		let pageVc = pageViewController.viewControllers.first as! ManagedIndexedViewViewController
		currentIndex = pageVc.index
	}

	// MARK: - Actions


	dynamic func onDoneTapped(sender: AnyObject) {
		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}

	dynamic func onNextTapped(sender: AnyObject) {
		stepForward()
	}

	// MARK: - Private

	private func vend(index:Int)->ManagedIndexedViewViewController {

		if index < 0 || index > count - 1 {
			assertionFailure("UniversalHowToPlayViewController index:\(index) is out of range:[0,\(count-1)]")
		}

		var page = InstructionView.create()

		page.label.attributedText = NSAttributedString(string: messages[index], attributes: [
			NSForegroundColorAttributeName: UIColor.whiteColor(),
			NSFontAttributeName:UIFont(name: "Avenir-Black", size: 16)!
		])

		page.centeredImageView.image = images[index]
		page.centeredImageView.imageView.layer.shadowColor = UIColor.blackColor().CGColor
		page.centeredImageView.imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		page.centeredImageView.imageView.layer.shadowOpacity = 1
		page.centeredImageView.imageView.layer.shadowRadius = 5

		return ManagedIndexedViewViewController(view: page, index: index, respectsTopLayoutGuide:true)
	}

	private var count:Int {
		return messages.count
	}

	private var currentIndex:Int = 0 {
		didSet {
			if currentIndex == count - 1 {
				navigationItem.leftBarButtonItem = nil
				navigationItem.rightBarButtonItem = doneBarButtonItem
			} else {
				navigationItem.leftBarButtonItem = skipBarButtonItem
				navigationItem.rightBarButtonItem = nextBarButtonItem
			}
		}
	}

	private func stepForward() {
		if currentIndex < count - 1 {
			currentIndex++
			setViewControllers([vend(currentIndex)], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
		}
	}

}
