//
//  ZRPagingSection.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRPagingSection.h"
#import "ZRLoadingTableViewCell.h"
#import "ZRContentTableViewCell.h"
#import "ZRPreloadingTableViewHeader.h"

@interface ZRPagingSection ()
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@end

@implementation ZRPagingSection

- (instancetype)initWithController:(ZRPagedArrayController *)controller tableView:(UITableView *)tableView
{
    NSParameterAssert(controller);
    NSParameterAssert(tableView);
    NSParameterAssert(controller.dataSource);
    
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _controller = controller;
    _controller.delegate = self;
    
    _tableView = tableView;
    
    [_tableView registerClass:[ZRLoadingTableViewCell class] forCellReuseIdentifier:ZRLoadingTableViewCellIdentifier];
    [_tableView registerClass:[ZRContentTableViewCell class] forCellReuseIdentifier:ZRContentTableViewCellIdentifier];
    [_tableView registerClass:[ZRPreloadingTableViewHeader class] forHeaderFooterViewReuseIdentifier:ZRPreloadingTableViewHeaderIdentifier];
    
    _numberFormatter = [NSNumberFormatter new];
    
    return self;
}

- (void)didChangePreloadingSwitch:(UISwitch *)sender
{
    if (sender.isOn)
    {
        self.controller.automaticPreloadIndexMargin = 10;
    }
    else
    {
        self.controller.automaticPreloadIndexMargin = 0;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.controller countOfPagedArray];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.controller objectInPagedArrayAtIndex:indexPath.row];
    if (object == [NSNull null])
    {
        ZRLoadingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ZRLoadingTableViewCellIdentifier forIndexPath:indexPath];
        cell.loading = YES;
        
        return cell;
    }
    else
    {
        ZRContentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ZRContentTableViewCellIdentifier forIndexPath:indexPath];
        NSString *string = [NSString stringWithFormat:@"#%@", [self.numberFormatter stringFromNumber:object]];
        [cell setContentText:string];
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.controller.shouldLoadPagesAutomatically)
    {
        ZRPreloadingTableViewHeader *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:ZRPreloadingTableViewHeaderIdentifier];
        headerView.preloadingSwitch.on = self.controller.automaticPreloadIndexMargin > 0;
        [headerView.preloadingSwitch addTarget:self action:@selector(didChangePreloadingSwitch:) forControlEvents:UIControlEventValueChanged];
        
        return headerView;
    }
    
    return nil;
}


#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.controller.shouldLoadPagesAutomatically)
    {
        return 44.0;
    }
    
    return 0.0;
}


#pragma mark - ZRPagedArrayControllerDelegate

- (void)controller:(ZRPagedArrayController *)controller didChangeObjectsForPage:(NSUInteger)page error:(NSError * __unused)error
{
    NSIndexSet *indexes = [controller indexesOfObjectsInPagedArrayForPage:page];
    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
    }];
    
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
