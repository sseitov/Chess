//
//  disposition.cpp
//  Chess
//
//  Created by Sergey Seitov on 08.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#include "disposition.h"

using namespace vchess;

void GameState::print()
{
	for (int j=7; j>=0; j--) {
		for (int i=0; i<8; i++) {
			const char* text;
			unsigned char cell = cells[i][j];
			switch (FIGURE(cell)) {
				case PAWN:
					text = "p";
					break;
				case ROOK:
					text = "R";
					break;
				case KNIGHT:
					text = "N";
					break;
				case BISHOP:
					text = "B";
					break;
				case QUEEN:
					text = "Q";
					break;
				case KING:
					text = "K";
					break;
				default:
					if (cell == 0) {
						text = "--";
					} else {
						text = "XX";
					}
					break;
			}
			if (cell != 0) {
				const char* color = COLOR(cell) ? "b" : "w";
				printf("%s%s ", text, color);
			} else {
				printf("%s ", text);
			}
		}
		printf("\n");
	}
	printf("\n");
}

void GameState::reset()
{
	for (int i=0; i<8; i++) {
		for (int j=0; j<8; j++) {
			cells[i][j] = 0;
		}
	}
	
	for (int i=0; i<8; i++) {
		cells[i][1] = PAWN;
	}
	cells[4][0] = KING;
	cells[3][0] = QUEEN | RIGHT;
	cells[2][0] = BISHOP;
	cells[1][0] = KNIGHT;
	cells[0][0] = ROOK;
	cells[5][0] = BISHOP | RIGHT;
	cells[6][0] = KNIGHT | RIGHT;
	cells[7][0] = ROOK | RIGHT;
	
	for (int i=0; i<8; i++) {
		cells[i][6] = PAWN | COLOR_MASK;
	}
	cells[4][7] = KING | COLOR_MASK;
	cells[3][7] = QUEEN | RIGHT | COLOR_MASK;
	cells[2][7] = BISHOP | COLOR_MASK;
	cells[1][7] = KNIGHT | COLOR_MASK;
	cells[0][7] = ROOK | COLOR_MASK;
	cells[5][7] = BISHOP | RIGHT | COLOR_MASK;
	cells[6][7] = KNIGHT | RIGHT | COLOR_MASK;
	cells[7][7] = ROOK | RIGHT | COLOR_MASK;
}

bool GameState::isEqual(const GameState& other)
{
	for (int y=0; y<8; y++) {
		for (int x=0; x<8; x++) {
			unsigned char c1 = cells[x][y];
			unsigned char c2 = other.cells[x][y];
			if (c1 == 0 && c2 == 0) {
				continue;
			}
			if (FIGURE(c1) != FIGURE(c2) || COLOR(c1) != COLOR(c2)) {
				return false;
			}
		}
	}
	return true;
}

unsigned char GameState::cellAt(Position pos)
{
	if (pos.x() < 0 || pos.x() > 7 || pos.y() < 0 || pos.y() > 7) {
		throw std::logic_error("position out of desk");
	} else {
		return cells[pos.x()][pos.y()];
	}
}

void GameState::setCell(unsigned char cell, Position pos)
{
	cells[pos.x()][pos.y()] = cell;
}

////////////////////////////////////////////////////////////////////

void Disposition::reset()
{
	_state.reset();
	_endGame = false;
}
/*
const std::string Disposition::moveNotation(const Move& m)
{
	std::string notation;
	if (m.moveType == QueenCastling) {
		notation = "O-O-O";
	} else if (m.moveType == KingCastling) {
		notation = "O-O";
	} else {
		switch (FIGURE(_state.cellAt(m.to))) {
			case KING:
				notation = "K";
				break;
			case QUEEN:
				notation = "Q";
				break;
			case ROOK:
				notation = "R";
				break;
			case BISHOP:
				notation = "B";
				break;
			case KNIGHT:
				notation = "N";
				break;
			default:
				notation = "";
				break;
		}
		notation += m.from.notation();
		notation += m.to.notation();
		if (m.moveType == Capture || m.moveType == EnPassant) {
			notation += "x";
		}
	}
	return notation;
}
*/
bool Disposition::checkEnd()
{
	int queen[2] = {0, 0};
	int other[2] = {0, 0};
	for (int i=0; i<8; i++) {
		for (int j=0; j<8; j++) {
			unsigned char cell = _state.cells[i][j];
			if (FIGURE(cell) == QUEEN) {
				if (COLOR(cell)) {
					queen[0]++;
				} else {
					queen[1]++;
				}
			} else if (FIGURE(cell)==KNIGHT || FIGURE(cell) == BISHOP || FIGURE(cell) == ROOK) {
				if (COLOR(cell)) {
					other[0]++;
				} else {
					other[1]++;
				}
			}
		}
	}
	if (queen[0] == 0 && queen[1] == 0) {
		return true;
	} else if (queen[0] > 0) {
		return (other[0] == 0);
	} else {
		return (other[1] == 0);
	}
}

void Disposition::doMove(const Move& move)
{
	bool color = COLOR(_state.cellAt(move.from));
	unsigned char figure = _state.cellAt(move.from) | MOVED;
	if (FIGURE(figure) == PAWN && move.firstMove) {
		figure |= FIRST_MOVE;
	}
	if (move.promote) {							// promote pawn to queen
		figure = QUEEN | MOVED;
		if (color) {
			figure |= COLOR_MASK;
		}
	}
	
	_state.setCell(0, move.from);			// clear "from" position
	if (!move.capturePosition.isNull()) {	// clear "capture" position
		_state.setCell(0, move.capturePosition);
	}
	_state.setCell(figure, move.to);		// move figure to "to" position
	
	int y = color ? 7 : 0;
	if (move.moveType == QueenCastling) {		// move ROOK if castling
		_state.setCell(_state.cellAt(Position(0, y)) | MOVED, Position(3,y));
		_state.setCell(0, Position(0, y));
	} else if (move.moveType == KingCastling) {
		_state.setCell(_state.cellAt(Position(7, y)) | MOVED, Position(5,y));
		_state.setCell(0, Position(7, y));
	}
	
	if (!_endGame) {
		_endGame = checkEnd();
	}
}

#pragma mark - move generation

bool Disposition::checkFor(bool color)
{
	Moves opMoves = capturesFor(!color);
	for (int i=0; i<opMoves.size(); i++) {
		Move m = opMoves[i];
		if (FIGURE(_state.cellAt(m.to)) == KING && COLOR(_state.cellAt(m.to)) == color)
			return true;
	}
	return false;
}

Moves Disposition::genMoves(bool color, const Position& from)
{
	Moves allMoves = capturesFor(color);
	if (!from.isNull()) {	// filter by position
		std::vector<Move>::iterator it = allMoves.begin();
		while (it != allMoves.end()) {
			if (it->from == from) {
				it++;
			} else {
				it = allMoves.erase(it);
			}
		}
	}
	for (int y=0; y<8; y++) {
		for (int x=0; x<8; x++) {
			if (from.isNull() || from == Position(x, y)) {
				unsigned char cell = _state.cells[x][y];
				if (cell && COLOR(cell) == color) {
					vchess::Moves movePositions = possibleFrom(Position(x, y));
					allMoves.insert(allMoves.end(), movePositions.begin(), movePositions.end());
				}
			}
		}
	}
	
	// filter by check anf setup promote
	std::vector<Move>::iterator it = allMoves.begin();
	it = allMoves.begin();
	bool isCheckBefore = checkFor(color);
	while (it != allMoves.end()) {
		if (!IS_MOVED(_state.cellAt(it->from))) {
			it->firstMove = true;
		}
		
		if ((it->moveType == QueenCastling || it->moveType == KingCastling) && isCheckBefore) {
			it = allMoves.erase(it);
			continue;
		}
		
		pushState();
		doMove(*it);
		bool isCheck = checkFor(color);
		popState();
		
		if (isCheck) {
			it = allMoves.erase(it);
		} else {
			int promoteLine = color ? 0 : 7;
			it->promote = (FIGURE(_state.cellAt(it->from)) == PAWN && it->to.y() == promoteLine);
			it++;
		}
	}

	return allMoves;
}

static Position deltaPos[5][9] = {
	{Position(-2, 1), Position(-1, 2), Position(1, 2), Position( 2, 1), Position(-2,-1), Position(-1,-2), Position(1, -2), Position( 2,-1), Position()},	// KNIGHT
	{Position(-1, 1), Position( 1, 1), Position(1,-1), Position(-1,-1), Position(), Position(), Position(), Position(), Position()},						// BISHOP
	{Position(-1, 0), Position( 0, 1), Position(1, 0), Position( 0,-1), Position(), Position(), Position(), Position(), Position()},						// ROOK
	{Position(-1, 0), Position(-1, 1), Position(0, 1), Position( 1, 1), Position( 1, 0), Position( 1,-1), Position(0, -1), Position(-1,-1), Position()},	// QUEEN
	{Position(-1, 0), Position(-1, 1), Position(0, 1), Position( 1, 1), Position( 1, 0), Position( 1,-1), Position(0, -1), Position(-1,-1), Position()}		// KING
};
static bool makeLine[5] = {false, true, true, true, false};

Moves Disposition::capturesFor(bool color)
{
	// create list for captures (по порядоку уменьшения веса взятой фигуры)
	struct FIG_POS {
		Figure fig;
		Position pos;
		bool operator<(const FIG_POS &rhs) const { return WEIGHT[fig] < WEIGHT[rhs.fig]; }
	};
	std::vector<FIG_POS> list;
	for (int y=0; y<8; y++) {
		for (int x=0; x<8; x++) {
			unsigned char cell = _state.cells[x][y];
			if (cell && COLOR(cell) != color) {
				FIG_POS fp;
				fp.fig = FIGURE(cell);
				fp.pos = Position(x,y);
				list.push_back(fp);
				int enline = COLOR(cell) ? 4 : 3;
				if (FIGURE(cell) == PAWN && IS_FIRST_MOVE(cell) && y == enline) {
					FIG_POS fp;
					fp.fig = FIGURE(cell);
					fp.pos = COLOR(cell) ? Position(x,y+1) : Position(x,y-1);
					list.push_back(fp);
				}
			}
		}
	}
	std::sort(list.rbegin(), list.rend());
	
	// create captures (по порядоку увеличения веса берущей фигуры)
	Moves captures;
	for (int i=0; i<list.size(); i++) {
		Moves pawns = capturesPawnFor(list[i].pos, color);
		for (int figure=KNIGHT; figure>=KING; figure--) {
			Moves figures = capturesFigureFor(list[i].pos, (Figure)figure);
			pawns.insert(pawns.end(), figures.begin(), figures.end());
		}
		captures.insert(captures.end(), pawns.begin(), pawns.end());
	}
	return captures;
}

Moves Disposition::capturesPawnFor(Position pos, bool color)
{
	Moves captures;
	int direction = color ? 1 : -1;
	Position left = pos + Position(-1, direction);
	if (!left.out_of_desk()) {
		if (FIGURE(_state.cellAt(left)) == PAWN && COLOR(_state.cellAt(left)) != COLOR(_state.cellAt(pos))) {
			Move m(PAWN, left, pos, Capture);
			m.capturePosition = pos;
			m.captureFigure = FIGURE(_state.cellAt(pos));
			captures.push_back(m);
		}
	}
	Position right = pos + Position(1, direction);
	if (!right.out_of_desk()) {
		if (FIGURE(_state.cellAt(right)) == PAWN && COLOR(_state.cellAt(right)) != COLOR(_state.cellAt(pos))) {
			Move m(PAWN, right, pos, Capture);
			m.capturePosition = pos;
			m.captureFigure = FIGURE(_state.cellAt(pos));
			captures.push_back(m);
		}
	}
	int enline = COLOR(_state.cellAt(pos)) ? 2 : 5;
	Position pawn = pos + Position(0, direction);
	if (_state.cellAt(pos) == 0) {
		if (_state.cellAt(pos) == 0 && pos.y() == enline &&
			FIGURE(_state.cellAt(pawn)) == PAWN && IS_FIRST_MOVE(_state.cellAt(pawn))) {
			left = pos + Position(-1, direction);
			if (!left.out_of_desk()) {
				if (FIGURE(_state.cellAt(left)) == PAWN && COLOR(_state.cellAt(left)) == color) {
					Move m(PAWN, left, pos, EnPassant);
					m.capturePosition = pawn;
					m.captureFigure = _state.cellAt(pawn);
					captures.push_back(m);
				}
			}
			right = pos + Position(1, direction);
			if (!right.out_of_desk()) {
				if (FIGURE(_state.cellAt(right)) == PAWN && COLOR(_state.cellAt(right)) == color) {
					Move m(PAWN, right, pos, EnPassant);
					m.capturePosition = pawn;
					m.captureFigure = _state.cellAt(pawn);
					captures.push_back(m);
				}
			}
		}
	}
	return captures;
}

Moves Disposition::capturesFigureFor(Position from, Figure figure)
{
	Moves captures;
	int index = KNIGHT - figure;
	Position *delta = deltaPos[index];
	bool line = makeLine[index];
	int i = 0;
	while  (!delta[i].isNull()) {
		Position pos = from + delta[i];
		if (pos.out_of_desk()) {
			i++;
			continue;
		}
		if (line) {
			while (!pos.out_of_desk() && _state.cellAt(pos) == 0) {
				pos = pos + delta[i];
			}
		}
		if (!pos.out_of_desk()) {
			if (FIGURE(_state.cellAt(pos)) == figure &&
				COLOR(_state.cellAt(from)) != COLOR(_state.cellAt(pos)))
			{
				Move m(figure, pos, from, Capture);
				m.capturePosition = from;
				m.captureFigure = _state.cellAt(from);
				captures.push_back(m);
			}
		}
		i++;
	}
	
	return captures;
}

Moves Disposition::possibleFrom(Position pos)
{
	unsigned char cell = _state.cells[pos.x()][pos.y()];
	if (FIGURE(cell) == KING) {
		return possibleKingFrom(pos);
	} else if (FIGURE(cell) == PAWN) {
		return possiblePawnFrom(pos);
	} else {
		return possibleFigureFrom(pos);
	}
}

Moves Disposition::possiblePawnFrom(Position pos)
{
	Moves possible;
	int direction = COLOR(_state.cellAt(pos)) ? -1 : 1;
	
	Position p = pos + Position(0, direction);
	if (!p.out_of_desk() && _state.cellAt(p) == 0) {
		possible.push_back(Move(PAWN, pos, p, Normal));
	} else {
		return possible;
	}
	if (!IS_MOVED(_state.cellAt(pos))) {
		Position p = pos + Position(0, direction*2);
		if (!p.out_of_desk() && _state.cellAt(p) == 0) {
			possible.push_back(Move(PAWN, pos, p, Normal));
		}
	}
	return possible;
}

Moves Disposition::possibleKingFrom(Position from)
{
	Moves possible = possibleFigureFrom(from);
	unsigned char king = _state.cellAt(from);
	if (!IS_MOVED(king)) {
		unsigned char leftRook,rightRook;
		int y = COLOR(king) ? 7 : 0;
		leftRook = _state.cells[0][y];
		if (vchess::IS_RIGHT(leftRook)) {
			leftRook = 0;
		}
		rightRook = _state.cells[7][y];
		if (!vchess::IS_RIGHT(rightRook)) {
			rightRook = 0;
		}
		if (leftRook && !IS_MOVED(leftRook)) {
			bool isCastling = true;
			for (int i=1; i<4; i++) {
				if (_state.cells[i][y]) {
					isCastling = false;
					break;
				}
			}
			if (isCastling) {
				Move m(KING, from, Position(2, y), QueenCastling);
				possible.push_back(m);
			}
		}
		if (rightRook && !IS_MOVED(rightRook)) {
			bool isCastling = true;
			for (int i=5; i<7; i++) {
				if (_state.cells[i][y]) {
					isCastling = false;
					break;
				}
			}
			if (isCastling) {
				Move m(KING, from, Position(6, y), KingCastling);
				possible.push_back(m);
			}
		}
	}
	return possible;
}

Moves Disposition::possibleFigureFrom(Position from)
{
	Moves possible;
	int index = KNIGHT - FIGURE(_state.cellAt(from));
	Position *delta = deltaPos[index];
	bool line = makeLine[index];
	int i = 0;
	while  (!delta[i].isNull()) {
		Position pos = from + delta[i];
		if (pos.out_of_desk()) {
			i++;
			continue;
		}
		if (line) {
			while (!pos.out_of_desk() && _state.cellAt(pos) == 0) {
				possible.push_back(Move(FIGURE(_state.cellAt(from)), from, pos, Normal));
				pos = pos + delta[i];
			}
		}
		if (!pos.out_of_desk()) {
			if (_state.cellAt(pos) == 0) {
				possible.push_back(Move(FIGURE(_state.cellAt(from)), from, pos, Normal));
			}
		}
		i++;
	}
	
	return possible;
}

