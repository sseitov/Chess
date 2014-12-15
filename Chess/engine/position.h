//
//  position.h
//  Pocket Chess
//
//  Created by Sergey Seitov on 04.08.13.
//  Copyright (c) 2013 V-Channel. All rights reserved.
//

#ifndef __Pocket_Chess__position__
#define __Pocket_Chess__position__

#include <string>
#include <vector>
#include <stdexcept>

namespace vchess {
	
	class Position {
		int		_x;
		int		_y;
		bool	_isNull;
		
	public:
		Position() : _x(-1), _y(-1), _isNull(true) {}
		Position(int x, int y) : _x(x), _y(y), _isNull(false) {}
		Position(const Position& pos) : _x(pos._x), _y(pos._y), _isNull(pos._isNull) {}
		Position(std::string notation)
		{
			_isNull = false;
			_x = notation[0] - 'a';
			_y = notation[1] - '1';
			if (out_of_desk()) {
				throw std::logic_error("position out of desk");
			}
		}
		
		int x() const { return _x; }
		int y() const { return _y; }
		bool isNull() const { return _isNull; }
		
		bool out_of_desk() const
		{
			return (_x < 0 || _x > 7 || _y < 0 || _y > 7);
		}
		
		std::string notation() const
		{
			if (out_of_desk()) {
				return "out of desk";
			} else if (isNull()) {
				return "Null";
			} else {
				std::string text;
				text.push_back('a'+_x);
				text.push_back('1'+_y);
				return text;
			}
		}
		
		bool operator==(const Position& pos) const
		{
			return (pos._x == _x && pos._y == _y);
		}
		Position operator+(const Position& pos)
		{
			return Position(_x+pos._x, _y+pos._y);
		}
	
	};
	
	typedef std::vector<Position> Positions;
}

#endif /* defined(__Pocket_Chess__position__) */
