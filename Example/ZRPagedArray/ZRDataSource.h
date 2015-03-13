//
//  ZRDataSource.h
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZRPagedArrayController.h"

FOUNDATION_EXPORT NSUInteger const ZRDataSourceDefaultLoadDelay;

@interface ZRDataSource : NSObject <ZRPagedArrayControllerDataSource>

- (instancetype)initWithLoadDelay:(NSTimeInterval)loadDelay NS_DESIGNATED_INITIALIZER;

@property (assign, nonatomic, readonly) NSTimeInterval loadDelay;

- (NSIndexSet *)loadedIndexes;

@end
