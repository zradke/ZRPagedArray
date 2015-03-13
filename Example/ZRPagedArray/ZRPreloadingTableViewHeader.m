//
//  ZRPreloadingTableViewHeader.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRPreloadingTableViewHeader.h"

NSString *const ZRPreloadingTableViewHeaderIdentifier = @"ZRPreloadingTableViewHeaderIdentifier";

@interface ZRPreloadingTableViewHeader ()

@end

@implementation ZRPreloadingTableViewHeader

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (!(self = [super initWithReuseIdentifier:reuseIdentifier]))
    {
        return nil;
    }
    
    UILabel *preloadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    preloadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    preloadingLabel.text = @"Preload content";
    preloadingLabel.textAlignment = NSTextAlignmentRight;
    [preloadingLabel sizeToFit];
    _preloadingLabel = preloadingLabel;
    
    [self addSubview:preloadingLabel];
    
    UISwitch *preloadingSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    preloadingSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [preloadingSwitch sizeToFit];
    [preloadingSwitch setContentHuggingPriority:751 forAxis:UILayoutConstraintAxisHorizontal];
    _preloadingSwitch = preloadingSwitch;
    
    [self addSubview:preloadingSwitch];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(preloadingLabel, preloadingSwitch);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(8)-[preloadingLabel]-(8)-[preloadingSwitch]-(8)-|" options:0 metrics:nil views:views]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:preloadingLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:preloadingSwitch attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    return self;
}

@end
