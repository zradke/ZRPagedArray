//
//  ZRPagedTableViewController.h
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZRDataSource, ZRPagingSection;

typedef NS_ENUM(NSInteger, ZRPagedViewControllerType)
{
    ZRPagedViewControllerTypeClassicManual,
    ZRPagedViewControllerTypeClassicAutomatic,
    ZRPagedViewControllerTypeFluentAutomatic
};

@interface ZRPagedTableViewController : UITableViewController

+ (instancetype)pagedViewControllerOfType:(ZRPagedViewControllerType)type;

@property (assign, nonatomic, readonly) ZRPagedViewControllerType pagingType;

@end
