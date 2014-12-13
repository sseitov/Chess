//
//  TableViewCell.h
//  Chess
//
//  Created by Sergey Seitov on 12.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "disposition.h"

#define TABLE_WIDTH	200

@interface TableViewCell : UITableViewCell

- (id)initWithMove:(const vchess::Move&)white black:(const vchess::Move&)black;

@end
