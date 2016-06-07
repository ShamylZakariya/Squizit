//
//  GalleryStore.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/27/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit
import CoreData

let GalleryStoreErrorDomain = "org.zakariya.Squizit.GalleryStore"
let GalleryStoreErrorCodeInitializationError = 0001

extension GalleryDrawing {

	var artistDisplayNames:String {
		var artistNames:[String] = []

		// NSOrderedSet doesn't support for in loop in swift, apparently
		artists.enumerateObjectsUsingBlock { artist, index, _ in
			artistNames.append(artist.name)
		}


		switch artistNames.count {
			case 0: return NSLocalizedString("Anonymous", comment: "No artist specified for gallery detail image")
			case 1: return artistNames[0]
			case 2: return artistNames[0] + " & " + artistNames[1]
			default:
				var str = artistNames[0]
				for i in 1 ..< artistNames.count {
					str += i < artistNames.count - 1 ? ", " : ", & "
					str += artistNames[i]
				}

				return str
		}
	}
}

class GalleryStore {

	/**
		Return first artist with the passed-in name.
		If no artist with this name, creates new Artist by this name and adds to store
	*/

	func loadArtist( name:String, create:Bool ) -> GalleryArtist? {
		let fr = NSFetchRequest()
		fr.entity = NSEntityDescription.entityForName(GalleryArtist.entityName(), inManagedObjectContext: self.managedObjectContext!)
		fr.predicate = NSPredicate(format: "name BEGINSWITH[cd] \"\(name)\"")

		let sd = NSSortDescriptor(key: "name", ascending: true)
		fr.sortDescriptors = [sd]

		do {
			if let results = try self.managedObjectContext?.executeFetchRequest(fr) {
				if !results.isEmpty {
					return results.first as! GalleryArtist?
				}
			}

		} catch let error as NSError {
			fatalError("GalleryStore::loadArtist error:\(error)")
		}

		// no such artist exists, so add and return

		if create {
			let newArtist = GalleryArtist.newInstanceInManagedObjectContext(self.managedObjectContext)
			newArtist.name = name

			self.save()

			return newArtist
		}

		return nil
	}

	/*
		return an array of GalleryArtist whos names start with `partialName
	*/
	func artists( partialName:String ) -> [GalleryArtist] {
		let fr = NSFetchRequest()
		fr.entity = NSEntityDescription.entityForName(GalleryArtist.entityName(), inManagedObjectContext: self.managedObjectContext!)
		fr.predicate = NSPredicate(format: "name BEGINSWITH[cd] \"\(partialName)\"")

		do {
			let results = try self.managedObjectContext?.executeFetchRequest(fr)
			return results as! [GalleryArtist]
		} catch let error as NSError {
			fatalError("GalleryStore::loadArtist error:\(error)")
		}

		return []
	}

	/**
		Return an array of all GalleryArtists added to this store
		NOTE: This is for testing purposes, a UI should use a NSFetchedResultsController
		to page result batch sizes efficiently
	*/
	func allArtists() -> [GalleryArtist] {

		let fr = NSFetchRequest()
		fr.entity = NSEntityDescription.entityForName(GalleryArtist.entityName(), inManagedObjectContext: self.managedObjectContext!)

		let sd = NSSortDescriptor(key: "name", ascending: true)
		fr.sortDescriptors = [sd]

		do {
			if let results = try self.managedObjectContext?.executeFetchRequest(fr) {
				return results as! [GalleryArtist]
			}
		} catch let error as NSError {
			fatalError("GalleryStore::allArtists error:\(error)")
		}

		return []
	}

	/**
		Return an array of all GalleryDrawings added to this store
		NOTE: This is for testing purposes, a UI should use a NSFetchedResultsController
		to page result batch sizes efficiently
	*/
	func allDrawings() -> [GalleryDrawing] {
		let fr = NSFetchRequest()
		fr.entity = NSEntityDescription.entityForName(GalleryDrawing.entityName(), inManagedObjectContext: self.managedObjectContext!)

		let sd = NSSortDescriptor(key: "date", ascending: true)
		fr.sortDescriptors = [sd]

		do {
			if let results = try self.managedObjectContext?.executeFetchRequest(fr) {
				return results as! [GalleryDrawing]
			}
		} catch let error as NSError {
			fatalError("GalleryStore::allDrawings error:\(error)")
		}

		return []
	}

	lazy var managedObjectModel: NSManagedObjectModel = {
	    let modelURL = NSBundle.mainBundle().URLForResource("GalleryStore", withExtension: "momd")
	    return NSManagedObjectModel(contentsOfURL: modelURL!)!
	}()

	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
	    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
	    // Create the coordinator and store

	    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
	    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("GalleryStore.sqlite")
	    var error: NSError? = nil
	    var failureReason = "There was an error creating or loading the application's saved data."
	    do {
			try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
		} catch var error1 as NSError {
			error = error1
	        coordinator = nil

	        // Report any error we got.
			/*
	        let dict = NSMutableDictionary()
	        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
	        dict[NSLocalizedFailureReasonErrorKey] = failureReason
	        dict[NSUnderlyingErrorKey] = error
			*/

			var dict = [NSObject:AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
			dict[NSLocalizedFailureReasonErrorKey] = failureReason
			dict[NSUnderlyingErrorKey] = error


			error = NSError(domain: GalleryStoreErrorDomain, code: GalleryStoreErrorCodeInitializationError, userInfo: dict)

	        // Replace this with code to handle the error appropriately.
	        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	        NSLog("Unresolved error \(error), \(error!.userInfo)")

	        abort()
	    } catch {
			fatalError()
		}
	    
	    return coordinator
	}()

	lazy var managedObjectContext: NSManagedObjectContext? = {
	    let coordinator = self.persistentStoreCoordinator
	    if coordinator == nil {
	        return nil
	    }
	    var managedObjectContext = NSManagedObjectContext()
	    managedObjectContext.persistentStoreCoordinator = coordinator
	    return managedObjectContext
	}()

	// MARK: - Core Data Saving support

	func save () {
	    if let moc = self.managedObjectContext {
	        var error: NSError? = nil
	        if moc.hasChanges {
				do {
					try moc.save()
				} catch let error1 as NSError {
					error = error1
					// Replace this implementation with code to handle the error appropriately.
					// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
					NSLog("Unresolved error \(error), \(error!.userInfo)")
					abort()
				}
			}
	    }
	}

	// MARK: Private

	private lazy var applicationDocumentsDirectory: NSURL = {
	    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		return urls[urls.count-1]
	}()



}