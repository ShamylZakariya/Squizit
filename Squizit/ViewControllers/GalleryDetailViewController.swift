//
//  GalleryDetailViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit
import Lilliput

let DebugLayout = false

class GalleryDetailCollectionViewCell : UICollectionViewCell {
	@IBOutlet weak var imageView: ImagePresenterView!
	@IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewCenterYAlignmentConstraint: NSLayoutConstraint!
	@IBOutlet weak var playerNamesLabel: UILabel!
	@IBOutlet weak var matchDateLabel: UILabel!

	var renderAction:CancelableAction<UIImage>?

	class func identifier() ->String { return "GalleryDetailCollectionViewCell" }

	override func awakeFromNib() {
		super.awakeFromNib()

		imageView.backgroundColor = SquizitTheme.paperBackgroundColor()

		// for some reason I can't set Baskerville in IB
		playerNamesLabel.font = UIFont(name: "Baskerville", size: playerNamesLabel.font.pointSize)
		matchDateLabel.font = UIFont(name:"Baskerville-Italic", size: matchDateLabel.font.pointSize)

		imageView.layer.shadowColor = UIColor.blackColor().CGColor
		imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		imageView.layer.shadowOpacity = 1
		imageView.layer.shadowRadius = 5

		prepareForReuse()
	}

	override func prepareForReuse() {

		if let action = renderAction {
			action.cancel()
			renderAction = nil
		}

		imageView.image = nil

		if DebugLayout {
			backgroundColor = UIColor(hue: CGFloat(drand48()), saturation: 0.5 + CGFloat(drand48()/2), brightness: 0.5 + CGFloat(drand48()/2), alpha: CGFloat(0.5))
		}
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
		let flowLayout = self.collectionView.collectionViewLayout as UICollectionViewFlowLayout
		let itemSize = flowLayout.itemSize
		let thumbnailHeight = itemSize.height * 0.85

		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			//
			//	Now, we have to render the thumbnail - it comes from the store as a transparent PNG, 
			//	with pen/brush strokes in black, and eraser in white. We need to multiply composite
			//	it over the paper texture to make a viable thumbnail image
			//

			var galleryCell = cell as GalleryDetailCollectionViewCell

			galleryCell.playerNamesLabel.text = drawing.artistDisplayNames
			galleryCell.matchDateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))


			// use the thumbnail's size to set the cell image size & aspect ratio
			let thumbnailActualHeight = CGFloat(drawing.thumbnailHeight)
			let thumbnailActualWidth = CGFloat(drawing.thumbnailWidth)
			let thumbnailWidth = thumbnailActualWidth * (thumbnailHeight/thumbnailActualHeight)
			galleryCell.imageViewHeightConstraint.constant = thumbnailHeight
			galleryCell.imageViewWidthConstraint.constant = thumbnailWidth

			// offset the vertical centering constraint
			galleryCell.imageViewCenterYAlignmentConstraint.constant = (galleryCell.playerNamesLabel.intrinsicContentSize().height + galleryCell.matchDateLabel.intrinsicContentSize().height) / 2

			let queue = _renderQueue
			galleryCell.renderAction = CancelableAction<UIImage>(action: { done, canceled in

				dispatch_async( queue ) {

					if let buffer = ByteBuffer.fromNSData( drawing.match ) {
						if !canceled() {
							var matchLoadResult = buffer.getMatch()
							if let error = matchLoadResult.error {
								NSLog("Unable to load match from data, error: %@", error.message )
								assertionFailure("Unable to load match from data, bailing" )
							}

							var match = matchLoadResult.value
							if !canceled() {
								var rendering = match.render( backgroundColor: backgroundColor )
								done( result:rendering )
							}
						}
					}
				}

			}, done:{ ( result:UIImage ) -> () in

				dispatch_main {
					galleryCell.imageView.image = result
				}

			})

		} else {
			assertionFailure("Unable to vend a GalleryDrawing for index path")
		}
	}

	private var _dateFormatter:NSDateFormatter?
	private var dateFormatter:NSDateFormatter {
		if _dateFormatter != nil {
			return _dateFormatter!
		}

		_dateFormatter = NSDateFormatter()
		_dateFormatter!.timeStyle = NSDateFormatterStyle.ShortStyle
		_dateFormatter!.dateStyle = NSDateFormatterStyle.LongStyle
		return _dateFormatter!
	}

}

class GalleryDetailViewController: UICollectionViewController, UIScrollViewDelegate {

	private var _exportQueue = dispatch_queue_create("com.zakariya.squizit.GalleryDetailExportQueue", nil)

	var store:GalleryStore!
	var filterPredicate:NSPredicate?
	var initialIndexPath:NSIndexPath?

	private var _dataSource:BasicGalleryCollectionViewDataSource!

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
	}

	override func didReceiveMemoryWarning() {
		_dataSource.didReceiveMemoryWarning()
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = SquizitTheme.galleryBackgroundColor()
		collectionView!.backgroundColor = SquizitTheme.galleryBackgroundColor()
		_dataSource = GalleryDetailCollectionViewDataSource(store: store, collectionView: collectionView!)
		_dataSource.scrollDelegate = self

		if let fp = filterPredicate {
			_dataSource.filterPredicate = filterPredicate
		}

		var flow = collectionView!.collectionViewLayout as UICollectionViewFlowLayout
		flow.minimumInteritemSpacing = 0
		flow.minimumLineSpacing = 0
		flow.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		updateItemSize()

		let numItems = _dataSource.collectionView(collectionView!, numberOfItemsInSection: 0)
		if numItems == 1 {
			if let drawing = _dataSource.fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? GalleryDrawing {
				self.title = drawing.artistDisplayNames
			}
		}

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "shareDrawing:")
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
		updateItemSize()
	}

	private func updateItemSize() {
		var flow = collectionView?.collectionViewLayout as UICollectionViewFlowLayout
		let width = view.bounds.width
		let height = view.bounds.height - 44
		flow.itemSize = CGSize(width: width, height: height)
	}

	// MARK: Actions

	dynamic func shareDrawing( sender:AnyObject ) {

		// first get the current item
		if let indexPath = self.collectionView!.indexPathsForVisibleItems().first as? NSIndexPath {
			if let drawing = _dataSource.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

				export(drawing) {
					[weak self] (rendering:UIImage)->Void in
					if let sself = self {

						var title:String = ""

						if drawing.artists.count > 0 {
							title = NSLocalizedString( "Squizit Match featuring ", comment:"ShareActionTitleWithArtistNames")
							title += drawing.artistDisplayNames
						} else {
							title = NSLocalizedString( "Squizit Match", comment:"ShareActionTitleWithoutArtistNames")
						}

						let activityController = UIActivityViewController( activityItems: [title,rendering], applicationActivities: nil)
						activityController.popoverPresentationController?.barButtonItem = sender as UIBarButtonItem
						activityController.view.tintColor = SquizitTheme.alertTintColor()
						sself.presentViewController(activityController, animated: true, completion: nil)

					}
				}
			}
		}
	}

	func export( drawing:GalleryDrawing, done:(rendering:UIImage)->Void) {

		dispatch_async(_exportQueue) {

			if let buffer = ByteBuffer.fromNSData( drawing.match ) {
				var matchLoadResult = buffer.getMatch()
				if let error = matchLoadResult.error {
					NSLog("Unable to load match from data, error: %@", error.message )
					assertionFailure("Unable to load match from data, bailing" )
				}

				//
				//	Note: we're rendering the match in retina so it looks super good
				//

				var background = SquizitTheme.exportedMatchBackgroundColor()
				var match = matchLoadResult.value
				var scale:CGFloat = 2
				var rendering = match.render( backgroundColor: background, scale:scale, watermark: true )

				dispatch_main {
					done( rendering:rendering )
				}
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

	private func numItems() -> Int {
		if let collectionView = self.collectionView {
			let flow = collectionView.collectionViewLayout as UICollectionViewFlowLayout
			let numItems = _dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
			return numItems
		}

		return 0
	}

	private func updateScrollPageIndex() {
		if let collectionView = self.collectionView {
			let flow = collectionView.collectionViewLayout as UICollectionViewFlowLayout
			let numItems = _dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

			let itemWidth = flow.itemSize.width
			let totalWidth = collectionView.contentSize.width
			let position = collectionView.contentOffset.x / totalWidth

			scrollPageIndex = max(Int(floor( CGFloat(position) * CGFloat(numItems) + CGFloat(0.5))), 0 )
		}
	}

	private var scrollPageIndex:Int = -1 {
		didSet {
			if scrollPageIndex != oldValue {
				self.title = "Drawing \(scrollPageIndex+1) of \(numItems())"
			}
		}
	}
}
