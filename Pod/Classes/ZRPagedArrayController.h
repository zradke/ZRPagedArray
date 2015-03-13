//
//  ZRPagedArrayController.h
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/4/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  Error domain for ZRPagedArrayController errors.
 */
FOUNDATION_EXPORT NSString *const ZRPagedArrayControllerErrorDomain;

/**
 *  Error code when a ZRPagedArrayController is missing a data source to load objects when requested.
 */
FOUNDATION_EXPORT NSUInteger const ZRPagedArrayControllerErrorMissingDataSource;

/**
 *  Block passed by ZRPagedArrayController to its data source which is invoked with the result of an object request for a given page.
 *
 *  @param objectsOrNil An array of objects to populate the controller's paged array with, or nil to indicate an error occured.
 *  @param errorOrNil   An error to indicate that the request failed, or nil to indicate success. Note that if this is nil but nil is also passed for the objects, the request is still treated as a failure.
 */
typedef void(^ZRPagedArrayControllerRequestCompletionHandler)(NSArray *objectsOrNil, NSError *errorOrNil);

@class ZRPagedArray, ZRPagedArrayController;

/**
 *  Protocol which allows conformers to act as data sources for ZRPagedArrayController instances. These data sources are responsible for loading objects when requested, and notifying the controller when the loading is completed.
 */
@protocol ZRPagedArrayControllerDataSource <NSObject>
@required

/**
 *  Asks the receiver to load objects for the given page. The receiver then notifies the controller that it has completed loading by passing the loaded objects or error into the given completion handler block. The completion block can be invoked immediately or asynchronously. Note that the receiver is required to execute the completion handler at some point, or risk leaving the controller unable to request objects for the given page. The completion handler expects an array of objects with the correct number associated with the given page, or nil to indicate that loading failed. Similarly, if the completion handler is passed an error, any objects also passed to the handler are ignored. No guarantees are placed on what thread this method will be called.
 *
 *  @param controller        The controller requesting objects.
 *  @param page              The page of objects to load.
 *  @param completionHandler The completion handler which must be executed with the result of the object loading. This block accepts an array of objects and an error, both of which may be nil. This can be invoked on any thread.
 */
- (void)controller:(ZRPagedArrayController *)controller requestsObjectsForPage:(NSUInteger)page completionHandler:(ZRPagedArrayControllerRequestCompletionHandler)completionHandler;

@end

/**
 *  Protocol which allows conformers to respond to changes in ZCRPagedArrayController instances.
 */
@protocol ZRPagedArrayControllerDelegate <NSObject>
@optional

/**
 *  Notifies the receiver that the controller will request objects for the given page. This method is always executed on the main thread.
 *
 *  @param controller The controller who will request objects.
 *  @param page       The page being requested.
 */
- (void)controller:(ZRPagedArrayController *)controller willRequestObjectsForPage:(NSUInteger)page;

/**
 *  Notifies the receiver that the controller has either succeeded or failed in aquiring objects for the given page. This method is always executed on the main thread.
 *
 *  @param controller The controller whose content may have changed.
 *  @param page       The page with updated content.
 *  @param error      An error indicating that the controller has failed to load any objects for the given page. This may be nil but the controller may still have failed to aquire content for the given page depending on the data source implementation.
 */
- (void)controller:(ZRPagedArrayController *)controller didChangeObjectsForPage:(NSUInteger)page error:(NSError *)error;

@end

/**
 *  Controller object which manages aquiring content for a ZRPagedArray instance. To effectively utilize a controller instance, a data source must be supplied which can perform the necessary actions to acquire objects to populate the backing paged array. The controller can be configured to automatically request unloaded pages when the -objectInPagedArrayAtIndex: method is invoked using the shouldLoadPagesAutomatically and automaticPreloadIndexMargin properties.
 */
@interface ZRPagedArrayController : NSObject
{
    @protected
    ZRPagedArray *_pagedArray;
}

/**
 *  Convenience class factory for generating a paged array controller.
 *
 *  @param pagedArray The paged array which should back the controller. This must not be nil.
 *  @see -initWithPagedArray:
 *
 *  @return An initialized instance of the receiver.
 */
+ (instancetype)controllerWithPagedArray:(ZRPagedArray *)pagedArray;

/**
 *  Convenience class factory for generating a paged array controller with a block data source. Unlike traditional ZRPagedArrayController instances, ones with block data sources will retain their data source and only use the dataSource property as an override if it is set.
 *
 *  @param pagedArray           The paged array which should back the controller. This must not be nil.
 *  @param objectRequestHandler A block that will fetch objects for the requested page. This block will be repeatedly invoked with each page being requested. The block is copied and retained by the instance, so some caution should be taken to avoid creating retain cycles.
 *
 *  @return An initialized instance of the receiver with a block data source.
 */
+ (instancetype)controllerWithPagedArray:(ZRPagedArray *)pagedArray objectRequestHandler:(void (^)(NSUInteger page, ZRPagedArrayControllerRequestCompletionHandler completionHandler))objectRequestHandler;

/**
 *  Initializes the receiver with a copy of the given paged array. This is the designated initializer.
 *
 *  @param pagedArray The paged array which should back the controller. This object is copied and will have no effect on the receiver after initialization. This must not be nil.
 *
 *  @return An initialized instance of the receiver.
 */
- (instancetype)initWithPagedArray:(ZRPagedArray *)pagedArray NS_DESIGNATED_INITIALIZER;


@property (copy, nonatomic, readonly) ZRPagedArray *pagedArray;

/**
 *  The data source which will load content for the receiver. This must be set for the content loading methods to work.
 */
@property (weak, nonatomic) id<ZRPagedArrayControllerDataSource> dataSource;

/**
 *  The delegate which the receiver will notify when content is changed.
 */
@property (weak, nonatomic) id<ZRPagedArrayControllerDelegate> delegate;

/**
 *  YES to have -objectInPagedArrayAtIndex: automatically load unset pages. By default this is YES. Note that automatic page loading will only ask the dataSource to load unset pages. If a page needs to be reloaded or unset, the -loadObjectAtIndex: page should be manually invoked.
 */
@property (assign, nonatomic) BOOL shouldLoadPagesAutomatically;

/**
 *  If set to a non-zero value and shouldLoadPagesAutomatically is set to YES, -objectInPagedArrayAtIndex: will add this value to the requested index and attempt to pre-load the next page. See the notes of shouldLoadPagesAutomatically for caveats regarding automatic page loading. By default this is 0.
 */
@property (assign, nonatomic) NSUInteger automaticPreloadIndexMargin;

/**
 *  Requests the number of objects in the backing paged array.
 *
 *  @return The total number of objects represented by the controller.
 */
- (NSUInteger)countOfPagedArray;

/**
 *  Requests all indexes of objects for the given page.
 *
 *  @param page The page to request object indexes for.
 *
 *  @return An index set of object indexes for the given page.
 */
- (NSIndexSet *)indexesOfObjectsInPagedArrayForPage:(NSUInteger)page;

/**
 *  Acquires the object at the requested index in the backing paged array. If shouldLoadPagesAutomatically is set to YES and the requested index is not set in the backing paged array, the data source will be asked to load all objects for the page at the requested index.
 *
 *  @param index The index of the object being requested.
 *
 *  @return The object in the backing paged array at the requested index.
 */
- (id)objectInPagedArrayAtIndex:(NSUInteger)index;

/**
 *  Checks if the receiver is currently loading the page for the given index.
 *
 *  @param index The index to check if content is being loaded.
 *
 *  @return YES if the receiver is awaiting content for the given index, or NO otherwise.
 */
- (BOOL)isLoadingObjectAtIndex:(NSUInteger)index;

/**
 *  Asks the receiver to load content for the page at the given index. Note that this method will have no effect if loading is already occuring for the given index. This can be checked via the -isLoadingObjectAtIndex: method prior to invoking this method. However, if the page is not being loaded, then calling this method will ask the delegate to load content regardless of whether content already exists at the given index or not. This can be useful for forcing a controller to reload objects when automatic page loading is enabled.
 *
 *  @param index The object index to load content for.
 *
 *  @return YES if the receiver initiated a request for the object at the given index, or NO if it could not or if a request for the given index is currently executing.
 */
- (BOOL)loadObjectAtIndex:(NSUInteger)index;

/**
 *  Asks the receiver to cancel any requests for the object at the given index. Note that cancelled requests will simply ignore any attempts to invoke the cancelled completion handler, but no error will be passed to the delegate.
 *
 *  @param index The object index to stop requesting content for.
 *
 *  @return YES if the receiver found and stopped a request for the object at the given index, or NO if no request was found.
 */
- (BOOL)cancelLoadingObjectAtIndex:(NSUInteger)index;

@end
