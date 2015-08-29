//
//  GalleryCollectionViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/29/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

let LOG_THUMBNAIL_RENDERING_LIFECYCLE = true

// MARK: - GalleryViewControllerDelegate

protocol GalleryViewControllerDelegate : class {

	func galleryDidDismiss( galleryViewController:AnyObject )

}

// MARK: - GalleryCollectionViewCell

let WigglePhaseDuration:NSTimeInterval = 0.2
let WiggleAngleMax = 0.75 * M_PI / 180.0

class GalleryCollectionViewCell : UICollectionViewCell {

	class func identifier() -> String { return "GalleryCollectionViewCell" }

	@IBOutlet weak var deleteButton: UIImageView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!

	private var deleting:Bool = false
	private let cycleOffset:NSTimeInterval = drand48() * M_PI_2
	private var phase:NSTimeInterval = 0
	private var wiggleAnimationDisplayLink:CADisplayLink?

	var drawing:GalleryDrawing?
	var indexInCollection:Int = 0

	var onLongPress:((( cell:GalleryCollectionViewCell )->())?)
	var onDeleteButtonTapped:((( cell:GalleryCollectionViewCell )->())?)

	var deleteButtonVisible:Bool = false {
		didSet {
			if deleteButtonVisible != oldValue {
				if deleteButtonVisible {
					self.showDeleteButton()
					startWiggling()
				} else {
					self.hideDeleteButton()
					stopWiggling()
				}
			}
		}
	}

	var thumbnail:UIImage? { return imageView.image }

	override func awakeFromNib() {
		super.awakeFromNib()
		clipsToBounds = false

		// uncomment to help debug layout
		//backgroundColor = UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 0.5, alpha: 0.5)

		deleteButton.alpha = 0
		deleteButton.hidden = true

		//imageView.clipsToBounds = true
		imageView.contentMode = UIViewContentMode.ScaleAspectFit

		// add shadows because we're a little skeumorphic here
		imageView.layer.shouldRasterize = true
		imageView.layer.shadowColor = UIColor.blackColor().CGColor
		imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		imageView.layer.shadowOpacity = 1
		imageView.layer.shadowRadius = 4

		addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "longPress:"))

		deleteButton.userInteractionEnabled = true
		deleteButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "deleteButtonTapped:"))

		// common initialization
		prepareForReuse()
	}

	override func prepareForReuse() {

		drawing = nil

		// reset layer transform and nil the image
		layer.transform = CATransform3DIdentity
		layer.opacity = 1

		setThumbnail(nil, animate: false)
	}

	func setThumbnail(thumbnail:UIImage?,animate:Bool) {
		imageView.image = thumbnail
		if let thumbnail = thumbnail {

			setNeedsLayout()
			layoutIfNeeded()

			let padding:CGFloat = 10
			let aspect = thumbnail.size.width / thumbnail.size.height
			let maxImageViewWidth = frame.width - 2*padding
			let maxImageViewHeight = frame.height - imageView.frame.minY - 72

			var imageHeight = label.frame.minY - padding - imageView.frame.minY
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

	dynamic func longPress( gr:UILongPressGestureRecognizer ) {
		switch gr.state {
			case UIGestureRecognizerState.Began:
				self.onLongPress?(cell:self)

			default: break;
		}
	}

	dynamic func deleteButtonTapped( tr:UITapGestureRecognizer ) {

		// flag that we're deleting - this halts the wiggle animation which would override our scale transform
		deleting = true
		let layer = self.layer
		let onDeleteButtonTapped = self.onDeleteButtonTapped

		UIView.animateWithDuration(0.2,
			animations: {
				[unowned self] () -> Void in
				let scale = CATransform3DMakeScale(0.1, 0.1, 1)
				layer.transform = CATransform3DConcat(layer.transform, scale)
				layer.opacity = 0
			}) {
				(complete:Bool) -> Void in
				onDeleteButtonTapped?(cell:self)
			}
	}

	func showDeleteButton() {
		let deleteButton = self.deleteButton
		UIView.animateWithDuration(0.2, animations: { () -> Void in
			deleteButton.hidden = false
			deleteButton.alpha = 1
		})
	}

	func hideDeleteButton() {
		let deleteButton = self.deleteButton
		UIView.animateWithDuration(0.2,
			animations: {
				[weak self] () -> Void in
				deleteButton.alpha = 0
			},
			completion:{
				(complete:Bool) -> Void in
				if complete {
					deleteButton.hidden = true
				}
			})
	}


	func startWiggling() {
		wiggleAnimationDisplayLink = CADisplayLink(target: self, selector: "updateWiggleAnimation")
		wiggleAnimationDisplayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
	}

	dynamic func updateWiggleAnimation() {

		if deleting {
			return
		}

		let now = NSDate().timeIntervalSinceReferenceDate
		let cycle = now / WigglePhaseDuration
		let sign = (indexInCollection % 2 == 0) ? +1.0 : -1.0
		let phase = sin(cycle * M_PI + cycleOffset * M_PI ) * sign
		let angle = CGFloat(phase * WiggleAngleMax)
		let layer = self.layer
		UIView.performWithoutAnimation { () -> Void in
			layer.transform = CATransform3DMakeRotation( angle, 0, 0, 1)
		}
	}

	func stopWiggling() {
		if let displayLink = wiggleAnimationDisplayLink {
			displayLink.invalidate()
			wiggleAnimationDisplayLink = nil
		}

		let layer = self.layer
		layer.removeAllAnimations()
		UIView.animateWithDuration( WigglePhaseDuration, animations: {
			layer.transform = CATransform3DIdentity
		})
	}
}

// MARK: - GalleryOverviewCollectionViewDataSource

class GalleryCollectionViewDataSource : BasicGalleryCollectionViewDataSource {

	private var thumbnailCompositorQueue = dispatch_queue_create("com.zakariya.squizit.GalleryThumbnailCompositorQueue", nil)
	private var thumbnailBackgroundColor = SquizitTheme.thumbnailBackgroundColor()
	private var renderedIconCache = NSCache()

	override init( store:GalleryStore, collectionView:UICollectionView ) {
		super.init(store: store, collectionView:collectionView)
	}

	var editMode:Bool = false {
		didSet {
			for cell in collectionView.visibleCells() {
				(cell as! GalleryCollectionViewCell).deleteButtonVisible = editMode
			}

			editModeChanged?( inEditMode: editMode )
		}
	}

	var editModeChanged:((inEditMode:Bool)->Void)?

	override var cellIdentifier:String {
		return GalleryCollectionViewCell.identifier()
	}

	override var fetchBatchSize:Int {
		return 16
	}

	var artistNameFilter:String? {
		didSet {
			var predicate:NSPredicate? = nil
			if artistNameFilter != oldValue {
				if let filter = artistNameFilter {
					if !filter.isEmpty {
						predicate = NSPredicate(format: "SUBQUERY(artists, $artist, $artist.name CONTAINS[cd] \"\(filter)\").@count > 0")
					}
				}
			}
			self.filterPredicate = predicate
		}
	}


	// MARK: UICollectionViewDelegate

	var galleryDrawingTapped:((drawing:GalleryDrawing,indexPath:NSIndexPath)->Void)?

	func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
		collectionView.deselectItemAtIndexPath(indexPath, animated: true)

		if !editMode {
			if let handler = galleryDrawingTapped, drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {
				handler( drawing: drawing, indexPath: indexPath )
			}
		}
	}

	override func configureCell( cell:UICollectionViewCell, atIndexPath indexPath:NSIndexPath ) {

		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			var galleryCell = cell as! GalleryCollectionViewCell

			galleryCell.drawing = drawing

			let nameAttrs = [
				NSFontAttributeName: UIFont(name: "Baskerville", size: 12)!,
				NSForegroundColorAttributeName: UIColor.whiteColor()
			]
			let dateAttrs = [
				NSFontAttributeName: UIFont(name: "Baskerville-Italic", size: 12)!,
				NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)
			]

			var attributedText = NSMutableAttributedString(string: drawing.artistDisplayNames, attributes: nameAttrs)
			attributedText.appendAttributedString(NSAttributedString(string: "\n" + dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date)),attributes: dateAttrs))

			galleryCell.label.attributedText = attributedText
			galleryCell.deleteButtonVisible = self.editMode

			// set the index in collection to aid in wiggle cycle direction (odd/even wiggle in different directions)
			galleryCell.indexInCollection = indexPath.item


			galleryCell.onLongPress = {
				[weak self]
				(cell:GalleryCollectionViewCell)->() in
				if let sself = self {
					if !sself.editMode {
						sself.editMode = true
					}
				}
			}

			galleryCell.onDeleteButtonTapped = {
				[weak self]
				(cell:GalleryCollectionViewCell)->() in
				if let sself = self {
					sself.store.managedObjectContext?.deleteObject(drawing)
					sself.store.save()
				}
			}

			let cache = renderedIconCache
			if let thumbnail = cache.objectForKey(drawing.uuid) as? UIImage {

				// no need to animate, since the thumbnail is already available
				galleryCell.setThumbnail(thumbnail, animate: false)

			} else {

				let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
				let itemSize = flowLayout.itemSize
				let thumbnailHeight = itemSize.height
				let queue = thumbnailCompositorQueue

				dispatch_async( queue ) {

					// render a thumbnail that is the max possible size for our layout

					var thumbnail = UIImage( data: drawing.thumbnail )!
					let size = CGSize( width: round(thumbnail.size.width * thumbnailHeight / thumbnail.size.height), height: thumbnailHeight )
					let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
					thumbnail = thumbnail.imageByScalingToSize(size, contentMode: .ScaleAspectFit, scale: 0)

					UIGraphicsBeginImageContextWithOptions(size, true, 0)

					self.thumbnailBackgroundColor.set()
					UIRectFillUsingBlendMode(rect, kCGBlendModeNormal)

					thumbnail.drawAtPoint(CGPoint.zeroPoint, blendMode: kCGBlendModeMultiply, alpha: 1)
					thumbnail = UIGraphicsGetImageFromCurrentImageContext()
					UIGraphicsEndImageContext()

					// we're done - add to icon cache and finish
					cache.setObject(thumbnail, forKey: drawing.uuid)

					dispatch_main {
						// only assign if the cell wasn't recycled while we rendered
						if galleryCell.drawing === drawing {
							// animate, because we had to wait for rendering to complete
							galleryCell.setThumbnail(thumbnail, animate: true)
						}
					}
				}
			}

		} else {
			assertionFailure("Unable to vend a GalleryDrawing for index path")
		}
	}

	lazy var dateFormatter:NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
		dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
		return dateFormatter
	}()
}

// MARK: - GalleryViewController

class GalleryViewController : UIViewController, UITextFieldDelegate {

	@IBOutlet weak var collectionView: UICollectionView!

	var store:GalleryStore!
	weak var delegate:GalleryViewControllerDelegate?

	private var dataSource:GalleryCollectionViewDataSource!
	private var searchField = SquizitThemeSearchField(frame: CGRect.zeroRect )
	private var fixedHeaderView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
	private let fixedHeaderHeight:CGFloat = 60

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		self.title = "Gallery"
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.backgroundColor = SquizitTheme.galleryBackgroundColor()


		dataSource = GalleryCollectionViewDataSource(store: store, collectionView: collectionView )

		dataSource.editModeChanged = {
			[weak self] ( inEditMode:Bool ) -> Void in
			if let sself = self {
				if inEditMode {
					sself.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: sself, action: "onDoneEditing:")
				} else {
					sself.navigationItem.rightBarButtonItem = nil
				}
			}
		}

		dataSource.galleryDrawingTapped = {
			[weak self] ( drawing:GalleryDrawing, indexPath:NSIndexPath ) in
			if let sself = self {
				sself.showDetail( drawing, indexPath:indexPath )
			}
		}

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: "onClose:")


		//
		//	Create the fixed header view
		//

		searchField.delegate = self
		searchField.placeholder = "Who drew..."
		searchField.returnKeyType = UIReturnKeyType.Search
		searchField.addTarget(self, action: "searchTextChanged:", forControlEvents: UIControlEvents.EditingChanged)

		fixedHeaderView.addSubview(searchField)
		view.addSubview(fixedHeaderView)


		//
		//	Make room for fixed header
		//

		collectionView.contentInset = UIEdgeInsets(top: fixedHeaderHeight, left: 0, bottom: 0, right: 0)


		//
		//	Listen for keyboard did dismiss to resign first responder - this handles when user hits the 
		//	keyboard dismiss key. I want the search field to lose focus
		//

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidDismiss:", name: UIKeyboardDidHideNotification, object: nil)
	}

	private var suggestedItemWidth:CGFloat {
		if traitCollection.horizontalSizeClass == .Compact || traitCollection.verticalSizeClass == .Compact {
			return 160
		} else {
			return 256
		}
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let aspect:CGFloat = 360.0 / 300.0
		var suggestedItemWidth = self.suggestedItemWidth
		var suggestedItemSize = CGSize(width:suggestedItemWidth, height: suggestedItemWidth*aspect)
		var itemWidth = floor(view.bounds.width / round(view.bounds.width / suggestedItemSize.width))
		let itemHeight = round(suggestedItemSize.height)
		let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
		flowLayout.itemSize = CGSize(width:itemWidth, height:itemHeight)
		collectionView.reloadData()


		//	Layout the fixed-position header containing the search field
		let headerFrame = CGRect(x:0, y: self.topLayoutGuide.length, width: self.view.bounds.width, height: fixedHeaderHeight)
		fixedHeaderView.frame = headerFrame

		let bounds = fixedHeaderView.bounds
		let margin:CGFloat = 20
		let searchFieldHeight:CGFloat = searchField.intrinsicContentSize().height
		let searchFieldFrame = CGRect(x: margin, y: bounds.midY - searchFieldHeight/2, width: bounds.width-2*margin, height: searchFieldHeight)

		searchField.frame = searchFieldFrame
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showPageDetail" {
			if let detailVC = segue.destinationViewController as? GalleryDetailPageViewController {
				if let indexPath = sender as? NSIndexPath {
					detailVC.store = store
					detailVC.filterPredicate = dataSource.filterPredicate
					detailVC.initialIndex = indexPath.item
				} else {
					assertionFailure("Didn't pass indexPath")
				}
			} else {
				assertionFailure("coun't grab the detail vc from segue")
			}
		}
	}

	// MARK: IBActions

	dynamic func onClose(sender: AnyObject) {
		delegate?.galleryDidDismiss(self)
	}

	dynamic func onDoneEditing( sender:AnyObject ) {
		dataSource.editMode = false
	}

	// MARK: UITextFieldDelegate

	dynamic func searchTextChanged( sender:UITextField ) {
		if sender === searchField {
			artistFilter = searchField.text
		}
	}

	func textFieldShouldEndEditing(textField: UITextField) -> Bool {
		if textField === searchField {}
		return true
	}

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if textField === searchField {
			textField.resignFirstResponder()
		}
		return true
	}

	func textFieldDidEndEditing(textField: UITextField) {
		if textField === searchField {
			textField.resignFirstResponder()
		}
	}

	func textFieldShouldClear(textField: UITextField) -> Bool {
		if textField === searchField {
			textField.resignFirstResponder()
		}
		return true
	}

	// MARK: Keyboard Handling

	dynamic func keyboardDidDismiss( note:NSNotification ) {
		view.endEditing(true)
	}

	// MARK: Private

	func showDetail( drawing:GalleryDrawing, indexPath:NSIndexPath ) {
		self.performSegueWithIdentifier("showPageDetail", sender: indexPath)
	}

	var artistFilter:String = "" {
		didSet {

			if _debouncedArtistFilterApplicator == nil {
				_debouncedArtistFilterApplicator = debounce(0.1) {
					[weak self] () -> () in
					if let sself = self {
						sself.dataSource.artistNameFilter = sself.artistFilter
							.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
							.capitalizedStringWithLocale(NSLocale.currentLocale())
					}
				}
			}

			_debouncedArtistFilterApplicator!()
		}
	}

	var _debouncedArtistFilterApplicator:((()->())?)
}
