//
//  ZRAppDelegate.m
//  ZRPagedArray
//
//  Created by CocoaPods on 03/12/2015.
//  Copyright (c) 2014 Zach Radke. All rights reserved.
//

#import "ZRAppDelegate.h"
#import "ZRPagedTableViewController.h"

#import <ZRPagedArray/ZRPagedArray.h>
#import <ZRPagedArray/ZRPagedArrayController.h>


@implementation ZRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIViewController *classicManualViewController = [ZRPagedTableViewController pagedViewControllerOfType:ZRPagedViewControllerTypeClassicManual];
    UIViewController *classicAutomaticViewController = [ZRPagedTableViewController pagedViewControllerOfType:ZRPagedViewControllerTypeClassicAutomatic];
    UIViewController *fluentViewController = [ZRPagedTableViewController pagedViewControllerOfType:ZRPagedViewControllerTypeFluentAutomatic];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:classicManualViewController],
                                         [[UINavigationController alloc] initWithRootViewController:classicAutomaticViewController],
                                         [[UINavigationController alloc] initWithRootViewController:fluentViewController]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
