//
//  GalleryCollectionViewDataSource.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class GalleryCollectionViewDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

	private var _store:GalleryStore
	private var _collectionView:UICollectionView

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

	var sortDescriptors:[NSSortDescriptor] {
		return [
			NSSortDescriptor(key: "date", ascending: false)
		]
	}

	var filterPredicate:NSPredicate? {
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

	// MARK: Methods for subclasses to override

	func configureCell( cell:GalleryCollectionViewCell, atIndexPath indexPath:NSIndexPath ) {
		assertionFailure("Subclasses must implement configureCell")
	}
}