//
//  GameController.m
//  Chess
//
//  Created by Sergey Seitov on 08.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "GameController.h"
#import "FigureView.h"
#import "MBProgressHUD.h"
#import "LostFigures.h"
#import "DevInfo.h"
#import "TableViewCell.h"

//#define DO_LOG

enum AlertAction {
	NoAction,
	StartGame,
	StopGame
};

enum Depth {
	Fast = 3,
	Strong = 4
};

@interface NSIndexSet (indexOfIndex)

- (NSUInteger)indexAtIndex:(NSUInteger)anIndex;

@end

@implementation NSIndexSet (indexOfIndex)

- (NSUInteger)indexAtIndex:(NSUInteger)anIndex
{
	if (anIndex >= [self count])
		return NSNotFound;
	
	NSUInteger index = [self firstIndex];
	for (NSUInteger i = 0; i < anIndex; i++)
		index = [self indexGreaterThanIndex:index];
	return index;
}

@end

@interface GameController () {
	
	vchess::Disposition _currentGame;
	int _turnTime;
	vchess::Moves _moves;
}

@property (weak, nonatomic) IBOutlet Desk *desk;
@property (weak, nonatomic) IBOutlet UIButton *commandButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timerLayout;
@property (weak, nonatomic) IBOutlet UISegmentedControl *timerView;
@property (weak, nonatomic) IBOutlet UIImageView *logo;

@property (strong, nonatomic) LostFigures *whiteLostFigures;
@property (strong, nonatomic) LostFigures *blackLostFigures;

@property (strong, nonatomic) NSTimer *timer;

@property (readwrite, nonatomic) BOOL userColor;

@property (strong, nonatomic) UITableView* table;

@property (readwrite, nonatomic) BOOL isDebut;
@property (readwrite, nonatomic) enum Depth depth;

@end

@implementation GameController

- (void)addBorderToView:(UIView*)v width:(CGFloat)width
{
	v.layer.borderWidth = width;
	v.layer.masksToBounds = YES;
	v.layer.cornerRadius = 10.0;
	v.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Pocket Chess";
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"marble.png"]];

	_logo.hidden = YES;
	
	_desk.image = [UIImage imageNamed:@"ChessDesk"];
	[self addBorderToView:_desk width:5.0];
	
	_whiteLostFigures = [[LostFigures alloc] initWithFrame:CGRectZero];
	_whiteLostFigures.backgroundColor = [UIColor lightGrayColor];
	[self addBorderToView:_whiteLostFigures width:(IS_PAD ? 5.0 : 2.0)];
	[self.view addSubview:_whiteLostFigures];
	
	_blackLostFigures = [[LostFigures alloc] initWithFrame:CGRectZero];
	_blackLostFigures.backgroundColor = [UIColor lightGrayColor];
	[self addBorderToView:_blackLostFigures width:(IS_PAD ? 5.0 : 2.0)];
	[self.view addSubview:_blackLostFigures];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"strongLevel"]) {
		_depth = Fast;
	} else {
		_depth = Strong;
	}
	
	srand((unsigned int)time(NULL));

	_desk.delegate = self;

	_timerLayout.constant = -40;
	_timerView.hidden = YES;
	
	CGRect frame = CGRectMake(self.view.frame.size.width, 0, 0, self.view.frame.size.height);
	_table = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	_table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	_table.dataSource = self;
	_table.delegate = self;
	_table.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self.view addSubview:_table];
	
	[_desk resetDisposition:_currentGame.state()];
}

- (IBAction)command:(UIButton *)sender
{
	if (_timer == nil) {
		[self doStartGame];
	} else {
		[self doStopGame];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (!IS_PAD && self.view.frame.size.height > 480) {
		_logo.hidden = NO;
	}
	if ( UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
		[self arrangeFromOrientation:UIInterfaceOrientationPortrait];
	} else {
		[self arrangeFromOrientation:UIInterfaceOrientationLandscapeLeft];
	}
}

- (void)arrangeFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	CGRect frame = _table.frame;
	if (_table.frame.size.width > 0) {
		frame.origin.x = self.view.frame.size.width - TABLE_WIDTH;
	} else {
		frame.origin.x = self.view.frame.size.width;
	}
	[UIView animateWithDuration:0.3f
					 animations:^(){
						 _table.frame = frame;
					 } completion:^(BOOL finished) {
						 if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
						 {
							 if (_desk.rotated) {
								 _blackLostFigures.frame = CGRectMake(_desk.frame.origin.x, _desk.frame.origin.y - (IS_PAD ? 80 : 40),
																	  _desk.frame.size.width, IS_PAD ? 70 : 30);
								 _whiteLostFigures.frame = CGRectMake(_desk.frame.origin.x, _desk.frame.origin.y + _desk.frame.size.width + 10,
																	  _desk.frame.size.width, IS_PAD ? 70 : 30);
							 } else {
								 _whiteLostFigures.frame = CGRectMake(_desk.frame.origin.x, _desk.frame.origin.y - (IS_PAD ? 80 : 40),
																	  _desk.frame.size.width, IS_PAD ? 70 : 30);
								 _blackLostFigures.frame = CGRectMake(_desk.frame.origin.x, _desk.frame.origin.y + _desk.frame.size.width + 10,
																	  _desk.frame.size.width, IS_PAD ? 70 : 30);
							 }
						 } else {
							 if (_desk.rotated) {
								 _blackLostFigures.frame = CGRectMake(_desk.frame.origin.x - (IS_PAD ? 80 : 40), _desk.frame.origin.y,
																	  IS_PAD ? 70 : 30, _desk.frame.size.height);
								 _whiteLostFigures.frame = CGRectMake(_desk.frame.origin.x + _desk.frame.size.width + 10, _desk.frame.origin.y,
																	  IS_PAD ? 70 : 30, _desk.frame.size.height);
							 } else {
								 _whiteLostFigures.frame = CGRectMake(_desk.frame.origin.x - (IS_PAD ? 80 : 40), _desk.frame.origin.y,
																	  IS_PAD ? 70 : 30, _desk.frame.size.height);
								 _blackLostFigures.frame = CGRectMake(_desk.frame.origin.x + _desk.frame.size.width + 10, _desk.frame.origin.y,
																	  IS_PAD ? 70 : 30, _desk.frame.size.height);
							 }
						 }
						 _blackLostFigures.hidden = NO;
						 _whiteLostFigures.hidden = NO;
					 }
	 ];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	_blackLostFigures.hidden = YES;
	_whiteLostFigures.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self arrangeFromOrientation:fromInterfaceOrientation];
}


- (IBAction)rotate:(id)sender
{
	[_desk rotate];
	if ( UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
		[self arrangeFromOrientation:UIInterfaceOrientationPortrait];
	} else {
		[self arrangeFromOrientation:UIInterfaceOrientationLandscapeLeft];
	}
}

- (void)doStartGame
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pocket Chess"
													message:@"What color you choose?"
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"White", @"Black", nil];
	alert.tag = StartGame;
	[alert show];
}

- (void)doStopGame
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pocket Chess" message:@"You are really surrender?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
	alert.tag = StopGame;
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag)
	{
		case StartGame:
			switch (buttonIndex) {
				case 2:
					_userColor = YES;
					break;
				case 1:
					_userColor = NO;
					break;
				default:
					return;
			}
			[self startGame];
			break;
		case StopGame:
			if (buttonIndex) {
				[self stopGame];
			}
			break;
		default:
			break;
	}
}

- (void)startGame
{
	[_commandButton setTitle:@"Surrender" forState:UIControlStateNormal];
	
	_timerView.hidden = NO;
	_timerLayout.constant = 6;
	[UIView animateWithDuration:0.4
					 animations:^{
						 [self.view layoutIfNeeded];
					 }
	 ];
	
	_isDebut = YES;
	[_whiteLostFigures clear];
	[_blackLostFigures clear];
	_moves.clear();
	_currentGame.reset();
	[_desk resetDisposition:_currentGame.state()];
	
	_turnTime = 0;
	_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
	if (_userColor) {	// первый ход от компьютера
		[self bestMove];
	} else {			// первый ход человека
		_desk.userInteractionEnabled = YES;
	}
}

- (void)timerTick:(NSTimer *)timer
{
	_turnTime++;
	NSString *txt = [NSString stringWithFormat:@"%.2d:%.2d", _turnTime/60, _turnTime % 60];
	if (_desk.activeColor) {
		[_timerView setTitle:txt forSegmentAtIndex:1];
	} else {
		[_timerView setTitle:txt forSegmentAtIndex:0];
	}
}

- (void)stopGame
{
	[_commandButton setTitle:@"Start New Game" forState:UIControlStateNormal];
	
	_timerLayout.constant = -40;
	[UIView animateWithDuration:0.4
					 animations:^{
						 [self.view layoutIfNeeded];
					 }
					 completion:^(BOOL finished){
						 _timerView.hidden = YES;
					 }
	 ];
	
	_desk.userInteractionEnabled = NO;
	[_timer invalidate];
	_timer = nil;
	
	[_timerView setTitle:@"00:00" forSegmentAtIndex:0];
	[_timerView setTitle:@"00:00" forSegmentAtIndex:1];
}

- (void)switchColor
{
	[_timer invalidate];
	if (_desk.activeColor) {
		[_timerView setTitle:@"00:00" forSegmentAtIndex:0];
	} else {
		[_timerView setTitle:@"00:00" forSegmentAtIndex:1];
	}
	_desk.activeColor = !_desk.activeColor;
	_turnTime = 0;
	_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
}

- (void)surrender
{
	[self stopGame];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pocket Chess" message:@"Congratulations! You won!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

#pragma mark - Desk delegate

- (void)didMakeMove:(vchess::Move)move
{
	[_desk makeMove:move inGame:&_currentGame completion:nil];
	_moves.push_back(move);
	[self logMove:move];
	[_table reloadData];
	_desk.userInteractionEnabled = NO;
	[self switchColor];
	[self bestMove];
//	_desk.userInteractionEnabled = YES;
}

- (vchess::Moves)generateMovesForFigure:(FigureView*)figure
{
	return _currentGame.genMoves(vchess::COLOR(figure.model), figure.position);
}

- (void)killFigure:(FigureView*)f
{
	[f kill:YES];
	[f removeFromSuperview];
	[_desk.figures removeObject:f];
	
	if (vchess::COLOR(f.model)) {
		[_blackLostFigures addFigure:f];
	} else {
		[_whiteLostFigures addFigure:f];
	}
}

- (void)aliveFigure:(FigureView*)f
{
	if (vchess::COLOR(f.model)) {
		[_blackLostFigures removeFigure:f];
	} else {
		[_whiteLostFigures removeFigure:f];
	}
	
	[f kill:NO];
	f.frame = [_desk cellFrameForPosition:f.position];
	[_desk.figures addObject:f];
	[_desk addSubview:f];
}

- (IBAction)showNotation
{
	CGRect frame = _table.frame;
	if (_table.frame.size.width > 0) {
		frame.origin.x = self.view.frame.size.width;
		frame.size.width = 0;
	} else {
		frame.origin.x = self.view.frame.size.width-TABLE_WIDTH;
		frame.size.width = TABLE_WIDTH;
	}
	[UIView animateWithDuration:.3f animations:^(){
		_table.frame = frame;
		[_table setNeedsLayout];
	}];
}

- (void)logMove:(vchess::Move)move
{
#ifdef DO_LOG
	NSString* color = _desk.activeColor ? @"BLACK" : @"WHITE";
	if (move.moveType != vchess::NotMove) {
		NSLog(@"%@ %s", color, move.notation().c_str());
	} else {
		NSLog(@"Null move");
	}
#endif
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width , 44)];
	
	CGRect frame = tableView.frame;
	frame.size.height = 44;
	
	UIFont* f = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:15];
	
	frame.size.width /= 2;
	frame.origin.x = 0;
	UILabel *white = [[UILabel alloc] initWithFrame:frame];
	white.backgroundColor = [UIColor lightGrayColor];
	white.textColor = [UIColor whiteColor];
	white.textAlignment = NSTextAlignmentCenter;
	white.text = @"WHITE";
	white.font = f;
	[v addSubview:white];
	
	frame.origin.x = frame.size.width;
	UILabel *black = [[UILabel alloc] initWithFrame:frame];
	black.backgroundColor = [UIColor blackColor];
	black.textColor = [UIColor whiteColor];
	black.textAlignment = NSTextAlignmentCenter;
	black.text = @"BLACK";
	black.font = f;
	[v addSubview:black];
	
	return v;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (_moves.size()/2 + _moves.size()%2);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int row = (int)indexPath.row;
	vchess::Move white;
	if (row*2 < _moves.size()) {
		white = _moves[row*2];
	}
	vchess::Move black;
	if (row*2+1 < _moves.size()) {
		black = _moves[row*2 +1];
	}
	return [[TableViewCell alloc] initWithMove:white black:black];
}

#pragma mark - Chess brain

- (IBAction)showSettings:(id)sender
{
	[self performSegueWithIdentifier:@"showSettings" sender:self];
}

- (NSString*)gameText
{
	std::string text;
	for (int i=0; i<_moves.size(); i++) {
		text += (_moves[i].shortNotation() + " ");
	}
	return [NSString stringWithUTF8String:text.c_str()];
}

- (vchess::Move)searchFromBook
{
	NSString *text = [self gameText];
	NSArray* debutBook = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"book" withExtension:@"plist"]];
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	if ([text isEqual:@""]) {
		[indexes addIndexesInRange:{0, debutBook.count}];
	} else {
		for (NSString *line in debutBook) {
			if ([line rangeOfString:text].location == 0 && line.length > text.length) {
				[indexes addIndex:[debutBook indexOfObject:line]];
			}
		}
	}
	if (indexes.count == 0) {
		return vchess::Move();
	}
	NSInteger index = rand() % indexes.count;
	NSArray *bookTurns = [[debutBook objectAtIndex:[indexes indexAtIndex:index]] componentsSeparatedByString:@" "];
	const char *turn = [[bookTurns objectAtIndex:_moves.size()] UTF8String];
	int x1 = turn[0] - 'a';
	int y1 = turn[1] - '1';
	int x2 = turn[2] - 'a';
	int y2 = turn[3] - '1';
	vchess::Position from(x1, y1);
	vchess::Position to(x2, y2);
	unsigned char fromFigure = _currentGame.state().cellAt(from);
	unsigned char toFigure = _currentGame.state().cellAt(to);
	if (toFigure) {
		vchess::Move m(vchess::FIGURE(fromFigure), from, to, vchess::Capture);
		m.capturePosition = to;
		m.captureFigure = toFigure;
		return m;
	} else {
		return vchess::Move(vchess::FIGURE(fromFigure),from, to, vchess::Normal);
	}
}

static vchess::Move best_move;
static int DEPTH;

int search(vchess::Disposition position, bool color, int depth, int alpha, int beta)
{
	if (depth == 0) return position.evaluate(color);
	
	vchess::Moves turns = position.genMoves(color, vchess::Position());
	
	std::vector<vchess::Move>::iterator it = turns.begin();
	
#pragma mark - TODO фильтр для чистки ошибочных ходов
	while (it != turns.end() && alpha < beta) {
		vchess::Move m = *it;
		bool moveColor = vchess::COLOR(position.state().cellAt(m.from));
		if (moveColor != color) {
//			NSLog(@"error move %s", m.notation().c_str());
			it = turns.erase(it);
		} else {
			it++;
		}
	}

	it = turns.begin();
	while (it != turns.end() && alpha < beta) {
		vchess::Move m = *it;
		position.pushState();
		position.doMove(m);
		int tmp = -search(position, !color, depth-1, -beta, -alpha);
		position.popState();
		if (tmp > alpha) {
			alpha = tmp;
			if (depth == DEPTH) {
				best_move = m;
			}
		}
		it++;
	}
	return alpha;
}

- (void)bestMove
{
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	best_move = vchess::Move();
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
		if (_isDebut) {
			best_move = [self searchFromBook];
		}
		if (best_move.moveType == vchess::NotMove) {
			_isDebut = NO;
			best_move = vchess::Move();
			DEPTH = _depth;
			search(_currentGame, _desk.activeColor, DEPTH, -vchess::W_INFINITY, vchess::W_INFINITY);
		}
		[self logMove:best_move];
		dispatch_async(dispatch_get_main_queue(), ^()
					   {
						   [MBProgressHUD hideHUDForView:self.view animated:YES];
						   if (best_move.moveType != vchess::NotMove) {
							   [_desk makeMove:best_move
										inGame:&_currentGame
									completion:^(BOOL success)
							   {
								   if (success) {
									   _moves.push_back(best_move);
									   [_table reloadData];
									   [self switchColor];
									   _desk.userInteractionEnabled = YES;
//									   [self bestMove];
								   } else {
									   [self surrender];
								   }
							   }];
						   } else {
							   [self surrender];
						   }
					   });
	});
}

@end
