//
//  GalleryCollectionViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/29/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

// MARK: - GalleryViewControllerDelegate

protocol GalleryViewControllerDelegate : class {

	func galleryDidDismiss( galleryViewController:AnyObject )

}

// MARK: - GalleryCollectionViewCell

let WigglePhaseDuration:NSTimeInterval = 0.2
let WiggleAngleMax = 0.75 * M_PI / 180.0

class GalleryCollectionViewCell : UICollectionViewCell {

	class func identifier() -> String { return "GalleryCollectionViewCell" }

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var deleteButton: UIImageView!
	@IBOutlet weak var imageView: ImagePresenterView!
	@IBOutlet weak var namesLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!

	@IBOutlet weak var topPaddingConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!

	var indexInCollection:Int = 0
	var thumbnailLoadAction:CancelableAction<UIImage>?

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

	override func awakeFromNib() {
		super.awakeFromNib()

		self.clipsToBounds = false
		deleteButton.alpha = 0
		deleteButton.hidden = true

		// for some reason I can't set Baskerville in IB
		namesLabel.font = UIFont(name: "Baskerville", size: namesLabel.font.pointSize)
		dateLabel.font = UIFont(name:"Baskerville-Italic", size: dateLabel.font.pointSize)

		// set background color of imageview to the thumbnail background to minimize flashing as images are lazily loaded
		imageView.backgroundColor = SquizitTheme.thumbnailBackgroundColor()
		imageView.contentMode = .Center

		// add shadows because we're a little skeumorphic here
		imageView.layer.shouldRasterize = true
		imageView.layer.shadowColor = UIColor.blackColor().CGColor
		imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		imageView.layer.shadowOpacity = 1
		imageView.layer.shadowRadius = 5

		addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "longPress:"))

		deleteButton.userInteractionEnabled = true
		deleteButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "deleteButtonTapped:"))

		// common initialization
		prepareForReuse()
	}

	override func prepareForReuse() {

		if let action = thumbnailLoadAction {
			action.cancel()
			thumbnailLoadAction = nil
		}

		// reset layer transform and nil the image
		layer.transform = CATransform3DIdentity
		layer.opacity = 1
		imageView.image = nil
	}

	dynamic func longPress( gr:UILongPressGestureRecognizer ) {
		switch gr.state {
			case UIGestureRecognizerState.Began:
				if let onLongPress = self.onLongPress {
					onLongPress( cell:self )
				}

			default: break;
		}
	}

	private var _deleting:Bool = false
	dynamic func deleteButtonTapped( tr:UITapGestureRecognizer ) {

		// flag that we're deleting - this halts the wiggle animation which would override our scale transform
		_deleting = true
		let layer = self.layer
		let maybeHandler = self.onDeleteButtonTapped

		UIView.animateWithDuration(0.2,
			animations: {
				[unowned self] () -> Void in
				let scale = CATransform3DMakeScale(0.1, 0.1, 1)
				layer.transform = CATransform3DConcat(layer.transform, scale)
				layer.opacity = 0
			}) {
				(complete:Bool) -> Void in
				if let handler = maybeHandler {
					handler( cell:self )
				}
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

	let _cycleOffset:NSTimeInterval = drand48() / 2
	var _phase:NSTimeInterval = 0
	var _wiggleAnimationDisplayLink:CADisplayLink?

	func startWiggling() {
		_wiggleAnimationDisplayLink = CADisplayLink(target: self, selector: "updateWiggleAnimation")
		_wiggleAnimationDisplayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
	}

	dynamic func updateWiggleAnimation() {

		if _deleting {
			return
		}

		let now = NSDate().timeIntervalSinceReferenceDate
		let cycle = now / WigglePhaseDuration
		let sign = (indexInCollection % 2 == 0) ? +1.0 : -1.0
		let phase = sin(cycle * M_PI + _cycleOffset * M_PI ) * sign
		let angle = CGFloat(phase * WiggleAngleMax)
		let layer = self.layer
		UIView.performWithoutAnimation { () -> Void in
			layer.transform = CATransform3DMakeRotation( angle, 0, 0, 1)
		}
	}

	func stopWiggling() {
		if let displayLink = _wiggleAnimationDisplayLink {
			displayLink.invalidate()
			_wiggleAnimationDisplayLink = nil
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

	var _thumbnailCompositorQueue = dispatch_queue_create("com.zakariya.squizit.GalleryThumbnailCompositorQueue", nil)
	var _thumbnailBackgroundColor = SquizitTheme.thumbnailBackgroundColor()
	var _renderedIconCache = NSCache()

	override init( store:GalleryStore, collectionView:UICollectionView ) {
		super.init(store: store, collectionView:collectionView)
	}

	var editMode:Bool = false {
		didSet {
			for cell in collectionView.visibleCells() {
				(cell as! GalleryCollectionViewCell).deleteButtonVisible = editMode
			}

			if let emc = editModeChanged {
				emc( inEditMode: editMode )
			}
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
						predicate = NSPredicate(format: "SUBQUERY(artists, $artist, $artist.name BEGINSWITH[cd] \"\(filter)\").@count > 0")
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
			if let handler = galleryDrawingTapped {
				if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {
					handler( drawing: drawing, indexPath: indexPath )
				}
			}
		}
	}

	override func configureCell( cell:UICollectionViewCell, atIndexPath indexPath:NSIndexPath ) {
		let store = self.store
		let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
		let itemSize = flowLayout.itemSize
		let thumbnailHeight = round(itemSize.height * 0.8)

		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			var galleryCell = cell as! GalleryCollectionViewCell
			galleryCell.namesLabel.text = drawing.artistDisplayNames
			galleryCell.dateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))
			galleryCell.deleteButtonVisible = self.editMode

			// set the index in collection to aid in wiggle cycle direction (odd/even wiggle in different directions)
			galleryCell.indexInCollection = indexPath.item

			// use the thumbnail's size to set the cell image size & aspect ratio
			let thumbnailActualHeight = CGFloat(drawing.thumbnailHeight)
			let thumbnailActualWidth = CGFloat(drawing.thumbnailWidth)
			let thumbnailWidth = round(thumbnailActualWidth * (thumbnailHeight/thumbnailActualHeight))
			galleryCell.imageViewHeightConstraint.constant = thumbnailHeight
			galleryCell.imageViewWidthConstraint.constant = thumbnailWidth


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

					store.managedObjectContext?.deleteObject(drawing)
					store.save()

				}
			}

			let cache = _renderedIconCache
			if let renderedIcon = cache.objectForKey(drawing.uuid) as? UIImage {

				galleryCell.imageView.animate = false
				galleryCell.imageView.image = renderedIcon

			} else {

				let queue = _thumbnailCompositorQueue
				galleryCell.thumbnailLoadAction = CancelableAction<UIImage>(action: { (done, canceled) in

					dispatch_async( queue ) {

						let size = CGSize( width: thumbnailWidth, height: thumbnailHeight )
						let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

						var thumbnail = UIImage( data: drawing.thumbnail )!
						thumbnail = thumbnail.imageByScalingToSize(size, contentMode: .ScaleAspectFit, scale: 0)

						UIGraphicsBeginImageContextWithOptions(size, true, 0)

						self._thumbnailBackgroundColor.set()
						UIRectFillUsingBlendMode(rect, kCGBlendModeNormal)

						if !canceled() {
							thumbnail.drawAtPoint(CGPoint.zeroPoint, blendMode: kCGBlendModeMultiply, alpha: 1)
							thumbnail = UIGraphicsGetImageFromCurrentImageContext()
							UIGraphicsEndImageContext()

							// we're done - add to icon cache and finish
							cache.setObject(thumbnail, forKey: drawing.uuid)
							done( result:thumbnail )
						} else {
							UIGraphicsEndImageContext()
						}
					}
				}, done: { ( result:UIImage ) -> () in
					dispatch_main {
						galleryCell.imageView.animate = true
						galleryCell.imageView.image = result
					}
				})
			}

		} else {
			assertionFailure("Unable to vend a GalleryDrawing for index path")
		}
	}

	var _dateFormatter:NSDateFormatter?
	var dateFormatter:NSDateFormatter {
		if _dateFormatter != nil {
			return _dateFormatter!
		}

		_dateFormatter = NSDateFormatter()
		_dateFormatter!.timeStyle = NSDateFormatterStyle.ShortStyle
		_dateFormatter!.dateStyle = NSDateFormatterStyle.ShortStyle
		return _dateFormatter!
	}
}

// MARK: - GalleryViewController

class GalleryViewController : UIViewController, UITextFieldDelegate {

	@IBOutlet weak var collectionView: UICollectionView!

	var store:GalleryStore!
	weak var delegate:GalleryViewControllerDelegate?
	var _dataSource:GalleryCollectionViewDataSource!

	var _searchField = SquizitThemeSearchField(frame: CGRect.zeroRect )
	var _fixedHeaderView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
	let _fixedHeaderHeight:CGFloat = 60

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


		_dataSource = GalleryCollectionViewDataSource(store: store, collectionView: collectionView )

		_dataSource.editModeChanged = {
			[weak self] ( inEditMode:Bool ) -> Void in
			if let sself = self {
				if inEditMode {
					sself.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: sself, action: "onDoneEditing:")
				} else {
					sself.navigationItem.rightBarButtonItem = nil
				}
			}
		}

		_dataSource.galleryDrawingTapped = {
			[weak self] ( drawing:GalleryDrawing, indexPath:NSIndexPath ) in
			if let sself = self {
				sself.showDetail( drawing, indexPath:indexPath )
			}
		}

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: "onClose:")


		//
		//	Create the fixed header view
		//

		_searchField.delegate = self
		_searchField.placeholder = "Who drew..."
		_searchField.returnKeyType = UIReturnKeyType.Search
		_searchField.addTarget(self, action: "searchTextChanged:", forControlEvents: UIControlEvents.EditingChanged)

		_fixedHeaderView.addSubview(_searchField)
		view.addSubview(_fixedHeaderView)


		//
		//	Make room for fixed header
		//

		collectionView.contentInset = UIEdgeInsets(top: _fixedHeaderHeight + 20, left: 0, bottom: 0, right: 0)


		//
		//	Listen for keyboard did dismiss to resign first responder - this handles when user hits the 
		//	keyboard dismiss key. I want the search field to lose focus
		//

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidDismiss:", name: UIKeyboardDidHideNotification, object: nil)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		//	Layout the fixed-position header containing the search field
		let headerFrame = CGRect(x:0, y: self.topLayoutGuide.length, width: self.view.bounds.width, height: _fixedHeaderHeight)
		_fixedHeaderView.frame = headerFrame

		let bounds = _fixedHeaderView.bounds
		let margin:CGFloat = 20
		let searchFieldHeight:CGFloat = _searchField.intrinsicContentSize().height
		let searchFieldFrame = CGRect(x: margin, y: bounds.midY - searchFieldHeight/2, width: bounds.width-2*margin, height: searchFieldHeight)

		_searchField.frame = searchFieldFrame
	}

	override func didReceiveMemoryWarning() {
		_dataSource.didReceiveMemoryWarning()
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
			if let detailVC = segue.destinationViewController as? GalleryDetailViewController {
				if let indexPath = sender as? NSIndexPath {
					detailVC.store = store
					detailVC.filterPredicate = _dataSource.filterPredicate
					detailVC.initialIndexPath = indexPath
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
		_dataSource.editMode = false
	}

	// MARK: UITextFieldDelegate

	dynamic func searchTextChanged( sender:UITextField ) {
		if sender === _searchField {
			artistFilter = _searchField.text
		}
	}

	func textFieldShouldEndEditing(textField: UITextField) -> Bool {
		if textField === _searchField {}
		return true
	}

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if textField == _searchField {
			textField.resignFirstResponder()
		}
		return true
	}

	func textFieldDidEndEditing(textField: UITextField) {
		if textField == _searchField {
			textField.resignFirstResponder()
		}
	}

	func textFieldShouldClear(textField: UITextField) -> Bool {
		if textField == _searchField {
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
		self.performSegueWithIdentifier("showDetail", sender: indexPath)
	}

	var artistFilter:String = "" {
		didSet {

			if _debouncedArtistFilterApplicator == nil {
				_debouncedArtistFilterApplicator = debounce(0.1) {
					[weak self] () -> () in
					if let sself = self {
						sself._dataSource.artistNameFilter = sself.artistFilter
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
