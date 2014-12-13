//
//  evaluate.cpp
//  Pocket Chess
//
//  Created by Sergey Seitov on 27.07.13.
//  Copyright (c) 2013 V-Channel. All rights reserved.
//

#include "disposition.h"

static int Flip[64] = {
	56,  57,  58,  59,  60,  61,  62,  63,
	48,  49,  50,  51,  52,  53,  54,  55,
	40,  41,  42,  43,  44,  45,  46,  47,
	32,  33,  34,  35,  36,  37,  38,  39,
	24,  25,  26,  27,  28,  29,  30,  31,
	16,  17,  18,  19,  20,  21,  22,  23,
	8,   9,  10,  11,  12,  13,  14,  15,
	0,   1,   2,   3,   4,   5,   6,   7
};

static int PawnWeight[64] = {
	0,  0,  0,  0,  0,  0,  0,  0,
	50, 50, 50, 50, 50, 50, 50, 50,
	10, 10, 20, 30, 30, 20, 10, 10,
	5,  5, 10, 25, 25, 10,  5,  5,
	0,  0,  0, 20, 20,  0,  0,  0,
	5, -5,-10,  0,  0,-10, -5,  5,
	5, 10, 10,-20,-20, 10, 10,  5,
	0,  0,  0,  0,  0,  0,  0,  0
};

static int KnightWeight[64] = {
	-50,-40,-30,-30,-30,-30,-40,-50,
	-40,-20,  0,  0,  0,  0,-20,-40,
	-30,  0, 10, 15, 15, 10,  0,-30,
	-30,  5, 15, 20, 20, 15,  5,-30,
	-30,  0, 15, 20, 20, 15,  0,-30,
	-30,  5, 10, 15, 15, 10,  5,-30,
	-40,-20,  0,  5,  5,  0,-20,-40,
	-50,-40,-30,-30,-30,-30,-40,-50
};

static int BishopWeight[64] = {
	-20,-10,-10,-10,-10,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5, 10, 10,  5,  0,-10,
	-10,  5,  5, 10, 10,  5,  5,-10,
	-10,  0, 10, 10, 10, 10,  0,-10,
	-10, 10, 10, 10, 10, 10, 10,-10,
	-10,  5,  0,  0,  0,  0,  5,-10,
	-20,-10,-10,-10,-10,-10,-10,-20
};

static int RookWeight[64] = {
	0,  0,  0,  0,  0,  0,  0,  0,
	5, 10, 10, 10, 10, 10, 10,  5,
   -5,  0,  0,  0,  0,  0,  0, -5,
   -5,  0,  0,  0,  0,  0,  0, -5,
   -5,  0,  0,  0,  0,  0,  0, -5,
   -5,  0,  0,  0,  0,  0,  0, -5,
   -5,  0,  0,  0,  0,  0,  0, -5,
	0,  0,  0,  5,  5,  0,  0,  0
};

static int QueenWeight[64] = {
	-20,-10,-10, -5, -5,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5,  5,  5,  5,  0,-10,
	 -5,  0,  5,  5,  5,  5,  0, -5,
	  0,  0,  5,  5,  5,  5,  0, -5,
	-10,  5,  5,  5,  5,  5,  0,-10,
	-10,  0,  5,  0,  0,  0,  0,-10,
	-20,-10,-10, -5, -5,-10,-10,-20
};

// king middle game
static int KingWeight[64] = {
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-20,-30,-30,-40,-40,-30,-30,-20,
	-10,-20,-20,-20,-20,-20,-20,-10,
	 20, 20,  0,  0,  0,  0, 20, 20,
	 20, 30, 10,  0,  0, 10, 30, 20
};

// king end game
static int KingEndWeight[64] = {
	-50,-40,-30,-20,-20,-30,-40,-50,
	-30,-20,-10,  0,  0,-10,-20,-30,
	-30,-10, 20, 30, 30, 20,-10,-30,
	-30,-10, 30, 40, 40, 30,-10,-30,
	-30,-10, 30, 40, 40, 30,-10,-30,
	-30,-10, 20, 30, 30, 20,-10,-30,
	-30,-30,  0,  0,  0,  0,-30,-30,
	-50,-30,-30,-30,-30,-30,-30,-50
};

#define INDEX(x,y) ((y<<3) + x)

namespace vchess {
	
	int positionWeight(unsigned char cell, int x, int y, bool endGame)
	{
		switch (FIGURE(cell)) {
			case PAWN:
				if (COLOR(cell)) {
					return PawnWeight[INDEX(x, y)];
				} else {
					return PawnWeight[Flip[INDEX(x, y)]];
				}
			case KNIGHT:
				if (COLOR(cell)) {
					return KnightWeight[INDEX(x, y)];
				} else {
					return KnightWeight[Flip[INDEX(x, y)]];
				}
			case BISHOP:
				if (COLOR(cell)) {
					return BishopWeight[INDEX(x, y)];
				} else {
					return BishopWeight[Flip[INDEX(x, y)]];
				}
			case ROOK:
				if (COLOR(cell)) {
					return RookWeight[INDEX(x, y)];
				} else {
					return RookWeight[Flip[INDEX(x, y)]];
				}
			case QUEEN:
				if (COLOR(cell)) {
					return QueenWeight[INDEX(x, y)];
				} else {
					return QueenWeight[Flip[INDEX(x, y)]];
				}
			case KING:
				if (endGame) {
					if (COLOR(cell)) {
						return KingEndWeight[INDEX(x, y)];
					} else {
						return KingEndWeight[Flip[INDEX(x, y)]];
					}
				} else {
					if (COLOR(cell)) {
						return KingWeight[INDEX(x, y)];
					} else {
						return KingWeight[Flip[INDEX(x, y)]];
					}
				}
			default:
				return 0;
		}
	}
	
	int Disposition::evaluate(bool color)
	{
		int score[2] = {0, 0};
		for (int y=0; y<8; y++) {
			for (int x=0; x<8; x++) {
				unsigned char cell = _state.cells[x][y];
				if (cell == 0) {
					continue;
				}
				if (COLOR(cell)) {
					score[1] += WEIGHT[FIGURE(cell)];
					score[1] += positionWeight(cell, x, y, _endGame);
				} else {
					score[0] += WEIGHT[FIGURE(cell)];
					score[0] += positionWeight(cell, x, y, _endGame);
				}
			}
		}
		
		if (color)
			return score[1] - score[0];
		else
			return score[0] - score[1];
	}
}
