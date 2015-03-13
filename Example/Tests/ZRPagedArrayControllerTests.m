//
//  ZRPagedArrayControllerTests.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/4/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ZRPagedArray/ZRPagedArray.h>
#import <ZRPagedArray/ZRPagedArrayController.h>

@interface ZRPagedArrayControllerTests : XCTestCase <ZRPagedArrayControllerDataSource, ZRPagedArrayControllerDelegate>
@property (copy, nonatomic) NSArray *contentsOverride;
@property (strong, nonatomic) NSError *contentsError;
@property (copy, nonatomic) void (^controllerDidChangePageContents)(NSUInteger page, NSError *error);
@end

@implementation ZRPagedArrayControllerTests

- (ZRPagedArrayController *)generateController
{
    ZRPagedArray *pagedArray = [[ZRPagedArray alloc] initWithCount:24 objectsPerPage:10 placeholderObject:nil];
    
    [pagedArray setObjects:@[@20, @21, @22, @23] forPage:2];
    
    ZRPagedArrayController *controller = [[ZRPagedArrayController alloc] initWithPagedArray:pagedArray];
    controller.dataSource = self;
    controller.delegate = self;
    
    return controller;
}

- (void)controller:(ZRPagedArrayController *)controller requestsObjectsForPage:(NSUInteger)page completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    XCTAssertNotNil(completionHandler);
    
    NSArray *contents = self.contentsOverride;
    NSError *error = self.contentsError;
    
    if (!contents)
    {
        NSIndexSet *indexes = [controller indexesOfObjectsInPagedArrayForPage:page];
        NSMutableArray *mutableContents = [NSMutableArray array];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [mutableContents addObject:@(idx)];
        }];
        contents = mutableContents;
    }
    
    // We dispatch so that the loading happens asynchronously
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completionHandler(contents, error);
    });
}

- (void)controller:(ZRPagedArrayController *)controller didChangeObjectsForPage:(NSUInteger)page error:(NSError *)error
{
    if (self.controllerDidChangePageContents)
    {
        self.controllerDidChangePageContents(page, error);
    }
}

- (void)tearDown
{
    self.contentsOverride = nil;
    self.contentsError = nil;
    self.controllerDidChangePageContents = nil;
    
    [super tearDown];
}

- (void)testInit
{
    ZRPagedArrayController *controller = [self generateController];
    
    XCTAssertNotNil(controller);
    XCTAssertTrue(controller.shouldLoadPagesAutomatically);
    XCTAssertEqual(controller.automaticPreloadIndexMargin, 0);
}

- (void)testInitImmutablePagedArray
{
    ZRPagedArray *pagedArray = [[ZRPagedArray alloc] initWithCount:24 objectsPerPage:10 placeholderObject:nil];
    ZRPagedArrayController *controller = [[ZRPagedArrayController alloc] initWithPagedArray:pagedArray];
    controller.delegate = self;
    
    __block BOOL didChangeContents = NO;
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        didChangeContents = YES;
    }];
    
    [pagedArray setObjects:@[@0, @1, @2, @3] forPage:2];
    
    XCTAssertFalse(didChangeContents);
}

- (void)testObjectAtIndex
{
    ZRPagedArrayController *controller = [self generateController];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], [NSNull null]);
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:20], @20);
}

- (void)testLoadObjectAtIndex
{
    XCTestExpectation *expect = [self expectationWithDescription:@"Delegate notified"];
    
    __block NSUInteger loadedPage = NSNotFound;
    __block NSError *loadError = nil;
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        loadedPage = page;
        loadError = error;
        [expect fulfill];
    }];
    
    ZRPagedArrayController *controller = [self generateController];
    controller.shouldLoadPagesAutomatically = NO;
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], [NSNull null]);
    
    XCTAssertTrue([controller loadObjectAtIndex:0]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], @0);
    XCTAssertEqual(loadedPage, 0);
    XCTAssertNil(loadError);
}

- (void)testLoadObjectAtIndexWithBlockDataSource
{
    ZRPagedArray *pagedArray = [[ZRPagedArray alloc] initWithCount:24 objectsPerPage:10 placeholderObject:nil];
    ZRPagedArrayController *controller = [ZRPagedArrayController controllerWithPagedArray:pagedArray objectRequestHandler:^(NSUInteger page, ZRPagedArrayControllerRequestCompletionHandler completionHandler) {
        NSIndexSet *indexes = [pagedArray indexesOfObjectsForPage:page];
        NSMutableArray *objects = [NSMutableArray array];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [objects addObject:@(idx * 10)];
        }];
        
        // We immediately execute the completion handler, meaning the content will be available as soon as it is requested.
        completionHandler(objects, nil);
    }];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:1], @10);
    
    controller.dataSource = self;
    controller.delegate = self;
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Delegate notified"];
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        [expect fulfill];
    }];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:11], [NSNull null]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:11], @11);
}

- (void)testAutomaticPageLoading
{
    XCTestExpectation *expect = [self expectationWithDescription:@"Delegate notified"];
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        [expect fulfill];
    }];
    
    ZRPagedArrayController *controller = [self generateController];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], [NSNull null]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], @0);
}

- (void)testAutomaticPageLoadingWithError
{
    XCTestExpectation *expect = [self expectationWithDescription:@"Delegate notified"];
    
    NSError *error = [NSError errorWithDomain:@"test.domain" code:2000 userInfo:nil];
    [self setContentsError:error];
    
    __block NSUInteger loadedPage = NSNotFound;
    __block NSError *loadError = nil;
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        loadedPage = page;
        loadError = error;
        [expect fulfill];
    }];
    
    ZRPagedArrayController *controller = [self generateController];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], [NSNull null]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqualObjects(loadError, error);
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], [NSNull null]);
}

- (void)testPreloading
{
    XCTestExpectation *expectPage0 = [self expectationWithDescription:@"Delegate notified of page 0."];
    XCTestExpectation *expectPage1 = [self expectationWithDescription:@"Delegate notified of page 1."];
    
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        if (page == 0)
        {
            [expectPage0 fulfill];
        }
        else if (page == 1)
        {
            [expectPage1 fulfill];
        }
    }];
    
    ZRPagedArrayController *controller = [self generateController];
    controller.automaticPreloadIndexMargin = 5;
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:5], [NSNull null]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:5], @5);
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:10], @10);
}

- (void)testIsLoadingPage
{
    XCTestExpectation *expect = [self expectationWithDescription:@"Delegate notified"];
    
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        [expect fulfill];
    }];
    
    ZRPagedArrayController *controller = [self generateController];
    controller.shouldLoadPagesAutomatically = NO;
    
    XCTAssertFalse([controller isLoadingObjectAtIndex:0]);
    
    [controller loadObjectAtIndex:0];
    
    XCTAssertTrue([controller isLoadingObjectAtIndex:0]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertFalse([controller isLoadingObjectAtIndex:0]);
}

- (void)testCancelLoadingPage
{
    XCTestExpectation *expect = [self expectationWithDescription:@"Delegate notified"];
    
    [self setControllerDidChangePageContents:^(NSUInteger page, NSError *error) {
        [expect fulfill];
    }];
    
    ZRPagedArrayController *controller = [self generateController];
    controller.shouldLoadPagesAutomatically = NO;
    
    XCTAssertFalse([controller isLoadingObjectAtIndex:0]);
    
    self.contentsOverride = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J"];
    XCTAssertTrue([controller loadObjectAtIndex:0]);
    
    XCTAssertTrue([controller isLoadingObjectAtIndex:0]);
    
    XCTAssertTrue([controller cancelLoadingObjectAtIndex:0]);
    
    XCTAssertFalse([controller isLoadingObjectAtIndex:0]);
    
    self.contentsOverride = nil;
    XCTAssertTrue([controller loadObjectAtIndex:0]);
    
    XCTAssertTrue([controller isLoadingObjectAtIndex:0]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqualObjects([controller objectInPagedArrayAtIndex:0], @0);
}

@end
