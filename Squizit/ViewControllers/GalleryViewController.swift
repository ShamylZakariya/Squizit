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

// MARK: - GalleryCollectionViewDataSource

class GalleryCollectionViewDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UIScrollViewDelegate {

	private var _store:GalleryStore
	private var _collectionView:UICollectionView
	private var _thumbnailCompositorQueue = dispatch_queue_create("com.zakariya.squizit.GalleryThumbnailCompositorQueue", nil)
	private var _thumbnailBackgroundColor = SquizitTheme.thumbnailBackgroundColor()

	init( store:GalleryStore, collectionView:UICollectionView ) {
		_store = store
		_collectionView = collectionView

		super.init()

		_collectionView.dataSource = self
		_collectionView.delegate = self
	}

	var editMode:Bool = false {
		didSet {
			for cell in _collectionView.visibleCells() {
				(cell as GalleryCollectionViewCell).deleteButtonVisible = editMode
			}

			if let emc = editModeChanged {
				emc( inEditMode: editMode )
			}
		}
	}

	var editModeChanged:((inEditMode:Bool)->Void)?

	func didReceiveMemoryWarning() {
		_fetchedResultsController = nil
	}

	// MARK: UICollectionViewDataSource

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let info = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
		return info.numberOfObjects
	}

	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(GalleryCollectionViewCell.identifier(), forIndexPath: indexPath) as GalleryCollectionViewCell

		configureCell( cell, atIndexPath: indexPath )
		return cell
	}

	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}



	// MARK: UICollectionViewDelegate

	func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
		collectionView.deselectItemAtIndexPath(indexPath, animated: true)

		if !editMode {
			NSLog("didSelectItemAtIndexPath: %@", indexPath )
		}
	}

	// MARK: FetchedResultsController

	private var _fetchedResultsController:NSFetchedResultsController?
	var fetchedResultsController:NSFetchedResultsController {
		if _fetchedResultsController != nil {
			return _fetchedResultsController!
		}

		var fetchRequest = NSFetchRequest()
		fetchRequest.entity = NSEntityDescription.entityForName(GalleryDrawing.entityName(), inManagedObjectContext: _store.managedObjectContext! )

		fetchRequest.sortDescriptors = self.sortDescriptors

		if let predicate = self.filterPredicate {
			fetchRequest.predicate = predicate
		}

		fetchRequest.fetchBatchSize = 4 * 4

		_fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: _store.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsController!.delegate = self

		performFetch()

		return _fetchedResultsController!
	}

	/*
		setting artistNameFilter will update the filter predicate on the fetch request
	*/
	var artistNameFilter:String? {
		didSet {
			if artistNameFilter != oldValue {
				fetchedResultsController.fetchRequest.predicate = self.filterPredicate
				performFetch()
				_collectionView.reloadData()
			}
		}
	}

	private var sortDescriptors:[NSSortDescriptor] {
		return [
			NSSortDescriptor(key: "date", ascending: false)
		]
	}

	private var filterPredicate:NSPredicate? {
		if let filter = artistNameFilter {
			if countElements(filter) > 0 {
				// find artists whos names start with filter
				return NSPredicate(format: "SUBQUERY(artists, $artist, $artist.name BEGINSWITH[cd] \"\(filter)\").@count > 0")
			}
		}

		return nil
	}

	private func performFetch() {
		var error:NSError? = nil
		if !fetchedResultsController.performFetch(&error) {
			NSLog("Unable to execute fetch, error: %@", error!.localizedDescription )
			abort()
		}
	}

	func controllerWillChangeContent(controller: NSFetchedResultsController) {}

	func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		switch type {
			case .Insert:
				_collectionView.insertSections(NSIndexSet( index: sectionIndex ))
			case .Delete:
				_collectionView.deleteSections(NSIndexSet(index: sectionIndex))
			default:
				return
		}
	}

	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath) {
		switch type {
			case .Insert:
				_collectionView.insertItemsAtIndexPaths([newIndexPath])
			case .Delete:
				_collectionView.deleteItemsAtIndexPaths([indexPath])
			case .Update:
				if let cell = _collectionView.cellForItemAtIndexPath(indexPath) as? GalleryCollectionViewCell {
					configureCell(cell, atIndexPath: indexPath)
				}
			case .Move:
				_collectionView.moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath)
			default:
				return
		}
	}

	func controllerDidChangeContent(controller: NSFetchedResultsController) {}

	// MARK: UIScrollViewDelegate

	var onScrollViewDidScroll:(((scrollView:UIScrollView)->())?)
	func scrollViewDidScroll(scrollView: UIScrollView) {
		if let handler = onScrollViewDidScroll {
			handler( scrollView: scrollView )
		}
	}

	// MARK: Private

	private func configureCell( cell:GalleryCollectionViewCell, atIndexPath indexPath:NSIndexPath ) {
		let store = _store
		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			var artistNames:[String] = []
			for artist in drawing.artists {
				artistNames.append(artist.name)
			}

			cell.alpha = 0
			cell.namesLabel.text = (artistNames as NSArray).componentsJoinedByString(", ")
			cell.dateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))
			cell.deleteButtonVisible = self.editMode


			cell.onLongPress = {
				[weak self]
				(cell:GalleryCollectionViewCell)->() in
				if let sself = self {
					if !sself.editMode {
						sself.editMode = true
					}
				}
			}

			cell.onDeleteButtonTapped = {
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

					cell.imageView.image = thumbnail
					UIView.animateWithDuration(0.2, animations: { () -> Void in
						cell.alpha = 1
					})

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
	private let _fixedHeaderHeightRange = (min: CGFloat(60), max:CGFloat(60))
	private var _fixedHeaderHeight:CGFloat = 60

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		self.title = "Gallery"
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

		if _fixedHeaderHeightRange.max > _fixedHeaderHeightRange.min {
			_dataSource.onScrollViewDidScroll = {
				[weak self] ( scrollView:UIScrollView) in
				if let sself = self {
					sself.scrollViewDidScroll( scrollView )
				}
			}
		}

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: "onClose:")


		//
		//	Create the fixed header view
		//

		_searchField.delegate = self
		_searchField.placeholder = "Who drew..."
		_searchField.addTarget(self, action: "searchTextChanged:", forControlEvents: UIControlEvents.EditingChanged)

		_fixedHeaderView.addSubview(_searchField)
		view.addSubview(_fixedHeaderView)


		//
		//	Make room for fixed header
		//

		collectionView.contentInset = UIEdgeInsets(top: _fixedHeaderHeight + 20, left: 0, bottom: 0, right: 0)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		layoutFixedHeaderView()
		scrollViewDidScroll(collectionView)
	}

	override func didReceiveMemoryWarning() {
		_dataSource.didReceiveMemoryWarning()
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
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
			setArtistFilter(_searchField.text)
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

	// MARK: Private

	private var _currentArtistFilter:String = ""
	private var _debouncedArtistFilterApplicator:((()->())?)

	private func setArtistFilter( partialName:String ) {

		_currentArtistFilter = partialName
			.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
			.capitalizedStringWithLocale(NSLocale.currentLocale())

		if _debouncedArtistFilterApplicator == nil {
			_debouncedArtistFilterApplicator = debounce(0.5) {
				[weak self] () -> () in
				if let sself = self {
					sself._dataSource.artistNameFilter = sself._currentArtistFilter
				}
			}
		}

		_debouncedArtistFilterApplicator!()
	}


	private func layoutFixedHeaderView() {
		let headerFrame = CGRect(x:0, y: self.topLayoutGuide.length, width: self.view.bounds.width, height: _fixedHeaderHeight)
		_fixedHeaderView.frame = headerFrame

		let bounds = _fixedHeaderView.bounds
		let margin:CGFloat = 20
		let searchFieldHeight:CGFloat = _searchField.intrinsicContentSize().height
		let searchFieldFrame = CGRect(x: margin, y: bounds.midY - searchFieldHeight/2, width: bounds.width-2*margin, height: searchFieldHeight)

		_searchField.frame = searchFieldFrame
	}

	private func scrollViewDidScroll( scrollView:UIScrollView ) {
		let minScroll = -(self.topLayoutGuide.length + _fixedHeaderHeight)
		let offset = scrollView.contentOffset.y - minScroll
		let maxScroll = _fixedHeaderHeight
		let scale = 1 - min(max( offset/maxScroll, 0 ), 1 )
		_fixedHeaderHeight = _fixedHeaderHeightRange.min + scale * ( _fixedHeaderHeightRange.max - _fixedHeaderHeightRange.min )
		layoutFixedHeaderView()
	}

}
