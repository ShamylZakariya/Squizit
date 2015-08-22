//
//  GalleryDetailViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit


let DebugLayout = false

struct RenderActionContext {
	var drawing:GalleryDrawing
	var match:Match
	var image:UIImage
}

class GalleryDetailCollectionViewCell : UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var playerNamesLabel: UILabel!
	@IBOutlet weak var matchDateLabel: UILabel!

	var renderAction:CancelableAction<RenderActionContext>?
	var drawing:GalleryDrawing?
	private (set) var thumbnail:UIImage?

	class func identifier() ->String { return "GalleryDetailCollectionViewCell" }

	override func awakeFromNib() {
		super.awakeFromNib()

		if DebugLayout {
			backgroundColor = UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 0.5, alpha: 0.5)
		}

		imageView.backgroundColor = SquizitTheme.paperBackgroundColor()
		imageView.contentMode = UIViewContentMode.ScaleAspectFit
		imageView.layer.shadowColor = UIColor.blackColor().CGColor
		imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		imageView.layer.shadowOpacity = 1
		imageView.layer.shadowRadius = 5

		// for some reason I can't set Baskerville in IB
		playerNamesLabel.font = UIFont(name: "Baskerville", size: playerNamesLabel.font.pointSize)
		matchDateLabel.font = UIFont(name:"Baskerville-Italic", size: matchDateLabel.font.pointSize)

		prepareForReuse()
	}

	override func prepareForReuse() {
		renderAction = nil
		drawing = nil
		setThumbnail(nil, animate: false)
	}

	func setThumbnail(thumbnail:UIImage?,animate:Bool) {

		imageView.image = thumbnail
		if let thumbnail = thumbnail {

			setNeedsLayout()
			layoutIfNeeded()

			let padding:CGFloat = 20
			let aspect = thumbnail.size.width / thumbnail.size.height
			let maxImageViewWidth = frame.width - 2*padding
			let maxImageViewHeight = frame.height - imageView.frame.minY - 72

			var imageHeight = playerNamesLabel.frame.minY - padding - imageView.frame.minY
			var imageWidth = imageHeight * aspect

			if imageWidth > maxImageViewWidth {
				imageWidth = maxImageViewWidth
				imageHeight = imageWidth / aspect
			}

			if imageHeight > maxImageViewHeight {
				let scale = maxImageViewHeight / imageHeight
				imageHeight *= scale
				imageWidth *= scale
			}

			imageViewHeightConstraint.constant = imageHeight
			imageViewWidthConstraint.constant = imageWidth
			//imageViewTopConstraint.constant = (maxImageViewHeight - imageHeight)/2

			if animate {
				UIView.animateWithDuration(0.3) {
					self.imageView.alpha = 1
				}
			} else {
				imageView.alpha = 1
			}
		} else {
			imageView.alpha = 0
		}
		
		setNeedsLayout()
	}

}

class GalleryDetailCollectionViewDataSource : BasicGalleryCollectionViewDataSource {

	private var _renderQueue = dispatch_queue_create("com.zakariya.squizit.GalleryDetailRenderQueue", nil)
	private var _drawingBackgroundColor = SquizitTheme.paperBackgroundColor()

	override var cellIdentifier:String {
		return GalleryDetailCollectionViewCell.identifier()
	}

	override var fetchBatchSize:Int {
		return 3
	}

	override func configureCell( cell:UICollectionViewCell, atIndexPath indexPath:NSIndexPath ) {
		let store = self.store
		let backgroundColor = _drawingBackgroundColor
		let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
		let itemSize = flowLayout.itemSize
		let thumbnailHeight = round(itemSize.height * 0.85)

		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			var galleryCell = cell as! GalleryDetailCollectionViewCell

			galleryCell.drawing = drawing
			galleryCell.playerNamesLabel.text = drawing.artistDisplayNames
			galleryCell.matchDateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))

			let index = indexPath.item
			let loader = loaderFor( index )

			//
			//	If the loader has completed already, just assign the image without animation
			//	Otherwise, cache the loader so the cell can cancel it when reused, and set the done
			//	action to assign the image
			//

			if let result = loader.result {
				galleryCell.setThumbnail(result.image, animate: false)
				galleryCell.renderAction = nil
			} else {
				galleryCell.renderAction = loader
				galleryCell.renderAction!.done = { result in
					dispatch_main {
						if galleryCell.drawing === result.drawing {
							galleryCell.setThumbnail(result.image, animate: true)
						}
					}
				}
			}

			// preload neighbor drawings, and prune drawings that are farther away
			preloadAndPrune( index )

		} else {
			assertionFailure("Unable to vend a GalleryDrawing for index path")
		}
	}

	private var _loaders:[Int:CancelableAction<RenderActionContext>?] = [:]

	private func loaderFor( index:Int ) -> CancelableAction<RenderActionContext> {
		let indexPath = NSIndexPath(forItem: index, inSection: 0 )
		let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as! GalleryDrawing

		// check for an existing loader @ index
		if let existingLoader = _loaders[index] {
			if let existingLoader = existingLoader {
				return existingLoader
			}
		}

		// we need to create a new loader and store it @ index

		let queue = _renderQueue
		let backgroundColor = _drawingBackgroundColor
		let loader = CancelableAction<RenderActionContext>(action: { done, canceled in

			dispatch_async( queue ) {
				let loadResult = Match.load(drawing.match)
				if let error = loadResult.error {
					NSLog("Unable to load match from data, error: %@", error.message )
					assertionFailure("Unable to load match from data, bailing" )
				}

				var match = loadResult.value
				var rendering = match.render( backgroundColor: backgroundColor )
				done( result:RenderActionContext(drawing:drawing,match:match,image:rendering))
			}
		})

		_loaders[index] = loader
		return loader
	}

	/*
		Ensures loaders are allocated for (index - 1) and (index + 1), and
		cancels and clears loaders outside that range
	*/
	private func preloadAndPrune( index:Int ) {

		// preload neighbors
		let count = self.count

		if index > 0 {
			loaderFor( index - 1 )
		}

		if index < count - 1 {
			loaderFor( index + 1 )
		}

		// prune loaders up to but not including index - 1
		if index > 2 {
			for i in 0 ..< index - 1 {
				if let maybeLoader = _loaders[i] {
					if let loader = maybeLoader {
						loader.cancel()
					}
					_loaders[i] = nil
				}
			}
		}

		// prune loaders from index + 2 to end
		if index < count - 2 {
			for i in index + 2 ..< count {
				if let maybeLoader = _loaders[i] {
					if let loader = maybeLoader {
						loader.cancel()
					}
					_loaders[i] = nil
				}
			}
		}
	}

	lazy var dateFormatter:NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
		dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
		return dateFormatter
	}()

}

class GalleryDetailViewController: UICollectionViewController, UIScrollViewDelegate {

	private var exportQueue = dispatch_queue_create("com.zakariya.squizit.GalleryDetailExportQueue", nil)
	private var dataSource:GalleryDetailCollectionViewDataSource!

	var store:GalleryStore!
	var filterPredicate:NSPredicate?
	var initialIndexPath:NSIndexPath?


	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
	}

	override func didReceiveMemoryWarning() {
		dataSource.didReceiveMemoryWarning()
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = SquizitTheme.galleryBackgroundColor()
		collectionView!.backgroundColor = SquizitTheme.galleryBackgroundColor()
		dataSource = GalleryDetailCollectionViewDataSource(store: store, collectionView: collectionView!)
		dataSource.scrollDelegate = self

		if let fp = filterPredicate {
			dataSource.filterPredicate = filterPredicate
		}

		var flow = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
		flow.minimumInteritemSpacing = 0
		flow.minimumLineSpacing = 0
		flow.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		updateItemSize()

		let numItems = dataSource.collectionView(collectionView!, numberOfItemsInSection: 0)
		if numItems == 1 {
			if let drawing = dataSource.fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? GalleryDrawing {
				self.title = drawing.artistDisplayNames
			}
		}

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

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if let targetIndexPath = initialIndexPath {
			collectionView!.scrollToItemAtIndexPath(targetIndexPath,
				atScrollPosition: .CenteredVertically | .CenteredHorizontally,
				animated: false)
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		updateScrollPageIndex()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		updateItemSize()
	}

	private func updateItemSize() {
		var flow = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
		let width = view.bounds.width
		let height = view.bounds.height - topLayoutGuide.length
		flow.itemSize = CGSize(width: width, height: height)
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
		if let indexPath = self.collectionView!.indexPathsForVisibleItems().first as? NSIndexPath {
			let action = dataSource.loaderFor( indexPath.item )
			if let result = action.result {
				dispatch_async(exportQueue) {

					var background = SquizitTheme.exportedMatchBackgroundColor()
					var rendering = result.match.render( backgroundColor: background, scale:2, watermark: true )

					dispatch_main {
						done( drawing:result.drawing, rendering:rendering )
					}
				}
			} else {
				assertionFailure("Unable to get result from action")
			}
		}
	}

	// MARK: UIScrollViewDelegate

	override func scrollViewDidScroll(scrollView: UIScrollView) {
		updateScrollPageIndex()
	}

	override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		updateScrollPageIndex()
	}

	private lazy var updateScrollPageIndex:(()->()) = {
		return debounce(0.1, {
			[weak self] () -> () in
			if let sself = self {

				let flow = sself.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
				let numItems = sself.dataSource.collectionView(sself.collectionView!, numberOfItemsInSection: 0)

				let itemWidth = flow.itemSize.width
				let totalWidth = sself.collectionView!.contentSize.width
				let position = sself.collectionView!.contentOffset.x / totalWidth

				sself.scrollPageIndex = max(Int(floor( CGFloat(position) * CGFloat(numItems) + CGFloat(0.5))), 0 )
			}
		})
	}()

	private var scrollPageIndex:Int = -1 {
		didSet {
			if scrollPageIndex != oldValue {
				self.title = "Drawing \(scrollPageIndex+1) of \(numPages)"
			}
		}
	}

	private var numPages:Int {
		return dataSource.count
	}

}
