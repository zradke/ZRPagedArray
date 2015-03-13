//
//  ZRContentTableViewCell.m
//  ZRPagedArray
//
//  Created by Zachary Radke | AMDU on 3/12/15.
//  Copyright (c) 2015 Zach Radke. All rights reserved.
//

#import "ZRContentTableViewCell.h"

NSString *const ZRContentTableViewCellIdentifier = @"ZRContentTableViewCellIdentifier";

@interface ZRContentTableViewCell ()

@property (strong, nonatomic) UILabel *contentLabel;

@end


@implementation ZRContentTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        return nil;
    }
    
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _contentLabel = contentLabel;
    
    [self addSubview:contentLabel];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:contentLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:contentLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:contentLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:8.0]];
    
    self.userInteractionEnabled = NO;
    
    return self;
}

- (void)prepareForReuse
{
    self.contentLabel.text = nil;
}

- (void)setContentText:(NSString *)contentText
{
    self.contentLabel.text = contentText;
}

@end
