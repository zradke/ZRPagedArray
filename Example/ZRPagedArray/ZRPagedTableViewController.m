//
//  ZRPagedTableViewController.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRPagedTableViewController.h"
#import "ZRClassicPagingSection.h"
#import "ZRDataSource.h"

#import <ZRPagedArray/ZRPagedArray.h>
#import <ZRPagedArray/ZRPagedArrayController.h>

@interface ZRPagedTableViewController ()
@property (strong, nonatomic) ZRDataSource *dataSource;
@property (strong, nonatomic) ZRPagingSection *section;
@end

@implementation ZRPagedTableViewController

+ (instancetype)pagedViewControllerOfType:(ZRPagedViewControllerType)type
{
    ZRPagedTableViewController *viewController = [[self alloc] initWithStyle:UITableViewStylePlain];
    viewController->_pagingType = type;
    
    switch (type)
    {
        case ZRPagedViewControllerTypeClassicManual:
            viewController.title = @"Manual";
            break;
        case ZRPagedViewControllerTypeClassicAutomatic:
            viewController.title = @"Automatic";
            break;
        case ZRPagedViewControllerTypeFluentAutomatic:
            viewController.title = @"Fluent";
            break;
        default:
            break;
    }
    
    return viewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(didRefresh:) forControlEvents:UIControlEventValueChanged];
    
    [self regenerateDataSourceAndSection];
}

- (void)didRefresh:(UIRefreshControl *)sender
{
    [self.refreshControl endRefreshing];
    [self regenerateDataSourceAndSection];
}

- (void)regenerateDataSourceAndSection
{
    self.dataSource = [ZRDataSource new];
    
    ZRPagedArray *pagedArray = [[ZRPagedArray alloc] initWithCount:100000 objectsPerPage:20 placeholderObject:nil];
    ZRPagedArrayController *controller = [[ZRPagedArrayController alloc] initWithPagedArray:pagedArray];
    controller.dataSource = self.dataSource;
    
    switch (self.pagingType)
    {
        case ZRPagedViewControllerTypeClassicManual:
            controller.shouldLoadPagesAutomatically = NO;
            self.section = [[ZRClassicPagingSection alloc] initWithController:controller tableView:self.tableView];
            break;
        case ZRPagedViewControllerTypeClassicAutomatic:
            controller.shouldLoadPagesAutomatically = YES;
            self.section = [[ZRClassicPagingSection alloc] initWithController:controller tableView:self.tableView];
            break;
        case ZRPagedViewControllerTypeFluentAutomatic:
            controller.shouldLoadPagesAutomatically = YES;
            self.section = [[ZRPagingSection alloc] initWithController:controller tableView:self.tableView];
            break;
        default:
            break;
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.section numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.section tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.section tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.section respondsToSelector:_cmd])
    {
        return [self.section tableView:tableView viewForHeaderInSection:section];
    }
    
    return nil;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.section respondsToSelector:_cmd])
    {
        return [self.section tableView:tableView heightForHeaderInSection:section];
    }
    
    return 0.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.section respondsToSelector:_cmd])
    {
        [self.section tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

@end
