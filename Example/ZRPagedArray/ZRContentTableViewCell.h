//
//  ZRContentTableViewCell.h
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const ZRContentTableViewCellIdentifier;

@interface ZRContentTableViewCell : UITableViewCell

- (void)setContentText:(NSString *)contentText;

@end
