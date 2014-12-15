//
//  move.h
//  Pocket Chess
//
//  Created by Sergey Seitov on 04.08.13.
//  Copyright (c) 2013 V-Channel. All rights reserved.
//

#ifndef __Pocket_Chess__move__
#define __Pocket_Chess__move__

#include "position.h"
#include <string>

namespace vchess {
	
	enum MoveType {
		NotMove,
		Normal,
		Capture,
		EnPassant,			// взятие пешкой через битое поле
		QueenCastling,		// рокировки
		KingCastling
	};
	
	struct Move {
		Figure figure;
		Position from;
		Position to;
		MoveType moveType;
		bool promote;				// превращение пешки
		bool firstMove;				// первый ход
		unsigned char captureFigure;
		Position capturePosition;
		
		Move()
			: moveType(NotMove), promote(false), firstMove(false), captureFigure(0)
		{}
		Move(const Move& other)
			: figure(other.figure), from(other.from), to(other.to), moveType(other.moveType), promote(other.promote), firstMove(other.firstMove),
			captureFigure(other.captureFigure), capturePosition(other.capturePosition)
		{}
		Move(Figure _figure, Position _from, Position _to, MoveType _moveType)
			: figure(_figure), from(_from), to(_to), moveType(_moveType), promote(false), firstMove(false), captureFigure(0)
		{}
		
		std::string notation() const
		{
			if (moveType != NotMove) {
				if (moveType == QueenCastling) {
					return "O-O-O";
				} else if (moveType == KingCastling) {
					return "O-O";
				} else {
					std::string text;
					switch (FIGURE(figure)) {
						case KING:
							text = "K";
							break;
						case QUEEN:
							text = "Q";
							break;
						case ROOK:
							text = "R";
							break;
						case BISHOP:
							text = "B";
							break;
						case KNIGHT:
							text = "N";
							break;
						default:
							break;
					}
					
					text += (from.notation() + to.notation());
					if (moveType == Capture || moveType == EnPassant || !capturePosition.isNull())
						text += "x";
					return text;
				}
			} else {
				return "";
			}
		}
		
		std::string shortNotation() const
		{
			if (moveType == NotMove) {
				return "";
			} else {
				return (from.notation() + to.notation());
			}
		}

		bool operator==(const Move& move)
		{
			return (from == move.from && to == move.to && moveType == move.moveType);
		}
	};
	
	typedef std::vector<Move> Moves;
}

#endif /* defined(__Pocket_Chess__move__) */
