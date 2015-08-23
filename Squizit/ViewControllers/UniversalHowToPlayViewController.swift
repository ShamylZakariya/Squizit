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
		nextBarButtonItem = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Plain, target: self, action: "onNextTapped:")
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

		var page = InstructionView.create()
		page.label.attributedText = NSAttributedString(string: "PAGE: \(index)", attributes: [
			NSForegroundColorAttributeName: UIColor.whiteColor()
			])


		page.centeredImageView.backgroundColor = UIColor.clearColor()

		return ManagedIndexedViewViewController(view: page, index: index, respectsTopLayoutGuide:true)
	}

	private var count:Int {
		return 3
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
