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
		Position from;
		Position to;
		MoveType moveType;
		bool promote;				// превращение пешки
		bool firstMove;				// первый ход
		unsigned char captureFigure;
		Position capturePosition;
		std::string notation;
		
		Move()
			: moveType(NotMove), promote(false), firstMove(false), captureFigure(0)
		{}
		Move(const Move& other)
			: from(other.from), to(other.to), moveType(other.moveType), promote(other.promote), firstMove(other.firstMove),
			captureFigure(other.captureFigure), capturePosition(other.capturePosition), notation(other.notation)
		{}
		Move(Position _from, Position _to, MoveType _moveType)
			: from(_from), to(_to), moveType(_moveType), promote(false), firstMove(false), captureFigure(0)
		{}
		
		std::string shortNotation() const
		{
			if (moveType == NotMove) {
				return "";
			} else {
				std::string text = (from.notation() + to.notation());
				if (moveType == Capture || moveType == EnPassant || !capturePosition.isNull())
					text += "x";
				return text;
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
