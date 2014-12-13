//
//  Figure.m
//  vChess
//
//  Created by Sergey Seitov on 1/29/10.
//  Copyright 2010 V-Channel. All rights reserved.
//

#import "FigureView.h"

using namespace vchess;

@implementation DragRect

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = YES;
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0 green:200.0/255.0 blue:0 alpha:1.0].CGColor);
	CGContextStrokeRectWithWidth(context, rect, 10);
}

@end

@implementation PossibleRect

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = YES;
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0 green:200.0/255.0 blue:0 alpha:1.0].CGColor);
	rect.origin.x = rect.size.width / 3;
	rect.origin.y = rect.size.height / 3;
	rect.size.width /= 3;
	rect.size.height /= 3;
	CGContextFillEllipseInRect(context, rect);
}

@end

@implementation FigureView

- (UIImage*)smallImageByType {
	
	switch (FIGURE(self.model)) {
		case KING:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"SmallBlackK"];
			} else {
				return [UIImage imageNamed:@"SmallWhiteK"];
			}
		case QUEEN:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"SmallBlackQ"];
			} else {
				return [UIImage imageNamed:@"SmallWhiteQ"];
			}
		case ROOK:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"SmallBlackR"];
			} else {
				return [UIImage imageNamed:@"SmallWhiteR"];
			}
		case BISHOP:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"SmallBlackB"];
			} else {
				return [UIImage imageNamed:@"SmallWhiteB"];
			}
		case KNIGHT:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"SmallBlackN"];
			} else {
				return [UIImage imageNamed:@"SmallWhiteN"];
			}
		case PAWN:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"SmallBlackP"];
			} else {
				return [UIImage imageNamed:@"SmallWhiteP"];
			}
		default:
			return nil;
	}
}

- (UIImage*)imageByType {
	
	switch (FIGURE(self.model)) {
		case KING:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"BlackK"];
			} else {
				return [UIImage imageNamed:@"WhiteK"];
			}
		case QUEEN:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"BlackQ"];
			} else {
				return [UIImage imageNamed:@"WhiteQ"];
			}
		case ROOK:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"BlackR"];
			} else {
				return [UIImage imageNamed:@"WhiteR"];
			}
		case BISHOP:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"BlackB"];
			} else {
				return [UIImage imageNamed:@"WhiteB"];
			}
		case KNIGHT:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"BlackN"];
			} else {
				return [UIImage imageNamed:@"WhiteN"];
			}
		case PAWN:
			if (COLOR(self.model)) {
				return [UIImage imageNamed:@"BlackP"];
			} else {
				return [UIImage imageNamed:@"WhiteP"];
			}
		default:
			return nil;
	}
}

- (id)initFigure:(unsigned char)figure {
	
	if (self = [super initWithFrame:CGRectMake(0, 0, FIGURE_SIZE, FIGURE_SIZE)]) {
		self.opaque = NO;
		self.userInteractionEnabled = YES;
		self.liveState = LIVING;
		self.model = figure;
		self.image = [self imageByType];
	}
	
	return self;
}

- (void)promote:(BOOL)promote {

	if (promote) {
		self.model = QUEEN | COLOR(self.model);
	} else {
		self.model = PAWN | COLOR(self.model);
	}
	self.image = [self imageByType];
}

- (void)kill:(BOOL)died {

	if (died) {
		self.bounds = CGRectMake(0, 0, SMALL_FIGURE_SIZE, SMALL_FIGURE_SIZE);
		self.liveState = KILLED;
		self.image = [self smallImageByType];
	} else {
		self.bounds = CGRectMake(0, 0, FIGURE_SIZE, FIGURE_SIZE);
		self.liveState = LIVING;
		self.image = [self imageByType];
	}
}

@end
