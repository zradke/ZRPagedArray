//
//  ZRPagingSection.h
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZRPagedArrayController.h"

@interface ZRPagingSection : NSObject <UITableViewDataSource, UITableViewDelegate, ZRPagedArrayControllerDelegate>

- (instancetype)initWithController:(ZRPagedArrayController *)controller tableView:(UITableView *)tableView NS_DESIGNATED_INITIALIZER;

@property (strong, nonatomic, readonly) ZRPagedArrayController *controller;
@property (strong, nonatomic, readonly) UITableView *tableView;

@end
