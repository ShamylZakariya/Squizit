//
//  GalleryDetailPageViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/22/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit
import Social

class TextActivityItemProvider : UIActivityItemProvider {

	override func item() -> AnyObject! {

		if let playerNames = self.placeholderItem as? String {
			if !playerNames.isEmpty {
				switch activityType! {
				case UIActivityTypePostToTwitter:
					return "@squizitapp match between " + playerNames

				default:
					return "SQUIZIT match between " + playerNames
				}
			} else {
				switch activityType! {
				case UIActivityTypePostToTwitter:
					return "@squizitapp"

				default:
					return "SQUIZIT match!"
				}
			}
		}

		return placeholderItem
	}
}


class GalleryDetailPageViewController : UIPageViewController, UIPageViewControllerDataSource,UIPageViewControllerDelegate {

	private let MaxPageCountToSeePageControl = 10

	private var renderQueue = dispatch_queue_create("com.zakariya.squizit.GalleryDetailPageViewControllerRenderQueue", nil)
	private var exportQueue = dispatch_queue_create("com.zakariya.squizit.GalleryDetailPageViewControllerExportQueue", nil)
	private var drawingBackgroundColor = SquizitTheme.paperBackgroundColor()
	private var baseTitle = "Showcase"
	private var pageIndicatorLabel:UILabel?

	var store:GalleryStore!
	var initialIndex:Int = 0 {
		didSet {
			currentIndex = initialIndex
		}
	}

	private var currentIndex:Int = 0

	override func awakeFromNib() {
		super.awakeFromNib()
		title = baseTitle
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		let initialPageVc = vend(initialIndex)
		setViewControllers([initialPageVc], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)

		dataSource = self
		delegate = self

		//
		//	Set up share buttons - a generic share, and a specific direct-to-twitter action if Twitter is available on this device
		//

		let shareAction = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "shareDrawing:")

		if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {

			let twitterIcon = UIImage(named: "gallery-detail-twitter-export-icon")!.imageWithRenderingMode(.AlwaysTemplate)
			let shareToTwitterAction = UIBarButtonItem(image: twitterIcon, style: .Plain, target: self, action: "shareDrawingToTwitter:")

			self.navigationItem.rightBarButtonItems = [ shareAction, shareToTwitterAction ]
		} else {
			self.navigationItem.rightBarButtonItem = shareAction
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		updatePageControlVisibility()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if let pageIndicatorLabel = pageIndicatorLabel {
			let padding = CGFloat(20)
			let labelWidth = view.bounds.width - 2*padding
			let labelHeight = pageIndicatorLabel.sizeThatFits(CGSize(width: labelWidth, height: 999)).height
			pageIndicatorLabel.frame = CGRect(x: 20, y: view.bounds.height - padding/2 - labelHeight, width: labelWidth, height: labelHeight)
		}
	}

	private func vend(index:Int)->ManagedIndexedViewViewController {

		let indexPath = NSIndexPath(forItem: index, inSection: 0)
		let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as! GalleryDrawing

		var page = GalleryDetailPageView.create()
		page.playerNamesLabel.text = drawing.artistDisplayNames
		page.matchDateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))

		page.centeredImageView.alpha = 0
		page.centeredImageView.imageView.layer.shadowColor = UIColor.blackColor().CGColor
		page.centeredImageView.imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		page.centeredImageView.imageView.layer.shadowOpacity = 1
		page.centeredImageView.imageView.layer.shadowRadius = 5


		// render the match
		dispatch_async( renderQueue ) {
			let loadResult = Match.load(drawing.match)
			if let error = loadResult.error {
				assertionFailure("Unable to load match from data, error:\(error.message)" )
			}

			var match = loadResult.value
			var rendering = match.render( backgroundColor: self.drawingBackgroundColor )

			dispatch_main {
				page.centeredImageView.image = rendering
				UIView.animateWithDuration(0.3) {
					page.centeredImageView.alpha = 1
				}
			}
		}

		return ManagedIndexedViewViewController(view: page, index: index, respectsTopLayoutGuide:true)
	}

	private lazy var dateFormatter:NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
		dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
		return dateFormatter
	}()


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
		return initialIndex
	}

	// MARK: - UIPageViewControllerDelegate

	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
		let pageVc = pageViewController.viewControllers.first as! ManagedIndexedViewViewController
		currentIndex = pageVc.index
		updatePageIndicatorLabel()
	}

	// MARK: - CoreData

	var count:Int {
		let info = self.fetchedResultsController.sections![0] as! NSFetchedResultsSectionInfo
		return info.numberOfObjects
	}

	private var _fetchedResultsController:NSFetchedResultsController?
	var fetchedResultsController:NSFetchedResultsController {
		if _fetchedResultsController != nil {
			return _fetchedResultsController!
		}

		var fetchRequest = NSFetchRequest()
		fetchRequest.entity = NSEntityDescription.entityForName(GalleryDrawing.entityName(), inManagedObjectContext: store.managedObjectContext! )

		fetchRequest.sortDescriptors = self.sortDescriptors
		fetchRequest.fetchBatchSize = fetchBatchSize
		if let predicate = self.filterPredicate {
			fetchRequest.predicate = predicate
		}

		_fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: store.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		performFetch()

		return _fetchedResultsController!
	}

	var fetchBatchSize:Int {
		return 3
	}

	var sortDescriptors:[NSSortDescriptor] = [NSSortDescriptor(key: "date", ascending: false)] {
		didSet {
			if _fetchedResultsController != nil {
				fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors
				performFetch()
			}
		}
	}

	var filterPredicate:NSPredicate? {
		didSet {
			if _fetchedResultsController != nil {
				fetchedResultsController.fetchRequest.predicate = filterPredicate
				performFetch()
			}
		}
	}

	private func performFetch() {
		var error:NSError? = nil
		if !fetchedResultsController.performFetch(&error) {
			NSLog("Unable to execute fetch, error: %@", error!.localizedDescription )
			abort()
		}
	}

	// MARK: Actions

	dynamic func shareDrawingToTwitter( sender:AnyObject ) {
		export { [weak self] drawing, rendering in
			if let sself = self {

				var message = "@squizitapp"
				if drawing.artists.count > 0 {
					message += " match between " + drawing.artistDisplayNames
				}

				var shareVC = SLComposeViewController_Twitter()
				shareVC.setInitialText(message)
				shareVC.addImage(rendering)

				sself.presentViewController(shareVC, animated: true, completion: nil)
			}
		}
	}

	dynamic func shareDrawing( sender:AnyObject ) {

		export { [weak self] drawing, rendering in
			if let sself = self {

				var title:String = ""
				if drawing.artists.count > 0 {
					title += drawing.artistDisplayNames
				}

				let textItem = TextActivityItemProvider(placeholderItem: title)
				let items = [rendering, textItem]

				let activityController = UIActivityViewController( activityItems: items, applicationActivities: nil)
				activityController.popoverPresentationController?.barButtonItem = sender as! UIBarButtonItem
				activityController.view.tintColor = SquizitTheme.alertTintColor()
				sself.presentViewController(activityController, animated: true, completion: nil)
			}
		}
	}

	func export( done:(drawing:GalleryDrawing, rendering:UIImage! )->Void ) {

		let indexPath = NSIndexPath(forItem: currentIndex, inSection: 0)
		let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as! GalleryDrawing

		dispatch_async(exportQueue) {

			let loadResult = Match.load(drawing.match)
			if let error = loadResult.error {
				assertionFailure("Unable to load match from data, error:\(error.message)" )
			}

			var match = loadResult.value
			var background = SquizitTheme.exportedMatchBackgroundColor()
			var rendering = match.render( backgroundColor: background, scale:2, watermark: true )

			dispatch_main {
				done( drawing:drawing, rendering:rendering )
			}
		}
	}

	// MARK: - Private

	private func updatePageControlVisibility() {
		if let pageControl = self.pageControl {
			if !shouldShowPageControl{
				if !pageControl.hidden {
					UIView.animateWithDuration(0.2, animations: {
						pageControl.alpha = 0
						}, completion: { completed in
							pageControl.hidden = true
					})
				}
			} else if pageControl.hidden {
				pageControl.alpha = 0
				pageControl.hidden = false
				UIView.animateWithDuration(0.2) {
					pageControl.alpha = 1
				}
			}
		}
		updatePageIndicatorLabel()
	}

	private var shouldShowPageControl:Bool {
		return count <= MaxPageCountToSeePageControl
	}

	private func updatePageIndicatorLabel() {
		if shouldShowPageControl {
			if let pageIndicatorLabel = pageIndicatorLabel {
				pageIndicatorLabel.removeFromSuperview()
				self.pageIndicatorLabel = nil
			}
		} else {
			if pageIndicatorLabel == nil {
				pageIndicatorLabel = UILabel(frame: CGRect.zeroRect)
				pageIndicatorLabel!.font = UIFont(name: "Baskerville-Italic", size: 12)!
				pageIndicatorLabel!.textColor = UIColor.whiteColor()
				pageIndicatorLabel!.textAlignment = NSTextAlignment.Center
				pageIndicatorLabel!.alpha = 0
				view.addSubview(pageIndicatorLabel!)

				UIView.animateWithDuration(0.2) {
					self.pageIndicatorLabel!.alpha = 1
				}
			}

			pageIndicatorLabel!.text = "\(currentIndex+1) of \(count)"
		}
	}

}
