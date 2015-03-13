//
//  ZRClassicPagingSection.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRClassicPagingSection.h"
#import "ZRLoadingTableViewCell.h"
#import "ZRContentTableViewCell.h"
#import "ZRDataSource.h"

@interface ZRClassicPagingSection ()
@property (strong, nonatomic) ZRDataSource *dataSource;
@end

@implementation ZRClassicPagingSection

- (instancetype)initWithController:(ZRPagedArrayController *)controller tableView:(UITableView *)tableView
{
    if (!(self = [super initWithController:controller tableView:tableView]))
    {
        return nil;
    }
    
    _dataSource = controller.dataSource;
        
    return self;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MIN(self.dataSource.loadedIndexes.count + 1, self.controller.countOfPagedArray);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // This is a loading cell
    if ([self.controller objectInPagedArrayAtIndex:indexPath.row] == [NSNull null])
    {
        ZRLoadingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ZRLoadingTableViewCellIdentifier forIndexPath:indexPath];
        
        if (self.controller.shouldLoadPagesAutomatically)
        {
            cell.loading = YES;
        }
        else
        {
            cell.loading = [self.controller isLoadingObjectAtIndex:indexPath.row];
        }
        
        return cell;
    }
    else // This is a content cell
    {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexSet *loadedIndexes = self.dataSource.loadedIndexes;
    
    // This is a loading cell
    if ((loadedIndexes.lastIndex == NSNotFound || indexPath.row > loadedIndexes.lastIndex) && !self.controller.shouldLoadPagesAutomatically)
    {
        [self.controller loadObjectAtIndex:indexPath.row];
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - ZRPagedArrayControllerDelegate

- (void)controller:(ZRPagedArrayController *)controller didChangeObjectsForPage:(NSUInteger)page error:(NSError * __unused)error
{
    NSIndexSet *indexes = [controller indexesOfObjectsInPagedArrayForPage:page];
    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
    }];
    
    [self.tableView beginUpdates];
    
    if (indexes.lastIndex == (controller.countOfPagedArray - 1))
    {
        [self.tableView deleteRowsAtIndexPaths:@[indexPaths.firstObject] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
}


@end
