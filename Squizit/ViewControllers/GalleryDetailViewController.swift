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
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewCenterYAlignmentConstraint: NSLayoutConstraint!
	@IBOutlet weak var playerNamesLabel: UILabel!
	@IBOutlet weak var matchDateLabel: UILabel!

	class func identifier() ->String { return "GalleryDetailCollectionViewCell" }

	override func prepareForReuse() {
		if DebugLayout {
			backgroundColor = UIColor(hue: CGFloat(drand48()), saturation: 0.5 + CGFloat(drand48()/2), brightness: 0.5 + CGFloat(drand48()/2), alpha: CGFloat(0.5))
		}
	}

	override func awakeFromNib() {
		super.awakeFromNib()

		// for some reason I can't set Baskerville in IB
		playerNamesLabel.font = UIFont(name: "Baskerville", size: playerNamesLabel.font.pointSize)
		matchDateLabel.font = UIFont(name:"Baskerville-Italic", size: matchDateLabel.font.pointSize)

		imageView.layer.shadowColor = UIColor.blackColor().CGColor
		imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		imageView.layer.shadowOpacity = 1
		imageView.layer.shadowRadius = 5
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		setNeedsUpdateConstraints()
	}

	override func updateConstraints() {
		super.updateConstraints()
		imageViewHeightConstraint.constant = self.bounds.height * 0.8
		imageViewCenterYAlignmentConstraint.constant = playerNamesLabel.intrinsicContentSize().height + matchDateLabel.intrinsicContentSize().height
	}

}

class GalleryDetailCollectionViewDataSource : BasicGalleryCollectionViewDataSource {

	private var _renderQueue = dispatch_queue_create("com.zakariya.squizit.GalleryDetailRenderQueue", nil)
	private var _matchBackgroundColor = SquizitTheme.paperBackgroundColor()

	override var cellIdentifier:String {
		return GalleryDetailCollectionViewCell.identifier()
	}

	override var fetchBatchSize:Int {
		return 3
	}

	override func configureCell( cell:UICollectionViewCell, atIndexPath indexPath:NSIndexPath ) {
		let store = self.store
		let backgroundColor = _matchBackgroundColor
		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			//
			//	Now, we have to render the thumbnail - it comes from the store as a transparent PNG, 
			//	with pen/brush strokes in black, and eraser in white. We need to multiply composite
			//	it over the paper texture to make a viable thumbnail image
			//

			var galleryCell = cell as GalleryDetailCollectionViewCell


			var artistNames:[String] = []
			for artist in drawing.artists {
				artistNames.append(artist.name)
			}

			var playerNamesText = NSLocalizedString("Anonymous", comment: "No artist specified for gallery detail image")
			if !artistNames.isEmpty {
				playerNamesText = (artistNames as NSArray).componentsJoinedByString(", ")
			}

			galleryCell.playerNamesLabel.text = playerNamesText

			galleryCell.matchDateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))

			dispatch_async( _renderQueue ) {

				if let buffer = ByteBuffer.fromNSData( drawing.match ) {
					var matchLoadResult = buffer.getMatch()
					if let error = matchLoadResult.error {
						NSLog("Unable to load match from data, error: %@", error.message )
						assertionFailure("Unable to load match from data, bailing" )
					}

					var match = matchLoadResult.value
					var rendering = match.render( UIColor.clearColor() )

					let size = rendering.size
					let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
					UIGraphicsBeginImageContextWithOptions(size, true, 0)

					backgroundColor.set()
					UIRectFillUsingBlendMode(rect, kCGBlendModeNormal)

					rendering.drawAtPoint(CGPoint(x: 0, y: 0), blendMode: kCGBlendModeMultiply, alpha: 1)

					rendering = UIGraphicsGetImageFromCurrentImageContext()
					UIGraphicsEndImageContext()


					dispatch_main {
						galleryCell.imageView.image = rendering
					}
				}
			}

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
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if let targetIndexPath = initialIndexPath {
			collectionView!.scrollToItemAtIndexPath(targetIndexPath,
				atScrollPosition: .CenteredVertically | .CenteredHorizontally,
				animated: false)
		}
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

	// MARK: UIScrollViewDelegate


	override func scrollViewDidScroll(scrollView: UIScrollView) {
		updateTitle()
	}

	override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		updateTitle()
	}

	private var _debouncedTitleUpdater:(()->())?
	private func updateTitle() {
		if _debouncedTitleUpdater == nil {
			var collectionView = self.collectionView!
			var flow = collectionView.collectionViewLayout as UICollectionViewFlowLayout
			var numItems = _dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

			_debouncedTitleUpdater = debounce(0.2, {
				[weak self] () -> () in
				if let sself = self {

					var itemWidth = flow.itemSize.width
					var totalWidth = collectionView.contentSize.width
					var position = collectionView.contentOffset.x / totalWidth
					var index = Int(floor( CGFloat(position) * CGFloat(numItems) + CGFloat(0.5))) + 1
					//NSLog( "position: %@, index: %@", position, index )

					sself.title = "Drawing \(index) of \(numItems)"
				}
			})
		}

		_debouncedTitleUpdater!()
	}
}
