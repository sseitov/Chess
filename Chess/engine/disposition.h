//
//  disposition.h
//  Chess
//
//  Created by Sergey Seitov on 08.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#ifndef __Chess__disposition__
#define __Chess__disposition__

#include "position.h"
#include "figure.h"
#include "move.h"

namespace vchess {
	
	class GameState {
		friend class Disposition;

		unsigned char cells[8][8];
		unsigned char saved[8][8];
	public:
		GameState()
		{
			for (int i=0; i<8; i++) {
				for (int j=0; j<8; j++) {
					cells[i][j]=0;
				}
			}
		}
		void print();
		void reset();
		bool isEqual(const GameState& other);
		unsigned char cellAt(Position pos);
		void setCell(unsigned char cell, Position pos);
	};
	
	class Disposition {
	private:
		GameState _state;
		GameState _savedState;
		bool _endGame;
		
	public:
		Disposition()
		{
			reset();
		}
		
		Disposition(const Disposition& other)
		{
			_state = other._state;
			_endGame = other._endGame;
		}
		void reset();
		void pushState()
		{
			_savedState = _state;
		}
		void popState()
		{
			_state = _savedState;
		}
		GameState state() { return _state; }
		
		const std::string moveNotation(const Move& m);
		
		void doMove(const Move& move);

		Moves genMoves(bool color, const Position& from);	// if from.isNull - all moves
		int evaluate(bool color);

	private:
		bool checkFor(bool color);
		bool checkEnd();
		
		Moves capturesFor(bool color);			// white - false, black - true
		Positions capturesPawnFor(Position pos, bool color);
		Positions capturesFigureFor(Position from, Figure figure);
		
		Moves possibleFrom(Position pos);
		Moves possiblePawnFrom(Position pos);
		Moves possibleKingFrom(Position pos);
		Moves possibleFigureFrom(Position pos);
	};
}
#endif /* defined(__Chess__disposition__) */
