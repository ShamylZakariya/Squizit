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

- (NSString *)description {
	NSMutableArray *drawingIDs = [NSMutableArray array];
	for ( GalleryDrawing *drawing in self.drawings ) {
		[drawingIDs addObject:drawing.uuid];
	}

	return [NSString stringWithFormat:@"<GalleryArtist name:%@ drawings:%@>", self.name, [drawingIDs componentsJoinedByString:@","] ];
}

@dynamic name;
@dynamic drawings;

@end


#pragma mark -

@implementation GalleryDrawing

+ (instancetype) newInstanceInManagedObjectContext: (NSManagedObjectContext*) context
{
	GalleryDrawing *gd = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
	gd.uuid = [NSUUID UUID].UUIDString;
	return gd;
}

+ (NSString*) entityName {
	return @"GalleryDrawing";
}

- (NSString*) description {
	NSMutableArray *artistNames = [NSMutableArray array];
	for ( GalleryArtist *artist in self.artists ) {
		[artistNames addObject:artist.name];
	}

	return [NSString stringWithFormat:@"<GalleryDrawing id:%@ date: %@ starred: %@ numPlayers: %@ artists: %@>",
		self.uuid,
		[NSDate dateWithTimeIntervalSinceReferenceDate:self.date],
		(self.starred ? @"YES" : @"NO"),
		@(self.numPlayers),
		[artistNames componentsJoinedByString:@","]];
}


@dynamic thumbnail;
@dynamic match;
@dynamic numPlayers;
@dynamic starred;
@dynamic date;
@dynamic artists;
@dynamic uuid;
@dynamic thumbnailWidth;
@dynamic thumbnailHeight;


@end
