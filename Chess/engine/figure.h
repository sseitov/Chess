//
//  figure.h
//  Pocket Chess
//
//  Created by Sergey Seitov on 04.08.13.
//  Copyright (c) 2013 V-Channel. All rights reserved.
//

#ifndef __Pocket_Chess__figure__
#define __Pocket_Chess__figure__

#include <string>

namespace vchess {

	enum Figure {
		KING	= 0x01,
		QUEEN	= 0x02,
		ROOK	= 0x03,
		BISHOP	= 0x04,
		KNIGHT	= 0x05,
		PAWN	= 0x06,
	};
	
	
	// маска для парных фигур и ферзя (дополнительный появляется без флага)
	const unsigned char RIGHT	= 0x10;
	// маска для пешки, короля и ладьи
	const unsigned char MOVED	= 0x20;
	// маска для пешки
	const unsigned char FIRST_MOVE = 0x40;
	// маска цвета
	const unsigned char COLOR_MASK	= 0x80;
	
	const int W_INFINITY	= 100000;
	const int W_PAWN		= 100;
	const int W_KNIGHT		= W_PAWN*3;
	const int W_BISHOP		= W_KNIGHT + 20;
	const int W_ROOK		= W_PAWN*5;
	const int W_QUEEN		= W_PAWN*9;
	const int W_KING		= W_INFINITY;
	
	const int WEIGHT[7] = {0, W_KING, W_QUEEN, W_ROOK, W_BISHOP, W_KNIGHT, W_PAWN};

	inline Figure FIGURE(unsigned char cell) { return (Figure)(cell & 7); }
	inline std::string FIG_NAME(unsigned char cell)
	{
		switch (FIGURE(cell)) {
			case KING:
				return "K";
			case QUEEN:
				return "Q";
			case ROOK:
				return "R";
			case BISHOP:
				return "B";
			case KNIGHT:
				return "N";
			default:
				return "";
		}
	}
	inline bool COLOR(unsigned char cell) { return (cell & COLOR_MASK); }
	inline bool IS_MOVED(unsigned char cell) { return ((cell & MOVED) != 0 || (cell & FIRST_MOVE) != 0); }
	inline bool IS_RIGHT(unsigned char cell) { return (cell & RIGHT); }
	inline bool IS_FIRST_MOVE(unsigned char cell) { return ((cell & FIRST_MOVE) != 0); }
	inline std::string NOTATION(unsigned char cell)
	{
		switch (FIGURE(cell)) {
			case KING:
				return "K";
			case QUEEN:
				return "Q";
			case ROOK:
				return "R";
			case BISHOP:
				return "B";
			case KNIGHT:
				return "N";
			default:
				return "";
		}
	}
}

#endif /* defined(__Pocket_Chess__figure__) */
