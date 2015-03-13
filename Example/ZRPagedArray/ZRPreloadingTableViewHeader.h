//
//  ZRPreloadingTableViewHeader.h
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const ZRPreloadingTableViewHeaderIdentifier;

@interface ZRPreloadingTableViewHeader : UITableViewHeaderFooterView

@property (strong, nonatomic) UILabel *preloadingLabel;
@property (strong, nonatomic) UISwitch *preloadingSwitch;

@end
