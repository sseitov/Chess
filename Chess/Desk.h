//
//  Desk.h
//  Chess
//
//  Created by Sergey Seitov on 08.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "disposition.h"

@class FigureView;

@protocol DeskDelegate <NSObject>

- (void)didMakeMove:(vchess::Move)move;
- (vchess::Moves)generateMovesForFigure:(FigureView*)figure;
- (void)killFigure:(FigureView*)figure;
- (void)aliveFigure:(FigureView*)figure;

@end

@interface Desk : UIImageView

@property (weak, nonatomic) id<DeskDelegate> delegate;

@property (readwrite, nonatomic) BOOL rotated;
@property (readwrite, nonatomic) BOOL activeColor;
@property (strong, nonatomic, readonly) NSMutableArray	*figures;

- (void)resetDisposition:(vchess::GameState)state;
- (void)rotate;
- (CGRect)cellFrameForPosition:(vchess::Position)pos;

- (void)makeMove:(const vchess::Move&)move
		  inGame:(vchess::Disposition*)game
	  completion:(void (^)(BOOL))completion;


@end
