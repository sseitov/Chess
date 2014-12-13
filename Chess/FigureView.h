//
//  FigureView.h
//  vChess
//
//  Created by Sergey Seitov on 1/29/10.
//  Copyright 2010 V-Channel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DevInfo.h"

#include "position.h"
#include "figure.h"
#include "move.h"

enum FigureLiveState {
	LIVING,
	KILLED,
	ALIVED
};

#define FIGURE_SIZE (IS_PAD ? 85.0 : 40.0)
#define SMALL_FIGURE_SIZE (IS_PAD ? 50.0 : 20.0)

@interface DragRect : UIView

@end

@interface PossibleRect : UIView

@end

@interface FigureView : UIImageView

@property (readwrite, nonatomic) unsigned char model;
@property (readwrite, nonatomic) vchess::Position position;
@property (readwrite, nonatomic) enum FigureLiveState liveState;

- (id)initFigure:(unsigned char)theModel;
- (void)kill:(BOOL)died;
- (void)promote:(BOOL)promote;

@end
