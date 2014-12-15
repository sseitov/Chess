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

@interface GameController () {
	
	vchess::Disposition _currentGame;
	int _turnTime;
	vchess::Moves _moves;
}

@property (weak, nonatomic) IBOutlet Desk *desk;

@property (strong, nonatomic) LostFigures *whiteLostFigures;
@property (strong, nonatomic) LostFigures *blackLostFigures;

@property (strong, nonatomic) UIButton* startButton;
@property (strong, nonatomic) UIButton* stopButton;
@property (strong, nonatomic) UIButton* levelButton;
@property (strong, nonatomic) UIButton* notationButton;

@property (strong, nonatomic) UISegmentedControl *timerView;
@property (strong, nonatomic) NSTimer *timer;

@property (readwrite, nonatomic) BOOL userColor;

@property (strong, nonatomic) UITableView* table;

@property (readwrite, nonatomic) BOOL isDebut;
@property (strong, nonatomic) NSArray *debutBook;
@property (readwrite, nonatomic) enum Depth depth;

@end

@implementation GameController

+ (UIButton*)buttonWithSize:(CGSize)size
{
	UIColor* btnColor = [UIColor whiteColor];
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[button setTitleColor:btnColor forState:UIControlStateNormal];
	button.backgroundColor = [UIColor grayColor];
	button.layer.borderWidth = 1.0;
	button.layer.masksToBounds = YES;
	button.layer.cornerRadius = 10.0;
	button.layer.borderColor = btnColor.CGColor;
	return button;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Pocket Chess";
	_desk.image = [UIImage imageNamed:@"ChessDesk"];
	
	_whiteLostFigures = [[LostFigures alloc] initWithFrame:CGRectZero];
	[self.view addSubview:_whiteLostFigures];
	_blackLostFigures = [[LostFigures alloc] initWithFrame:CGRectZero];
	[self.view addSubview:_blackLostFigures];
	
	_startButton = [GameController buttonWithSize:CGSizeMake(100, 30)];
	[_startButton setTitle:@"Start" forState:UIControlStateNormal];
	[_startButton addTarget:self action:@selector(doStartGame) forControlEvents:UIControlEventTouchDown];
	
	_stopButton = [GameController buttonWithSize:CGSizeMake(100, 30)];
	[_stopButton setTitle:@"Surrender" forState:UIControlStateNormal];
	[_stopButton addTarget:self action:@selector(doStopGame) forControlEvents:UIControlEventTouchDown];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_startButton];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(rotate)];
	self.navigationItem.rightBarButtonItem.tintColor = [UIColor grayColor];
	
	_depth = Fast;
	_levelButton = [GameController buttonWithSize:CGSizeMake(140, 30)];
	[_levelButton setTitle:@"Fast mode" forState:UIControlStateNormal];
	[_levelButton addTarget:self action:@selector(setLevel:) forControlEvents:UIControlEventTouchDown];
	_notationButton = [GameController buttonWithSize:CGSizeMake(140, 30)];
	[_notationButton setTitle:@"Show Notation" forState:UIControlStateNormal];
	[_notationButton addTarget:self action:@selector(showNotation:) forControlEvents:UIControlEventTouchDown];
	
	srand((unsigned int)time(NULL));
	_debutBook = [[NSArray alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"book" withExtension:@"plist"]];
	

	_desk.delegate = self;

	_timerView = [[UISegmentedControl alloc] initWithItems:@[@"00:00", @"00:00"]];
	_timerView.userInteractionEnabled = NO;
	_timerView.tintColor = [UIColor grayColor];
	[_timerView setWidth:60 forSegmentAtIndex:0];
	[_timerView setWidth:60 forSegmentAtIndex:1];
	
	NSDictionary *attributes = @{UITextAttributeFont: [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.f],
								 UITextAttributeTextColor: [UIColor blackColor],
								 UITextAttributeTextShadowColor: [UIColor clearColor],
								 };
	[_timerView setTitleTextAttributes:attributes forState:UIControlStateNormal];
	
	CGRect frame = CGRectMake(self.view.frame.size.width, 0, 0, self.view.frame.size.height);
	_table = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	_table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	_table.dataSource = self;
	_table.delegate = self;
	_table.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self.view addSubview:_table];
	
	[_desk resetDisposition:_currentGame.state()];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ( UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
		[self arrangeFromOrientation:UIInterfaceOrientationPortrait];
	} else {
		[self arrangeFromOrientation:UIInterfaceOrientationLandscapeLeft];
	}
	
	UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	NSArray* items =  @[[[UIBarButtonItem alloc] initWithCustomView:_levelButton], space, [[UIBarButtonItem alloc] initWithCustomView:_notationButton]];
	[self.navigationController.toolbar setItems:items];
}

- (void)arrangeFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
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
	CGRect frame = _table.frame;
	if (_table.frame.size.width > 0) {
		frame.origin.x = self.view.frame.size.width - TABLE_WIDTH;
	} else {
		frame.origin.x = self.view.frame.size.width;
	}
	[UIView animateWithDuration:0.3f animations:^(){
		_table.frame = frame;
	}];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self arrangeFromOrientation:fromInterfaceOrientation];
}


- (void)rotate
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
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:_stopButton] animated:YES];
	self.navigationItem.titleView = _timerView;
	
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
	_desk.userInteractionEnabled = NO;
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:_startButton] animated:YES];
	self.navigationItem.titleView = nil;
	[_timer invalidate];
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

- (void)showNotation:(UIButton*)sender
{
	CGRect frame = _table.frame;
	if (_table.frame.size.width > 0) {
		[_notationButton setTitle:@"Show Notation" forState:UIControlStateNormal];
		frame.origin.x = self.view.frame.size.width;
		frame.size.width = 0;
	} else {
		[_notationButton setTitle:@"Hide Notation" forState:UIControlStateNormal];
		frame.origin.x = self.view.frame.size.width-TABLE_WIDTH;
		frame.size.width = TABLE_WIDTH;
	}
	[UIView animateWithDuration:.3f animations:^(){
		_table.frame = frame;
		[_table setNeedsLayout];
	}];
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
	
	frame.size.width /= 2;
	frame.origin.x = 0;
	UILabel *white = [[UILabel alloc] initWithFrame:frame];
	white.backgroundColor = [UIColor grayColor];
	white.textColor = [UIColor whiteColor];
	white.textAlignment = NSTextAlignmentCenter;
	white.text = @"WHITE";
	[v addSubview:white];
	
	frame.origin.x = frame.size.width;
	UILabel *black = [[UILabel alloc] initWithFrame:frame];
	black.backgroundColor = [UIColor grayColor];
	black.textColor = [UIColor whiteColor];
	black.textAlignment = NSTextAlignmentCenter;
	black.text = @"BLACK";
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

- (void)setLevel:(UIButton *)sender
{
	if (_depth == Fast) {
		_depth = Strong;
		[_levelButton setTitle:@"Strong mode" forState:UIControlStateNormal];
	} else {
		_depth = Fast;
		[_levelButton setTitle:@"Fast mode" forState:UIControlStateNormal];
	}
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
	NSMutableArray *matchesArray = [NSMutableArray array];
	if ([text isEqual:@""]) {
		[matchesArray addObjectsFromArray:_debutBook];
	} else {
		for (NSString *line in _debutBook) {
			if ([line rangeOfString:text].location == 0 && line.length > text.length) {
				[matchesArray addObject:line];
			}
		}
	}
	if (matchesArray.count == 0) {
		return vchess::Move();
	}
	int index = rand() % matchesArray.count;
	NSArray *bookTurns = [[matchesArray objectAtIndex:index] componentsSeparatedByString:@" "];
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

static vchess::Position checkPos(7, 0);

int search(vchess::Disposition position, bool color, int depth, int alpha, int beta)
{
	if (depth == 0) return position.evaluate(color);
	
	vchess::Moves turns = position.genMoves(color, vchess::Position());
	
	std::vector<vchess::Move>::iterator it = turns.begin();
	if (depth == DEPTH) {
//		NSLog(@"SEARCH FOR COLOR %d =================================", color);
		while (it != turns.end() && alpha < beta) {
			vchess::Move m = *it;
			bool moveColor = vchess::COLOR(position.state().cellAt(m.from));
			if (moveColor != color) {
//				NSLog(@"error move %s", m.notation().c_str());
				it = turns.erase(it);
			} else {
				it++;
			}
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
									   NSLog(@"ERROR TURN");
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
