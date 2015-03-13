//
//  ZRLoadingTableViewCell.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRLoadingTableViewCell.h"

NSString *const ZRLoadingTableViewCellIdentifier = @"ZRLoadingTableViewCellIdentifier";

@interface ZRLoadingTableViewCell ()

@property (strong, nonatomic) UILabel *loadMoreLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end


@implementation ZRLoadingTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        return nil;
    }
    
    UILabel *loadMoreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    loadMoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    loadMoreLabel.text = @"Tap to load more";
    loadMoreLabel.textColor = [UIColor grayColor];
    [loadMoreLabel sizeToFit];
    _loadMoreLabel = loadMoreLabel;
    
    [self addSubview:loadMoreLabel];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:loadMoreLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:loadMoreLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [activityIndicatorView sizeToFit];
    _activityIndicatorView = activityIndicatorView;
    
    [self addSubview:activityIndicatorView];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    return self;
}

- (void)prepareForReuse
{
    if (self.isLoading)
    {
        self.loadMoreLabel.hidden = YES;
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
    }
    else
    {
        self.loadMoreLabel.hidden = NO;
        self.activityIndicatorView.hidden = YES;
        [self.activityIndicatorView stopAnimating];
    }
}

- (void)setLoading:(BOOL)loading
{
    if (_loading == loading)
    {
        return;
    }
    
    _loading = loading;
    
    if (_loading)
    {
        self.loadMoreLabel.hidden = YES;
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
    }
    else
    {
        self.loadMoreLabel.hidden = NO;
        self.activityIndicatorView.hidden = YES;
        [self.activityIndicatorView stopAnimating];
    }
}

@end
