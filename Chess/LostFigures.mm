//
//  LostFigures.m
//  Chess
//
//  Created by Сергей Сейтов on 10.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "LostFigures.h"
#import "DevInfo.h"
#import "FigureView.h"

@implementation LostFigures

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)layoutSubviews
{
	CGRect frame = CGRectMake(5, 5, SMALL_FIGURE_SIZE, SMALL_FIGURE_SIZE);
	BOOL bHorizontal = self.frame.size.width > self.frame.size.height;
	for (UIView* v in self.subviews) {
		v.frame = frame;
		if (bHorizontal) {
			frame.origin.x += (SMALL_FIGURE_SIZE + 5);
		} else {
			frame.origin.y += (SMALL_FIGURE_SIZE + 5);
		}
	}
}

- (void)clear
{
	for (UIView* v in self.subviews) {
		[v removeFromSuperview];
	}
	[self setNeedsLayout];
}

- (void)addFigure:(FigureView*)figure
{
	[self addSubview:figure];
	[self setNeedsLayout];
}

- (void)removeFigure:(FigureView*)figure
{
	for (UIView* v in self.subviews) {
		if (v == figure) {
			[v removeFromSuperview];
			[self setNeedsLayout];
			break;
		}
	}
}

@end
