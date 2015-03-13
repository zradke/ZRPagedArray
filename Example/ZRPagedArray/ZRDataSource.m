//
//  ZRDataSource.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRDataSource.h"

NSUInteger const ZRDataSourceDefaultLoadDelay = 1.5;

@interface ZRDataSource ()
@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) NSMutableIndexSet *mutableLoadedIndexes;
@end

@implementation ZRDataSource

- (instancetype)initWithLoadDelay:(NSTimeInterval)loadDelay
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _loadDelay = loadDelay;
    _queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
    _mutableLoadedIndexes = [NSMutableIndexSet indexSet];
    
    return self;
}

- (instancetype)init
{
    return [self initWithLoadDelay:ZRDataSourceDefaultLoadDelay];
}

- (NSIndexSet *)loadedIndexes
{
    __block NSIndexSet *loadedIndexes;
    dispatch_sync(self.queue, ^{
        loadedIndexes = [self.mutableLoadedIndexes copy];
    });
    
    return loadedIndexes;
}

- (void)controller:(ZRPagedArrayController *)controller requestsObjectsForPage:(NSUInteger)page completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    NSIndexSet *indexes = [controller indexesOfObjectsInPagedArrayForPage:page];
    
    NSMutableArray *objects = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [objects addObject:@(idx + 1)];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.loadDelay * NSEC_PER_SEC)), self.queue, ^{
        completionHandler(objects, nil);
        [self.mutableLoadedIndexes addIndexes:indexes];
    });
}

@end
