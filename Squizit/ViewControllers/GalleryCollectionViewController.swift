//
//  GalleryCollectionViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/29/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

protocol GalleryCollectionViewControllerDelegate : class {

	func galleryCollectionViewDidDismiss( galleryCollectionView:GalleryCollectionViewController )

}

class GalleryCollectionViewCell : UICollectionViewCell {

	class func identifier() -> String { return "GalleryCollectionViewCell" }


	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var namesLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!

	override func awakeFromNib() {
		self.clipsToBounds = false
		imageView.layer.shadowColor = UIColor.blackColor().CGColor
		imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
		imageView.layer.shadowOpacity = 1
		imageView.layer.shadowRadius = 5
	}
}

class GalleryCollectionViewController : UICollectionViewController, UICollectionViewDataSource, UICollectionViewDelegate {

	var store:GalleryStore!
	weak var delegate:GalleryCollectionViewControllerDelegate?

	private var _thumbnailCompositorQueue = dispatch_queue_create("com.zakariya.squizit.GalleryThumbnailCompositorQueue", nil)
	private var _thumbnailBackgroundColor = SquizitTheme.thumbnailBackgroundColor()

	private var _dateFormatter:NSDateFormatter?
	var dateFormatter:NSDateFormatter {
		if _dateFormatter != nil {
			return _dateFormatter!
		}

		_dateFormatter = NSDateFormatter()
		_dateFormatter!.timeStyle = NSDateFormatterStyle.ShortStyle
		_dateFormatter!.dateStyle = NSDateFormatterStyle.ShortStyle
		return _dateFormatter!
	}

	private var _fetchedResultsController:NSFetchedResultsController?
	var fetchedResultsController:NSFetchedResultsController {
		if _fetchedResultsController != nil {
			return _fetchedResultsController!
		}

		var fetchRequest = NSFetchRequest()
		fetchRequest.entity = NSEntityDescription.entityForName(GalleryDrawing.entityName(), inManagedObjectContext: store.managedObjectContext )

		fetchRequest.sortDescriptors = self.sortDescriptors

		if let predicate = self.filterPredicate {
			fetchRequest.predicate = predicate
		}

		fetchRequest.fetchBatchSize = 4 * 4

		_fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: store.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

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

	// MARK: UICollectionViewController

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		self.title = "Gallery"
	}

	override func viewDidLoad() {
		runFetch()

		collectionView.backgroundColor = SquizitTheme.galleryBackgroundColor()
		collectionView.delegate = self
		collectionView.dataSource = self
	}

	override func didReceiveMemoryWarning() {
		_fetchedResultsController = nil
	}


	// MARK: UICollectionViewDataSource

	override func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int {
		return 1
	}

	override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(GalleryCollectionViewCell.identifier(), forIndexPath: indexPath) as GalleryCollectionViewCell

		configureCell( cell, atIndexPath: indexPath )
		return cell
	}

	override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
		let info = self.fetchedResultsController.sections[section] as NSFetchedResultsSectionInfo
		return info.numberOfObjects
	}

	// MARK: UICollectionViewDelegate

	override func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
		NSLog("didSelectItemAtIndexPath: %@", indexPath )
		collectionView.deselectItemAtIndexPath(indexPath, animated: true)
	}

	// MARK: IBActions

	@IBAction func onDone(sender: AnyObject) {
		delegate?.galleryCollectionViewDidDismiss(self)
	}

	// MARK: Private

	private func runFetch() {
		var error:NSError? = nil
		if !fetchedResultsController.performFetch(&error) {
			NSLog("Unable to execute fetch, error: %@", error!.localizedDescription )
			abort()
		}
	}

	private func configureCell( cell:GalleryCollectionViewCell, atIndexPath indexPath:NSIndexPath ) {
		if let drawing = self.fetchedResultsController.objectAtIndexPath(indexPath) as? GalleryDrawing {

			var artistNames:[String] = []
			for artist in drawing.artists {
				artistNames.append(artist.name)
			}

			cell.containerView.alpha = 0
			cell.namesLabel.text = (artistNames as NSArray).componentsJoinedByString(", ")
			cell.dateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: drawing.date))

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
						cell.containerView.alpha = 1
					})

				}
			}

		} else {
			assertionFailure("Unable to vend a GalleryDrawing for index path")
		}
	}
}