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


class GalleryStore {

	/**
		Return first artist with the passed-in name.
		If no artist with this name, creates new Artist by this name and adds to store
	*/

	func loadArtist( name:String, create:Bool ) -> GalleryArtist? {
		var fr = NSFetchRequest()
		fr.entity = NSEntityDescription.entityForName(GalleryArtist.entityName(), inManagedObjectContext: self.managedObjectContext)
		fr.predicate = NSPredicate(format: "name like[cd] \"\(name)\"")

		var sd = NSSortDescriptor(key: "name", ascending: true)
		fr.sortDescriptors = [sd]

		var error: NSError? = nil
		if let results = self.managedObjectContext?.executeFetchRequest(fr, error: &error ) {

			if !results.isEmpty {
				return results.first as GalleryArtist?
			}
		}

		// no such artist exists, so add and return

		if create {
			var newArtist = GalleryArtist.newInstanceInManagedObjectContext(self.managedObjectContext)
			newArtist.name = name

			self.save()

			return newArtist
		}

		return nil
	}

	lazy var managedObjectModel: NSManagedObjectModel = {
	    let modelURL = NSBundle.mainBundle().URLForResource("GalleryStore", withExtension: "momd")
	    return NSManagedObjectModel(contentsOfURL: modelURL)
	}()

	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
	    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
	    // Create the coordinator and store

	    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
	    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("GalleryStore.sqlite")
	    var error: NSError? = nil
	    var failureReason = "There was an error creating or loading the application's saved data."
	    if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
	        coordinator = nil

	        // Report any error we got.
	        let dict = NSMutableDictionary()
	        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
	        dict[NSLocalizedFailureReasonErrorKey] = failureReason
	        dict[NSUnderlyingErrorKey] = error
	        error = NSError.errorWithDomain(GalleryStoreErrorDomain, code: GalleryStoreErrorCodeInitializationError, userInfo: dict)

	        // Replace this with code to handle the error appropriately.
	        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	        NSLog("Unresolved error \(error), \(error!.userInfo)")

	        abort()
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
	        if moc.hasChanges && !moc.save(&error) {
	            // Replace this implementation with code to handle the error appropriately.
	            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	            NSLog("Unresolved error \(error), \(error!.userInfo)")
	            abort()
	        }
	    }
	}

	// MARK: Private

	private lazy var applicationDocumentsDirectory: NSURL = {
	    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		return urls.last as NSURL
	}()



}