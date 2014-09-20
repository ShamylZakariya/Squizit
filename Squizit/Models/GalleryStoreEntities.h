//
//  Artist.h
//  Squizit
//
//  Created by Shamyl Zakariya on 8/27/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GalleryDrawing;
@class GalleryArtist;

@interface GalleryArtist : NSManagedObject

+ (instancetype) newInstanceInManagedObjectContext: (NSManagedObjectContext*) context;
+ (NSString*) entityName;

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *drawings;
@end

@interface GalleryArtist (CoreDataGeneratedAccessors)

- (void)addDrawingsObject:(GalleryDrawing *)value;
- (void)removeDrawingsObject:(GalleryDrawing *)value;
- (void)addDrawings:(NSSet *)values;
- (void)removeDrawings:(NSSet *)values;

@end

#pragma mark -

@interface GalleryDrawing : NSManagedObject

+ (instancetype) newInstanceInManagedObjectContext: (NSManagedObjectContext*) context;
+ (NSString*) entityName;

@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSData * match;
@property (nonatomic) int16_t numPlayers;
@property (nonatomic) BOOL starred;
@property (nonatomic) NSTimeInterval date;
@property (nonatomic, retain) NSSet *artists;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic) int32_t thumbnailWidth;
@property (nonatomic) int32_t thumbnailHeight;
@end

@interface GalleryDrawing (CoreDataGeneratedAccessors)

- (void)addArtistsObject:(GalleryArtist *)value;
- (void)removeArtistsObject:(GalleryArtist *)value;
- (void)addArtists:(NSSet *)values;
- (void)removeArtists:(NSSet *)values;

@end
