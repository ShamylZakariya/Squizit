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

class GalleryCollectionViewCell : UICollectionViewCell {

	class func identifier() -> String { return "GalleryCollectionViewCell" }


	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var deleteButton: UIImageView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var namesLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!

	var onLongPress:((( cell:GalleryCollectionViewCell )->())?)
	var onDeleteButtonTapped:((( cell:GalleryCollectionViewCell )->())?)

	var deleteButtonVisible:Bool = false {
		didSet {
			if deleteButtonVisible {
				self.showDeleteButton()
				self.wiggleCycle( .Start )
			} else {
				self.hideDeleteButton()
				self.wiggleCycle( .End )
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

		imageView.layer.shouldRasterize = true
		imageView.layer.shadowColor = UIColor.blackColor().CGColor
		imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		imageView.layer.shadowOpacity = 1
		imageView.layer.shadowRadius = 5

		let longPressGR = UILongPressGestureRecognizer(target: self, action: "longPress:")
		addGestureRecognizer(longPressGR)

		deleteButton.userInteractionEnabled = true
		deleteButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "deleteButtonTapped:"))
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		//wiggleCycle(.Restart) // this doesn't work
	}

	dynamic private func longPress( gr:UILongPressGestureRecognizer ) {
		switch gr.state {
			case UIGestureRecognizerState.Began:
				if let onLongPress = self.onLongPress {
					onLongPress( cell:self )
				}

			default: break;
		}
	}

	dynamic private func deleteButtonTapped( tr:UITapGestureRecognizer ) {
		if let handler = onDeleteButtonTapped {
			handler( cell:self )
		}
	}

	private func showDeleteButton() {
		let deleteButton = self.deleteButton
		UIView.animateWithDuration(0.2, animations: { () -> Void in
			deleteButton.hidden = false
			deleteButton.alpha = 1
		})
	}

	private func hideDeleteButton() {
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

	private let _wiggleVariance:NSTimeInterval = drand48()
	private let _wiggleCycleDuration:NSTimeInterval = 0.5
	private var _wiggling = false

	private enum WiggleCycle {
		case Start
		case Continue
		case End
		case Restart
	}

	private func wiggleCycle( phase:WiggleCycle ) {

		let wiggleAngle = M_PI * 0.00625
		let layer = self.layer
		let duration = _wiggleCycleDuration/2

		let nextCycle = { [weak self] ()->() in
			if let sself = self {
				sself.wiggleCycle(.Continue)
			}
		}

		switch phase {

			case .Start:
				if _wiggling {
					return
				}

				_wiggling = true
				delay(_wiggleVariance * duration, nextCycle )

			case .Continue:
				if !_wiggling {
					return
				}

				UIView.animateWithDuration( duration,
					delay: 0,
					options: UIViewAnimationOptions.AllowUserInteraction,
					animations: { () -> Void in
						layer.transform = CATransform3DMakeRotation(CGFloat(-wiggleAngle), 0, 0, 1)
						return
					},
					completion: {
						(complete:Bool) -> Void in

						UIView.animateWithDuration( duration,
							delay: 0,
							options: UIViewAnimationOptions.AllowUserInteraction,
							animations: { () -> Void in
								layer.transform = CATransform3DMakeRotation(CGFloat(+wiggleAngle), 0, 0, 1)
								return
							},
							completion: {
								(complete:Bool) -> Void in
								nextCycle()
							})

					})


			case .End:
				if !_wiggling {
					return
				}

				_wiggling = false
				layer.removeAllAnimations()
				UIView.animateWithDuration( duration, animations: {
					layer.transform = CATransform3DIdentity
				})

			case .Restart:
				_wiggling = false
				layer.removeAllAnimations()
				wiggleCycle(.Start)
		}
	}
}

// MARK: - GalleryOverviewCollectionViewDataSource

class GalleryCollectionViewDataSource : BasicGalleryCollectionViewDataSource {

	private var _thumbnailCompositorQueue = dispatch_queue_create("com.zakariya.squizit.GalleryThumbnailCompositorQueue", nil)
	private var _thumbnailBackgroundColor = SquizitTheme.thumbnailBackgroundColor()

	override init( store:GalleryStore, collectionView:UICollectionView ) {
		super.init(store: store, collectionView:collectionView)
	}

	var editMode:Bool = false {
		didSet {
			for cell in collectionView.visibleCells() {
				(cell as GalleryCollectionViewCell).deleteButtonVisible = editMode
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
					if countElements(filter) > 0 {
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
		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			var galleryCell = cell as GalleryCollectionViewCell
			galleryCell.namesLabel.text = drawing.artistDisplayNames
			galleryCell.dateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))
			galleryCell.deleteButtonVisible = self.editMode

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

			//
			//	Now, we have to render the thumbnail - it comes from the store as a transparent PNG, 
			//	with pen/brush strokes in black, and eraser in white. We need to multiply composite
			//	it over the paper texture to make a viable thumbnail image
			//

			dispatch_async( _thumbnailCompositorQueue ) {

				var thumbnail = UIImage( data: drawing.thumbnail )
				let size = thumbnail.size
				let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
				UIGraphicsBeginImageContextWithOptions(size, true, 0)

				self._thumbnailBackgroundColor.set()
				UIRectFillUsingBlendMode(rect, kCGBlendModeNormal)

				thumbnail.drawAtPoint(CGPoint(x: 0, y: 0), blendMode: kCGBlendModeMultiply, alpha: 1)

				thumbnail = UIGraphicsGetImageFromCurrentImageContext()
				UIGraphicsEndImageContext()

				dispatch_async(dispatch_get_main_queue() ) {
					galleryCell.imageView.image = thumbnail
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
		_dateFormatter!.dateStyle = NSDateFormatterStyle.ShortStyle
		return _dateFormatter!
	}
}

// MARK: - GalleryViewController

class GalleryViewController : UIViewController, UITextFieldDelegate {

	@IBOutlet weak var collectionView: UICollectionView!

	var store:GalleryStore!
	weak var delegate:GalleryViewControllerDelegate?
	private var _dataSource:GalleryCollectionViewDataSource!

	private var _searchField = SquizitThemeSearchField(frame: CGRect.zeroRect )
	private var _fixedHeaderView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
	private let _fixedHeaderHeight:CGFloat = 60

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

	dynamic private func onClose(sender: AnyObject) {
		delegate?.galleryDidDismiss(self)
	}

	dynamic private func onDoneEditing( sender:AnyObject ) {
		_dataSource.editMode = false
	}

	// MARK: UITextFieldDelegate

	dynamic private func searchTextChanged( sender:UITextField ) {
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

	private func showDetail( drawing:GalleryDrawing, indexPath:NSIndexPath ) {
		self.performSegueWithIdentifier("showDetail", sender: indexPath)
	}

	private var artistFilter:String = "" {
		didSet {

			if _debouncedArtistFilterApplicator == nil {
				_debouncedArtistFilterApplicator = debounce(0.5) {
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

	private var _debouncedArtistFilterApplicator:((()->())?)
}
