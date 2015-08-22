//
//  BasicGalleryCollectionViewDataSource.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class BasicGalleryCollectionViewDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UIScrollViewDelegate {

	private var _store:GalleryStore
	private var _collectionView:UICollectionView

	weak var scrollDelegate:UIScrollViewDelegate?

	init( store:GalleryStore, collectionView:UICollectionView ) {
		_store = store
		_collectionView = collectionView

		super.init()

		_collectionView.dataSource = self
		_collectionView.delegate = self
	}

	// your view controller should forward didReceiveMemoryWarning to here
	func didReceiveMemoryWarning() {
		_fetchedResultsController = nil
	}

	var store:GalleryStore { return _store }
	var collectionView:UICollectionView { return _collectionView }
	var cellIdentifier:String {
		assertionFailure("Subclasses must override cellIdentifier")
		return ""
	}

	var count:Int {
		let info = self.fetchedResultsController.sections![0] as! NSFetchedResultsSectionInfo
		return info.numberOfObjects
	}

	// MARK: - UICollectionViewDataSource

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.count
	}

	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
		configureCell( cell, atIndexPath: indexPath )
		return cell
	}

	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}

	// MARK: - FetchedResultsController

	private var _fetchedResultsController:NSFetchedResultsController?
	var fetchedResultsController:NSFetchedResultsController {
		if _fetchedResultsController != nil {
			return _fetchedResultsController!
		}

		var fetchRequest = NSFetchRequest()
		fetchRequest.entity = NSEntityDescription.entityForName(GalleryDrawing.entityName(), inManagedObjectContext: _store.managedObjectContext! )

		fetchRequest.sortDescriptors = self.sortDescriptors
		fetchRequest.fetchBatchSize = fetchBatchSize
		if let predicate = self.filterPredicate {
			fetchRequest.predicate = predicate
		}

		_fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: _store.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsController!.delegate = self

		performFetch()

		return _fetchedResultsController!
	}

	var fetchBatchSize:Int {
		assertionFailure("Subclasses must override fetchBatchSize" )
		return 0
	}

	var sortDescriptors:[NSSortDescriptor] = [NSSortDescriptor(key: "date", ascending: false)] {
		didSet {
			if _fetchedResultsController != nil {
				fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors
				performFetch()
				_collectionView.reloadData()
			}
		}
	}

	var filterPredicate:NSPredicate? {
		didSet {
			if _fetchedResultsController != nil {
				fetchedResultsController.fetchRequest.predicate = filterPredicate
				performFetch()
				_collectionView.reloadData()
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

	// MARK: - NSFetchedResultsControllerDelegate

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

	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		switch type {
			case .Insert:
				_collectionView.insertItemsAtIndexPaths([newIndexPath!])
			case .Delete:
				_collectionView.deleteItemsAtIndexPaths([indexPath!])
			case .Update:
				if let cell = _collectionView.cellForItemAtIndexPath(indexPath!) {
					configureCell(cell, atIndexPath: indexPath!)
				}
			case .Move:
				_collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
			default:
				return
		}
	}

	func controllerDidChangeContent(controller: NSFetchedResultsController) {}

	// MARK: - UIScrollViewDelegate

	func scrollViewDidScroll(scrollView: UIScrollView) {
		scrollDelegate?.scrollViewDidScroll?(scrollView)
	}

	func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		scrollDelegate?.scrollViewDidEndDecelerating?(scrollView)
	}

	// MARK: - Methods for subclasses to override

	func configureCell( cell:UICollectionViewCell, atIndexPath indexPath:NSIndexPath ) {
		assertionFailure("Subclasses must implement configureCell")
	}
}