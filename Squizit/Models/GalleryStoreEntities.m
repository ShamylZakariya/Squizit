//
//  Artist.m
//  Squizit
//
//  Created by Shamyl Zakariya on 8/27/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

#import "GalleryStoreEntities.h"


@implementation GalleryArtist

+ (instancetype) newInstanceInManagedObjectContext: (NSManagedObjectContext*) context
{
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
}

+ (NSString*) entityName {
	return @"GalleryArtist";
}

@dynamic name;
@dynamic drawings;

@end


#pragma mark -

@implementation GalleryDrawing

+ (instancetype) newInstanceInManagedObjectContext: (NSManagedObjectContext*) context
{
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
}

+ (NSString*) entityName {
	return @"GalleryDrawing";
}


@dynamic thumbnail;
@dynamic match;
@dynamic numPlayers;
@dynamic starred;
@dynamic date;
@dynamic artists;

@end
