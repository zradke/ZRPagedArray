//
//  ZRPagedArrayTests.m
//  ZRPagedArrayTests
//
//  Created by Zach Radke on 3/3/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ZRPagedArray/ZRPagedArray.h>

@interface ZRPagedArrayTests : XCTestCase

@end

@implementation ZRPagedArrayTests

- (ZRPagedArray *)pagedArray
{
    ZRPagedArray *pagedArray = [[ZRPagedArray alloc] initWithCount:24 objectsPerPage:10 placeholderObject:@"*"];
    
    [pagedArray setObjects:@[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J"] forPage:1];
    
    return pagedArray;
}


#pragma mark - Public interface

- (void)testInit
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertNotNil(pagedArray);
    XCTAssertEqual(pagedArray.count, 24);
    XCTAssertEqual(pagedArray.objectsPerPage, 10);
    XCTAssertEqual(pagedArray.pageCount, 3);
    XCTAssertEqualObjects(pagedArray.placeholderObject, @"*");
}

- (void)testInitWithLargeCountPerformance
{
    // Compared against AWPagedArray using the same count, objects per page, and accessing the same index.
    [self measureBlock:^{
        ZRPagedArray *pagedArray = [[ZRPagedArray alloc] initWithCount:1000000 objectsPerPage:30 placeholderObject:nil];
        XCTAssertEqualObjects([(id)pagedArray objectAtIndex:50000], [NSNull null]);
    }];
}

- (void)testObjectAtIndex
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertEqualObjects([pagedArray objectAtIndex:0], @"*");
    XCTAssertEqualObjects([pagedArray objectAtIndex:10], @"A");
    XCTAssertEqualObjects(pagedArray[20], @"*");
}

- (void)testObjectAtInvalidIndex
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertThrows([pagedArray objectAtIndex:pagedArray.count]);
}

- (void)testSetObjectsForPage
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    NSMutableArray *contents = [NSMutableArray array];
    for (NSUInteger i = 1; i <= pagedArray.objectsPerPage; i++)
    {
        [contents addObject:@(i)];
    }
    
    [pagedArray setObjects:contents forPage:0];
    
    XCTAssertEqualObjects([pagedArray objectAtIndex:0], @1);
    XCTAssertEqualObjects([pagedArray objectAtIndex:10], @"A");
    XCTAssertEqualObjects(pagedArray[20], @"*");
}

- (void)testSetObjectsForLastPage
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    [pagedArray setObjects:@[@0, @1, @2, @3] forPage:2];
    
    XCTAssertEqualObjects([pagedArray objectAtIndex:0], @"*");
    XCTAssertEqualObjects([pagedArray objectAtIndex:10], @"A");
    XCTAssertEqualObjects(pagedArray[20], @0);
}

- (void)testSetInvalidObjectsCount
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    NSArray *contents = @[@0, @1, @2, @3, @4];
    XCTAssertThrows([pagedArray setObjects:contents forPage:2]);
}

- (void)testUnsetObjectsForPage
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertTrue([pagedArray isContentSetForPage:1]);
    XCTAssertEqualObjects([pagedArray objectAtIndex:10], @"A");
    
    [pagedArray removeObjectsForPage:1];
    
    XCTAssertFalse([pagedArray isContentSetForPage:1]);
    XCTAssertEqualObjects([pagedArray objectAtIndex:10], @"*");
}

- (void)testUnsetObjectsForUnsetPage
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertFalse([pagedArray isContentSetForPage:0]);
    XCTAssertNoThrow([pagedArray removeObjectsForPage:0]);
}

- (void)testUnsetObjectsForInvalidPage
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertThrows([pagedArray removeObjectsForPage:19]);
}

- (void)testPageLoading
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertFalse([pagedArray isContentSetForPage:0]);
    XCTAssertTrue([pagedArray isContentSetForPage:1]);
    XCTAssertFalse([pagedArray isContentSetForPage:2]);
    
    NSMutableArray *contents = [NSMutableArray array];
    for (NSUInteger i = 1; i <= pagedArray.objectsPerPage; i++)
    {
        [contents addObject:@(i)];
    }
    
    [pagedArray setObjects:contents forPage:0];
    
    XCTAssertTrue([pagedArray isContentSetForPage:0]);
    XCTAssertTrue([pagedArray isContentSetForPage:1]);
    XCTAssertFalse([pagedArray isContentSetForPage:2]);
}

- (void)testPageAtIndex
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertEqual([pagedArray pageForObjectIndex:0], 0);
    XCTAssertEqual([pagedArray pageForObjectIndex:10], 1);
    XCTAssertEqual([pagedArray pageForObjectIndex:20], 2);
    XCTAssertEqual([pagedArray pageForObjectIndex:23], 2);
    XCTAssertEqual([pagedArray pageForObjectIndex:24], NSNotFound);
}

- (void)testIndexesForPage
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    NSIndexSet *expectedIndexes;
    expectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, pagedArray.objectsPerPage)];
    XCTAssertEqualObjects([pagedArray indexesOfObjectsForPage:0], expectedIndexes);
    
    expectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(10, pagedArray.objectsPerPage)];
    XCTAssertEqualObjects([pagedArray indexesOfObjectsForPage:1], expectedIndexes);
    
    expectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(20, 4)];
    XCTAssertEqualObjects([pagedArray indexesOfObjectsForPage:2], expectedIndexes);
    
    XCTAssertNil([pagedArray indexesOfObjectsForPage:3]);
}


#pragma mark - NSObject

- (void)testEquality
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    XCTAssertTrue([pagedArray isEqual:pagedArray]);
    XCTAssertFalse([pagedArray isEqual:@10]);
    XCTAssertTrue([pagedArray isEqual:[self pagedArray]]);
    XCTAssertTrue([pagedArray isEqualToPagedArray:[self pagedArray]]);
    XCTAssertFalse([pagedArray isEqualToPagedArray:nil]);
}


#pragma mark - NSCopying

- (void)testCopy
{
    ZRPagedArray *pagedArray = [self pagedArray];
    ZRPagedArray *copy = [pagedArray copy];
    
    XCTAssertEqualObjects(pagedArray, copy);
    
    [copy setObjects:@[@0, @1, @2, @3] forPage:2];
    
    XCTAssertFalse([pagedArray isEqualToPagedArray:copy]);
}


#pragma mark - NSFastEnumeration

- (void)testFastEnumeration
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    NSMutableArray *expectedArray = [NSMutableArray array];
    for (NSInteger i = 0; i < pagedArray.count; i++)
    {
        [expectedArray addObject:pagedArray[i]];
    }
    
    NSMutableArray *enumeratedArray = [NSMutableArray array];
    for (NSString *obj in pagedArray)
    {
        [enumeratedArray addObject:obj];
    }
    
    XCTAssertEqualObjects(expectedArray, enumeratedArray);
}

- (void)testFastEnumerationPerformance
{
    ZRPagedArray *pagedArray = [[ZRPagedArray alloc] initWithCount:1000000 objectsPerPage:30 placeholderObject:nil];
    
    // Compared against using a normal for-loop
    [self measureBlock:^{
        NSMutableArray *expectedArray = [NSMutableArray array];
        for (id obj in pagedArray)
        {
            [expectedArray addObject:obj];
        }
    }];
}

- (void)testFastEnumerationSettingMutation
{
    ZRPagedArray *pagedArray = [self pagedArray];
    dispatch_block_t block = ^{
        for (NSString __unused *obj in pagedArray)
        {
            [pagedArray setObjects:@[@0, @1, @2, @3] forPage:2];
        }
    };
    
    XCTAssertThrows(block());
}

- (void)testFastEnumerationRemovingMutation
{
    ZRPagedArray *pagedArray = [self pagedArray];
    dispatch_block_t block = ^{
        for (NSString __unused *obj in pagedArray)
        {
            [pagedArray removeObjectsForPage:1];
        }
    };
    
    XCTAssertThrows(block());
}


#pragma mark - NSSecureCoding

- (void)testEncodeDecode
{
    ZRPagedArray *pagedArray = [self pagedArray];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:pagedArray];
    
    XCTAssertNotNil(data);
    
    ZRPagedArray *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertNotNil(decoded);
    XCTAssertEqualObjects(pagedArray, decoded);
    
    [decoded setObjects:@[@1, @2, @3, @4] forPage:2];
    
    XCTAssertFalse([pagedArray isEqualToPagedArray:decoded]);
}

@end
