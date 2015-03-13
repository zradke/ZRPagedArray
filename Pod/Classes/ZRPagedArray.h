//
//  ZRPagedArray.h
//  ZRPagedArray
//
//  Created by Zach Radke on 3/3/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Heavily modified version of [AWPagedArray](https://github.com/MrAlek/AWPagedArray) to support much larger object counts. All instances of ZRPagedArray are mutable, but are initialized with a static total object count and number of objects per page. However, the actual contents of the array can be modified by setting pages of content.
 *
 *  ZRPagedArray supports NSCopying, NSFastEnumeration, and NSSecureCoding. Note that the implementation of NSFastEnumeration prevents the receiver from being mutated while enumerating. The implementation of NSSecureCoding relies on the given placeholder object and all contents to also support NSCoding or NSSecureCoding.
 */
@interface ZRPagedArray : NSObject <NSCopying, NSFastEnumeration, NSSecureCoding>

/**
 *  Designated initializer.
 *
 *  @param totalCount        The total number of objects that the receiver should contain.
 *  @param objectsPerPage    The number of objects per page. Note that if the total count is not divisible by the objects per page, the last page will be the remainder.
 *  @param placeholderObject An optional placeholder object that is returned if an index is accessed whose content has not been set. If nil, [NSNull null] will be used.
 *
 *  @return An initialized receiver.
 */
- (instancetype)initWithCount:(NSUInteger)totalCount objectsPerPage:(NSUInteger)objectsPerPage placeholderObject:(id)placeholderObject NS_DESIGNATED_INITIALIZER;

/**
 *  The total count of the receiver.
 */
@property (assign, nonatomic, readonly) NSUInteger count;

/**
 *  The maximum number of objects per page.
 */
@property (assign, nonatomic, readonly) NSUInteger objectsPerPage;

/**
 *  The number of pages in the receiver.
 */
@property (assign, nonatomic, readonly) NSUInteger pageCount;

/**
 *  The placeholder object returned when no content is loaded.
 */
@property (strong, nonatomic, readonly) id placeholderObject;

/**
 *  Retrieves an object for the given index.
 *
 *  @param index The index to retrieve. This must be less than the count of the receiver, or an exception will be thrown.
 *
 *  @return The object at the given index if it has been set, or the placeholderObject if it has not.
 */
- (id)objectAtIndex:(NSUInteger)index;
- (id)objectAtIndexedSubscript:(NSUInteger)index;

/**
 *  Sets the contents of the given page, mutating the receiver. The contents must contain the correct number of objects for the requested page and the page must be less than the pageCount or an exception will be thrown. Note that this method may be called multiple times, and each time will change the contents of the receiver.
 *
 *  @param objects The objects to set on the given page. The count of this array must match the receiver's expectations.
 *  @param page    The page to set the contents on. This must be a valid page index.
 */
- (void)setObjects:(NSArray *)objects forPage:(NSUInteger)page;

/**
 *  Unsets the contents of the given page, mutating the receiver. This method may be called on an empty page, but will have no effect.
 *
 *  @param page The page to remove the contents of. This must be a valid page index.
 */
- (void)removeObjectsForPage:(NSUInteger)page;

/**
 *  Checks if the given page has it's content set via the -setObjects:forPage: method. The requested page must be a valid page index or an exception will be thrown.
 *
 *  @param page The page to load content for. This must be a valid page index.
 *
 *  @return YES if the page has contents have been set, or NO if they have not.
 */
- (BOOL)isContentSetForPage:(NSUInteger)page;

/**
 *  Returns the page index for the given object index.
 *
 *  @param index The object index to query.
 *
 *  @return The page index if the object index is valid, or NSNotFound.
 */
- (NSUInteger)pageForObjectIndex:(NSUInteger)index;

/**
 *  Returns the indexes of objects associated with the given page.
 *
 *  @param page The page index to query.
 *
 *  @return The indexes of the page's objects, or nil if the page index is invalid.
 */
- (NSIndexSet *)indexesOfObjectsForPage:(NSUInteger)page;

/**
 *  Checks if the receiver has equal properties to those of the passed paged array.
 *
 *  @param pagedArray The paged array to check for equality.
 *
 *  @return YES if the receiver has equal properties to those of the given paged array, or NO if they are inequal.
 */
- (BOOL)isEqualToPagedArray:(ZRPagedArray *)pagedArray;

@end
