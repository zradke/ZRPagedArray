//
//  ZRPagedArray.m
//  ZRPagedArray
//
//  Created by Zach Radke on 3/3/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRPagedArray.h"
#import <libkern/OSAtomic.h>

@interface ZRPagedArray ()
{
    OSSpinLock _spinLock;
    unsigned long _mutations;
}

@property (strong, nonatomic) NSMutableDictionary *objectsForPages;

@end

@implementation ZRPagedArray

- (instancetype)initWithCount:(NSUInteger)totalCount objectsPerPage:(NSUInteger)objectsPerPage placeholderObject:(id)placeholderObject
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _count = totalCount;
    _objectsPerPage = objectsPerPage;
    _pageCount = ceil((double)_count / _objectsPerPage);
    _placeholderObject = placeholderObject ?: [NSNull null];
    
    _spinLock = OS_SPINLOCK_INIT;
    _mutations = 0;
    _objectsForPages = [NSMutableDictionary dictionary];
    
    return self;
}

- (instancetype)init
{
    return [self initWithCount:0 objectsPerPage:0 placeholderObject:nil];
}


#pragma mark - Public Interface

- (id)objectAtIndex:(NSUInteger)index
{
    if (index >= self.count)
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Index %ld is beyond the bounds of the paged array (0..%ld).", (long)index, (long)self.count];
    }
    
    OSSpinLockLock(&_spinLock);
    NSUInteger page = [self pageForObjectIndex:index];
    NSArray *contents = self.objectsForPages[@(page)];
    OSSpinLockUnlock(&_spinLock);
    
    id object;
    if (contents)
    {
        NSUInteger actualIndex = index - (page * self.objectsPerPage);
        object = contents[actualIndex];
    }
    else
    {
        object = self.placeholderObject;
    }
    
    return object;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return [self objectAtIndex:index];
}

- (void)setObjects:(NSArray *)objects forPage:(NSUInteger)page
{
    if (page >= self.pageCount)
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Page %ld is beyond the bounds of the paged array (0..%ld).", (long)page, (long)self.pageCount];
    }
    
    NSUInteger expectedCount = (page == self.pageCount - 1) ? (self.count % self.objectsPerPage) : self.objectsPerPage;
    if (objects.count != expectedCount)
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Incorrect number of objects for page %ld. Expected count of %ld but got %ld", (long)page, (long)expectedCount, (long)objects.count];
    }
    
    OSSpinLockLock(&_spinLock);
    self.objectsForPages[@(page)] = [objects copy];
    _mutations++; // For NSFastEnumeration book-keeping.
    OSSpinLockUnlock(&_spinLock);
}

- (void)removeObjectsForPage:(NSUInteger)page
{
    if (page >= self.pageCount)
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Page %ld is beyond the bounds of the paged array (0..%ld).", (long)page, (long)self.pageCount];
    }
    
    OSSpinLockLock(&_spinLock);
    [self.objectsForPages removeObjectForKey:@(page)];
    _mutations++; // For NSFastEnumeration book-keeping.
    OSSpinLockUnlock(&_spinLock);
}

- (BOOL)isContentSetForPage:(NSUInteger)page
{
    OSSpinLockLock(&_spinLock);
    BOOL isLoaded = self.objectsForPages[@(page)] != nil;
    OSSpinLockUnlock(&_spinLock);
    
    return isLoaded;
}

- (NSUInteger)pageForObjectIndex:(NSUInteger)index
{
    if (index >= self.count)
    {
        return NSNotFound;
    }
    else
    {
        return floor((double)index / self.objectsPerPage);
    }
}

- (NSIndexSet *)indexesOfObjectsForPage:(NSUInteger)page
{
    if (page >= self.pageCount)
    {
        return nil;
    }
    
    NSUInteger location = page * self.objectsPerPage;
    NSUInteger length = (page == (self.pageCount - 1)) ? (self.count % self.objectsPerPage) : self.objectsPerPage;
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(location, length)];
}


#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    else if (![object isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return [self isEqualToPagedArray:object];
}

- (BOOL)isEqualToPagedArray:(ZRPagedArray *)pagedArray
{
    if (!pagedArray)
    {
        return NO;
    }
    
    OSSpinLockLock(&_spinLock);
    BOOL equalObjectsForPages = [self.objectsForPages isEqualToDictionary:pagedArray.objectsForPages];
    OSSpinLockUnlock(&_spinLock);
    
    return self.count == pagedArray.count &&
           self.objectsPerPage == pagedArray.objectsPerPage &&
           [self.placeholderObject isEqual:pagedArray.placeholderObject] &&
           equalObjectsForPages;
}

- (NSUInteger)hash
{
    OSSpinLockLock(&_spinLock);
    NSUInteger hash = self.count ^ self.objectsPerPage ^ [self.placeholderObject hash] ^ [self.objectsForPages hash];
    OSSpinLockUnlock(&_spinLock);
    
    return hash;
}


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    typeof(self) copy = [[[self class] allocWithZone:zone] initWithCount:self.count
                                                          objectsPerPage:self.objectsPerPage
                                                       placeholderObject:self.placeholderObject];
    
    OSSpinLockLock(&_spinLock);
    copy.objectsForPages = [NSMutableDictionary dictionaryWithDictionary:self.objectsForPages];
    OSSpinLockUnlock(&_spinLock);
    
    return copy;
}


#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    // The first loop we set up the state
    if (state->state == 0)
    {
        state->state = 1;
        state->mutationsPtr = &_mutations;
        
        // We will store the last retrieved index in state.extra[0]
        state->extra[0] = 0;
    }
    
    // Each time this method is called we will start from the index we left off at
    NSUInteger currentIndex = state->extra[0];
    
    NSUInteger currentPage;
    NSArray *currentContents;
    NSUInteger relativeIndex;
    
    // We use the buffer to store our objects since we don't have any storage ourself that would work.
    NSUInteger count;
    for (count = 0; count < len && currentIndex < self.count; count++)
    {
        currentPage = [self pageForObjectIndex:currentIndex];
        
        // Because we're using state.mutationsPtr, we can access this directly without locking.
        currentContents = self.objectsForPages[@(currentPage)];
        
        if (currentContents)
        {
            relativeIndex = currentIndex - (currentPage * self.objectsPerPage);
            buffer[count] = currentContents[relativeIndex];
        }
        else
        {
            buffer[count] = self.placeholderObject;
        }
        
        currentIndex++;
    }
    
    // Remember that buffer is just given for convenience, but state.itemsPtr is the storage that actually matters.
    state->itemsPtr = buffer;
    
    // We also remember to update the state.extra[0] with the next index to retrieve.
    state->extra[0] = currentIndex;
    
    return count;
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt64:self.count forKey:NSStringFromSelector(@selector(count))];
    [aCoder encodeInt64:self.objectsPerPage forKey:NSStringFromSelector(@selector(objectsPerPage))];
    [aCoder encodeObject:self.placeholderObject forKey:NSStringFromSelector(@selector(placeholderObject))];
    
    if ([self.placeholderObject conformsToProtocol:@protocol(NSSecureCoding)] &&
        [[self.placeholderObject class] supportsSecureCoding])
    {
        [aCoder encodeObject:NSStringFromClass([self.placeholderObject class]) forKey:@"placeholderObjectClass"];
    }
    
    [aCoder encodeObject:self.objectsForPages forKey:NSStringFromSelector(@selector(objectsForPages))];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSUInteger count = [aDecoder decodeInt64ForKey:NSStringFromSelector(@selector(count))];
    NSUInteger objectsPerPage = [aDecoder decodeInt64ForKey:NSStringFromSelector(@selector(objectsPerPage))];
    
    id placeholder;
    NSString *placeholderObjectClass = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"placeholderObjectClass"];
    if (placeholderObjectClass)
    {
        placeholder = [aDecoder decodeObjectOfClass:NSClassFromString(placeholderObjectClass)
                                             forKey:NSStringFromSelector(@selector(placeholderObject))];
    }
    else
    {
        placeholder = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(placeholderObject))];
    }
    
    if (!(self = [self initWithCount:count objectsPerPage:objectsPerPage placeholderObject:placeholder]))
    {
        return nil;
    }
    
    _objectsForPages = [aDecoder decodeObjectOfClass:[NSMutableDictionary class]
                                              forKey:NSStringFromSelector(@selector(objectsForPages))];
    
    return self;
}

@end
