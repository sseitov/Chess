//
//  TableViewCell.m
//  Chess
//
//  Created by Sergey Seitov on 12.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "TableViewCell.h"

@interface TableViewCell ()

@property (strong, nonatomic) UILabel* white;
@property (strong, nonatomic) UILabel* black;

@end

@implementation TableViewCell

- (id)initWithMove:(const vchess::Move&)white black:(const vchess::Move&)black
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	if (self) {
		_white = [[UILabel alloc] initWithFrame:CGRectZero];
		if (white.moveType != vchess::NotMove) {
			_white.text = [NSString stringWithUTF8String:white.notation().c_str()];
		}
		_white.textAlignment = NSTextAlignmentCenter;
		[self.contentView addSubview:_white];
		
		_black = [[UILabel alloc] initWithFrame:CGRectZero];
		if (black.moveType != vchess::NotMove) {
			_black.text = [NSString stringWithUTF8String:black.notation().c_str()];
		}
		_black.textAlignment = NSTextAlignmentCenter;
		[self.contentView addSubview:_black];
	}
	return self;
}

- (void)layoutSubviews
{
	CGRect frame = self.contentView.bounds;
	frame.size.width = TABLE_WIDTH/2;
	frame.origin.x = 0;
	_white.frame = frame;
	frame.origin.x = TABLE_WIDTH/2;
	_black.frame = frame;
}

@end
