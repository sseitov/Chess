//
//  Desk.m
//  Chess
//
//  Created by Sergey Seitov on 08.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "Desk.h"
#import "FigureView.h"
#import <AudioToolbox/AudioToolbox.h>

#define DESK_SIZE (IS_PAD ? 680.0 : 320.0)

@interface Desk () {
	
	SystemSoundID soundID;
	vchess::Moves	possibleMoves;
}

@property (strong, nonatomic) FigureView *dragFigure;
@property (readwrite, nonatomic) CGPoint dragStart;
@property (strong, nonatomic) DragRect *dragRect;
@property (strong, nonatomic) NSMutableArray *possibleCells;

@end

@implementation Desk

- (void)awakeFromNib
{
	_figures = [NSMutableArray new];
	_possibleCells = [NSMutableArray new];
	
	NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"turn_sound" ofType:@"wav"];
	AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
	
	_dragRect = [[DragRect alloc] initWithFrame:CGRectMake(0, 0, FIGURE_SIZE, FIGURE_SIZE)];
	_dragRect.hidden = YES;
	[self addSubview:_dragRect];
}

- (CGRect)cellFrameForPosition:(vchess::Position)pos
{
	if (!_rotated) {
		return CGRectMake(pos.x() *FIGURE_SIZE, DESK_SIZE - FIGURE_SIZE - pos.y()*FIGURE_SIZE, FIGURE_SIZE, FIGURE_SIZE);
	} else {
		return CGRectMake(DESK_SIZE - FIGURE_SIZE - pos.x()*FIGURE_SIZE, pos.y()*FIGURE_SIZE, FIGURE_SIZE, FIGURE_SIZE);
	}
}

- (void)resetDisposition:(vchess::GameState)state
{
	for (FigureView *f in _figures) {
		[f removeFromSuperview];
	}
	[_figures removeAllObjects];
	
	for (int y=0; y<8; y++) {
		for (int x=0; x<8; x++) {
			unsigned char cell = state.cellAt(vchess::Position(x, y));
			if (cell) {
				FigureView *f = [[FigureView alloc] initFigure:cell];
				f.position = vchess::Position(x, y);
				f.frame = [self cellFrameForPosition:f.position];
				[self addSubview:f];
				[_figures addObject:f];
			}
		}
	}
	_activeColor = NO;
}

- (vchess::GameState)getDisposition
{
	vchess::GameState state;
	for (int y=0; y<8; y++) {
		for (int x=0; x<8; x++) {
			vchess::Position pos(x, y);
			FigureView* figure = [self figureAt:pos];
			if (figure) {
				state.setCell(figure.model, pos);
			}
		}
	}
	return state;
}

- (void)rotate
{
	_rotated = !_rotated;
	for (FigureView *f in _figures) {
		f.frame = [self cellFrameForPosition:f.position];
	}
}

#pragma mark - move animations

- (FigureView*)figureAt:(vchess::Position)position
{
	NSEnumerator *enumerator = [_figures objectEnumerator];
	FigureView *f;
	while (f = [enumerator nextObject]) {
		if (f.position == position) {
			return f;
		}
	}
	return nil;
}

- (void)moveFigure:(FigureView*)f to:(vchess::Position)position
{
	if (f.liveState == KILLED) {
		[self.delegate killFigure:f];
	} else if (f.liveState == ALIVED) {
		[self.delegate aliveFigure:f];
	} else {
		f.frame = [self cellFrameForPosition:position];
		f.position = position;
	}
}

- (void)moveFigure:(FigureView*)f to:(vchess::Position)position
		completion:(void (^)())completion
{
	[UIView animateWithDuration:0.2
					 animations:^{
						 [self moveFigure:f to:position];
					 }
					 completion:^(BOOL finished){
						 if (finished) {
							 completion();
						 }
					 }
	 ];
}

- (void)prepareMove:(const vchess::Move&)move forFigure:(FigureView*)figure
{
	if (move.moveType == vchess::KingCastling || move.moveType == vchess::QueenCastling) {
		int x1 = move.moveType == vchess::KingCastling ? 7 : 0;
		int x2 = move.moveType == vchess::KingCastling ? 5 : 3;
		int y = vchess::COLOR(figure.model) ? 7 : 0;
		FigureView *rook = [self figureAt:vchess::Position(x1, y)];
		[self moveFigure:rook to:vchess::Position(x2, y)];
	} else if (!move.capturePosition.isNull()) {
		FigureView *eat = [self figureAt:move.capturePosition];
		eat.liveState = KILLED;
		[self moveFigure:eat to:vchess::Position()];
	} else {
		FigureView* f = [self figureAt:move.to];
		if (f) {
			NSLog(@"move type error ");
		}
	}
	
	if (move.promote) {
		[figure promote:true];
	}
	AudioServicesPlaySystemSound (soundID);
}

- (BOOL)checkState:(vchess::GameState)state
{
	vchess::GameState deskState = [self getDisposition];
	if (state.isEqual(deskState)) {
		return YES;
	} else {
		NSLog(@"ERROR MOVE. POSITION:");
		state.print();
		NSLog(@"ON DESK:");
		deskState.print();
		return NO;
	}
}

- (void)makeMove:(const vchess::Move&)move
		  inGame:(vchess::Disposition*)game
	  completion:(void (^)(BOOL))completion
{
	FigureView* figure = [self figureAt:move.from];
	if (figure) {
		[self prepareMove:move forFigure:figure];
		if (completion) {
			[self moveFigure:figure to:move.to completion:^(){
				game->doMove(move);
				completion([self checkState:game->state()]);
			}];
		} else {
			[self moveFigure:figure to:move.to];
			game->doMove(move);
		}
	} else {
		NSLog(@"NO FIGURE AT %s", move.from.notation().c_str());
		if (completion) {
			completion(NO);
		}
	}
}

#pragma mark - touches implementation

- (vchess::Position)positionFromPoint:(CGPoint)pt forFigure:(FigureView*)figure
{
	vchess::Position result(-1, -1);
	if (pt.x < 0 || pt.x > DESK_SIZE || pt.y < 0 || pt.y > DESK_SIZE) {
		_dragRect.hidden = YES;
	} else {
		int x, y;
		if (!_rotated) {
			x = pt.x/FIGURE_SIZE;
			y = 8 - pt.y/FIGURE_SIZE;
		} else {
			x = 8 - pt.x/FIGURE_SIZE;
			y = pt.y/FIGURE_SIZE;
		}
		result = vchess::Position(x, y);
		_dragRect.hidden = NO;
		if (_rotated) {
			_dragRect.frame = CGRectMake(FIGURE_SIZE*(7-x), FIGURE_SIZE*y, FIGURE_SIZE, FIGURE_SIZE);
		} else {
			_dragRect.frame = CGRectMake(FIGURE_SIZE*x, FIGURE_SIZE*(7-y), FIGURE_SIZE, FIGURE_SIZE);
		}
	}
	return result;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	if ([touch.view isKindOfClass:[FigureView class]]) {
		_dragFigure = (FigureView*)[touch view];
		if (vchess::COLOR(_dragFigure.model) != _activeColor) {
			_dragFigure = nil;
			return;
		}
		possibleMoves = [self.delegate generateMovesForFigure:_dragFigure];
		for (int i=0; i<possibleMoves.size(); i++) {
			PossibleRect *p = [[PossibleRect alloc] init];
			p.frame = [self cellFrameForPosition:possibleMoves[i].to];
			[self addSubview:p];
			[_possibleCells addObject:p];
		}
		_dragStart = _dragFigure.center;
		CGPoint pt = _dragFigure.center;
		pt.y -= _dragFigure.bounds.size.height/2;
		_dragFigure.center = pt;
		[self bringSubviewToFront:_dragFigure];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	if ([touch view] == _dragFigure) {
		CGPoint pt = [touch locationInView:self];
		pt.y -= _dragFigure.bounds.size.height/2;
		_dragFigure.center = pt;
		[self positionFromPoint:pt forFigure:_dragFigure];
	}
}

- (vchess::Move)findMoveFrom:(vchess::Position)from to:(vchess::Position)to
{
	for (vchess::Moves::iterator it = possibleMoves.begin(); it != possibleMoves.end(); it++) {
		if (it->from == from && it->to == to) {
			return *it;
		}
	}
	return vchess::Move();
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	if ([touch view] == _dragFigure) {
		CGPoint pt = [touch locationInView:self];
		pt.y -= _dragFigure.bounds.size.height/2;
		_dragFigure.center = pt;
		vchess::Position to = [self positionFromPoint:pt forFigure:_dragFigure];
		vchess::Move m = [self findMoveFrom:_dragFigure.position to:to];
		if (m.moveType == vchess::NotMove) {
			[self animateFigure:_dragFigure to:_dragStart];
		} else {
			[self.delegate didMakeMove:m];
		}
		
		for (UIView *v in _possibleCells) {
			[v removeFromSuperview];
		}
		[_possibleCells removeAllObjects];
		_dragRect.hidden = YES;
	}
}

#pragma mark - animation

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	self.userInteractionEnabled = YES;
}

- (void)animateFigure:(FigureView*)figure to:(CGPoint)pt {
	
	self.userInteractionEnabled = NO;
	CALayer *dragLayer = figure.layer;
	
	// Create a keyframe animation to follow a path back to the center
	CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	bounceAnimation.removedOnCompletion = NO;
	
	CGFloat animationDuration = 0.2;
	
	
	// Create the path for the bounces
	CGMutablePathRef thePath = CGPathCreateMutable();
	
	CGFloat midX = pt.x;
	CGFloat midY = pt.y;
	CGFloat originalOffsetX = figure.center.x - midX;
	CGFloat originalOffsetY = figure.center.y - midY;
	CGFloat offsetDivider = 4.0;
	
	BOOL stopBouncing = NO;
	
	// Start the path at the placard's current location
	CGPathMoveToPoint(thePath, NULL, figure.center.x, figure.center.y);
	CGPathAddLineToPoint(thePath, NULL, midX, midY);
	
	// Add to the bounce path in decreasing excursions from the center
	while (stopBouncing != YES) {
		CGPathAddLineToPoint(thePath, NULL, midX + originalOffsetX/offsetDivider, midY + originalOffsetY/offsetDivider);
		CGPathAddLineToPoint(thePath, NULL, midX, midY);
		
		offsetDivider += 4;
		animationDuration += 1/offsetDivider;
		if ((abs(originalOffsetX/offsetDivider) < 6) && (abs(originalOffsetY/offsetDivider) < 6)) {
			stopBouncing = YES;
		}
	}
	
	bounceAnimation.path = thePath;
	bounceAnimation.duration = animationDuration;
	CGPathRelease(thePath);
	
	// Create a basic animation to restore the size of the figure
	CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	transformAnimation.removedOnCompletion = YES;
	transformAnimation.duration = animationDuration;
	transformAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	
	
	// Create an animation group to combine the keyframe and basic animations
	CAAnimationGroup *theGroup = [CAAnimationGroup animation];
	
	// Set self as the delegate to allow for a callback to reenable user interaction
	theGroup.delegate = self;
	theGroup.duration = animationDuration;
	theGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	
	theGroup.animations = [NSArray arrayWithObjects:bounceAnimation, transformAnimation, nil];
	
	
	// Add the animation group to the layer
	[dragLayer addAnimation:theGroup forKey:@"animatePlacardViewToCenter"];
	
	// Set the placard view's center and transformation to the original values in preparation for the end of the animation
	figure.center =  pt;
	figure.transform = CGAffineTransformIdentity;
}

@end
