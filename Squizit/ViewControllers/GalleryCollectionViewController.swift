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
			} else {
				self.hideDeleteButton()
			}
		}
	}

	override func awakeFromNib() {
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
		UIView.animateWithDuration(0.2, animations: { () -> Void in
			self.deleteButton.hidden = false
			self.deleteButton.alpha = 1
		})

		_wiggleDelay = drand48() * _wiggleCycleDuration
		self.wiggleCycle()
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

		self.wiggleCycle() // returns to zero point
	}

	private var _wiggleDelay:NSTimeInterval = 0
	private let _wiggleCycleDuration = 0.75
	private var _wiggling = false

	private func wiggleCycle() {

		let wiggleAngle = M_PI * 0.00625
		let layer = self.layer

		if self.deleteButtonVisible {
			if !_wiggling {
				_wiggling = true
				UIView.animateKeyframesWithDuration( _wiggleCycleDuration,
					delay: _wiggleDelay,
					options: UIViewKeyframeAnimationOptions.AllowUserInteraction | UIViewKeyframeAnimationOptions.CalculationModeCubic,
					animations: {
						() -> Void in

						UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5, animations: {
							() -> Void in
							layer.transform = CATransform3DMakeRotation(CGFloat(-wiggleAngle), 0, 0, 1)
						})

						UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: {
							() -> Void in
							layer.transform = CATransform3DMakeRotation(CGFloat(+wiggleAngle), 0, 0, 1)
						})

					},
					completion: {
						[weak self] ( complete:Bool ) -> Void in
						if let sself = self {
							sself._wiggleDelay = 0
							sself._wiggling = false
							sself.wiggleCycle()
						}
					});
			}
		} else {
			_wiggling = false
			UIView.animateWithDuration( _wiggleCycleDuration/2, animations: {
				layer.transform = CATransform3DIdentity
			})
		}
	}
}

// MARK: - GalleryCollectionViewDataSource

class GalleryCollectionViewDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

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

	func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int {
		return 1
	}

	func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(GalleryCollectionViewCell.identifier(), forIndexPath: indexPath) as GalleryCollectionViewCell

		configureCell( cell, atIndexPath: indexPath )
		return cell
	}

	func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
		let info = self.fetchedResultsController.sections[section] as NSFetchedResultsSectionInfo
		return info.numberOfObjects
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
		fetchRequest.entity = NSEntityDescription.entityForName(GalleryDrawing.entityName(), inManagedObjectContext: _store.managedObjectContext )

		fetchRequest.sortDescriptors = self.sortDescriptors

		if let predicate = self.filterPredicate {
			fetchRequest.predicate = predicate
		}

		fetchRequest.fetchBatchSize = 4 * 4

		_fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: _store.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsController!.delegate = self

		var error:NSError? = nil
		if !_fetchedResultsController!.performFetch(&error) {
			NSLog("Unable to execute fetch, error: %@", error!.localizedDescription )
			abort()
		}

		return _fetchedResultsController!
	}

	var sortDescriptors:[NSSortDescriptor] {
		return [
			NSSortDescriptor(key: "date", ascending: true)
		]
	}

	var filterPredicate:NSPredicate? {
		return nil
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

// MARK: - GalleryCollectionViewController

class GalleryCollectionViewController : UICollectionViewController {

	var store:GalleryStore!
	weak var delegate:GalleryViewControllerDelegate?
	private var _dataSource:GalleryCollectionViewDataSource!


	// MARK: UICollectionViewController

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		self.title = "Gallery"
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.backgroundColor = SquizitTheme.galleryBackgroundColor()

		_dataSource = GalleryCollectionViewDataSource(store: store, collectionView: collectionView)
		_dataSource.editModeChanged = {
			[unowned self] ( inEditMode:Bool ) -> Void in

			if inEditMode {
				self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "onDoneEditing:")
			} else {
				self.navigationItem.rightBarButtonItem = nil
			}
		}
	}

	override func didReceiveMemoryWarning() {
		_dataSource.didReceiveMemoryWarning()
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	// MARK: IBActions

	@IBAction func onClose(sender: AnyObject) {
		delegate?.galleryDidDismiss(self)
	}

	@IBAction func onDoneEditing( sender:AnyObject ) {
		_dataSource.editMode = false
	}
}
