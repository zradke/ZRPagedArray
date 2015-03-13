//
//  ZRPagedArrayController.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/4/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRPagedArrayController.h"
#import "ZRPagedArray.h"
#import <libkern/OSAtomic.h>

NSString *const ZRPagedArrayControllerErrorDomain = @"com.zachradke.pagedArrayController.errorDomain";
NSUInteger const ZRPagedArrayControllerErrorMissingDataSource = 899;

@interface ZRPagedArrayController ()
{
    OSSpinLock _spinLock;
}

@property (strong, nonatomic) NSMutableDictionary *loadingIdentifiersForPages;
@property (copy, nonatomic) void (^blockDataSource)(NSUInteger, ZRPagedArrayControllerRequestCompletionHandler);
@end

@implementation ZRPagedArrayController

#pragma mark - Lifecycle

+ (instancetype)controllerWithPagedArray:(ZRPagedArray *)pagedArray
{
    return [[self alloc] initWithPagedArray:pagedArray];
}

+ (instancetype)controllerWithPagedArray:(ZRPagedArray *)pagedArray objectRequestHandler:(void (^)(NSUInteger, ZRPagedArrayControllerRequestCompletionHandler))objectRequestHandler
{
    NSParameterAssert(objectRequestHandler);
    
    ZRPagedArrayController *controller = [[self alloc] initWithPagedArray:pagedArray];
    controller.blockDataSource = objectRequestHandler;
    
    return controller;
}

- (instancetype)initWithPagedArray:(ZRPagedArray *)pagedArray
{
    NSParameterAssert(pagedArray);
    
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _pagedArray = [pagedArray copy];
    _spinLock = OS_SPINLOCK_INIT;
    _loadingIdentifiersForPages = [NSMutableDictionary dictionary];
    _shouldLoadPagesAutomatically = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithPagedArray:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}


#pragma mark - Paged array vending

- (ZRPagedArray *)pagedArray
{
    return [_pagedArray copy];
}

- (NSUInteger)countOfPagedArray
{
    return _pagedArray.count;
}

- (NSIndexSet *)indexesOfObjectsInPagedArrayForPage:(NSUInteger)page
{
    return [_pagedArray indexesOfObjectsForPage:page];
}

- (id)objectInPagedArrayAtIndex:(NSUInteger)index
{
    NSUInteger currentPage = [_pagedArray pageForObjectIndex:index];
    
    [self _tryLoadingContentsForPage:currentPage];
    
    NSUInteger preloadMargin = MIN(self.automaticPreloadIndexMargin, _pagedArray.objectsPerPage);
    NSUInteger preloadIndex = MIN((index + preloadMargin), (_pagedArray.count - 1));
    NSUInteger preloadedPage = [_pagedArray pageForObjectIndex:preloadIndex];
    
    if (preloadedPage != NSNotFound && preloadedPage != currentPage)
    {
        [self _tryLoadingContentsForPage:preloadedPage];
    }
    
    return _pagedArray[index];
}


#pragma mark - Requesting content

- (BOOL)isLoadingObjectAtIndex:(NSUInteger)index
{
    NSUInteger page = [_pagedArray pageForObjectIndex:index];
    
    OSSpinLockLock(&_spinLock);
    BOOL isLoading = self.loadingIdentifiersForPages[@(page)] != nil;
    OSSpinLockUnlock(&_spinLock);
    
    return isLoading;
}

- (BOOL)loadObjectAtIndex:(NSUInteger)index
{
    return [self _loadContentsForPage:[_pagedArray pageForObjectIndex:index]];
}

- (BOOL)cancelLoadingObjectAtIndex:(NSUInteger)index
{
    NSUInteger page = [_pagedArray pageForObjectIndex:index];
    
    OSSpinLockLock(&_spinLock);
    
    BOOL success = NO;
    if (self.loadingIdentifiersForPages[@(page)])
    {
        [self.loadingIdentifiersForPages removeObjectForKey:@(page)];
        success = YES;
    }
    
    OSSpinLockUnlock(&_spinLock);
    
    return success;
}


#pragma mark - Private

- (void)_didReceiveMemoryWarning:(NSNotification __unused *)note
{
    // TODO: Add ability to flush out objects when memory is running low.
}

- (void)_tryLoadingContentsForPage:(NSUInteger)page
{
    if (self.shouldLoadPagesAutomatically && ![_pagedArray isContentSetForPage:page])
    {
        [self _loadContentsForPage:page];
    }
}

- (BOOL)_loadContentsForPage:(NSUInteger)page
{
    OSSpinLockLock(&_spinLock);
    BOOL isLoadingPage = self.loadingIdentifiersForPages[@(page)] != nil;
    OSSpinLockUnlock(&_spinLock);
    
    if (isLoadingPage)
    {
        return NO;
    }
    
    [self _notifyDelegateOnMainThreadInBlock:^(id<ZRPagedArrayControllerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(controller:willRequestObjectsForPage:)])
        {
            [delegate controller:self willRequestObjectsForPage:page];
        }
    }];
    
    // This identifier will help us ensure that the same completion handler is being executed as the one we are adding here.
    NSUUID *loadingIdentifier = [NSUUID UUID];
    
    __weak typeof(self) weakSelf = self;
    void (^completionHandler)(NSArray *, NSError *) = ^(NSArray *objectsOrNil, NSError *errorOrNil) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf _completeLoadingOfPage:page withObjects:objectsOrNil error:errorOrNil originalLoadingIdentifier:loadingIdentifier];
    };
    
    OSSpinLockLock(&_spinLock);
    id<ZRPagedArrayControllerDataSource> dataSource = self.dataSource;
    if (dataSource || self.blockDataSource)
    {
        self.loadingIdentifiersForPages[@(page)] = loadingIdentifier;
    }
    OSSpinLockUnlock(&_spinLock);
    
    if (dataSource)
    {
        [dataSource controller:self requestsObjectsForPage:page completionHandler:completionHandler];
        return YES;
    }
    else if (self.blockDataSource)
    {
        self.blockDataSource(page, completionHandler);
        return YES;
    }
    else
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Missing data source",
                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Missing a data source to load contents for page %ld.", (long)page]};
        NSError *error = [NSError errorWithDomain:ZRPagedArrayControllerErrorDomain
                                             code:ZRPagedArrayControllerErrorMissingDataSource
                                         userInfo:userInfo];
        
        [self _notifyDelegateOnMainThreadInBlock:^(id<ZRPagedArrayControllerDelegate> delegate) {
            if ([delegate respondsToSelector:@selector(controller:didChangeObjectsForPage:error:)])
            {
                [delegate controller:self didChangeObjectsForPage:page error:error];
            }
        }];
        
        return NO;
    }
}

- (void)_completeLoadingOfPage:(NSUInteger)page withObjects:(NSArray *)objects error:(NSError *)error originalLoadingIdentifier:(NSUUID *)originalLoadingIdentifier
{
    OSSpinLockLock(&_spinLock);
    NSUUID *loadingIdentifier = self.loadingIdentifiersForPages[@(page)];
    
    // This loading result is invalid because it was cancelled and another one has taken its place
    if (![loadingIdentifier isEqual:originalLoadingIdentifier])
    {
        OSSpinLockUnlock(&_spinLock);
        return;
    }
    
    [self.loadingIdentifiersForPages removeObjectForKey:@(page)];
    OSSpinLockUnlock(&_spinLock);
    
    if (objects && !error)
    {
        [_pagedArray setObjects:objects forPage:page];
    }
    else
    {
        [_pagedArray removeObjectsForPage:page];
    }
    
    [self _notifyDelegateOnMainThreadInBlock:^(id<ZRPagedArrayControllerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(controller:didChangeObjectsForPage:error:)])
        {
            [delegate controller:self didChangeObjectsForPage:page error:error];
        }
    }];
}

- (void)_notifyDelegateOnMainThreadInBlock:(void (^)(id<ZRPagedArrayControllerDelegate> delegate))block
{
    NSParameterAssert(block);
    
    id<ZRPagedArrayControllerDelegate> delegate = self.delegate;
    
    if (!delegate)
    {
        return;
    }
    
    if ([NSThread isMainThread])
    {
        block(delegate);
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(delegate);
        });
    }
}


@end
