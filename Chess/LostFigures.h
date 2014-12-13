//
//  LostFigures.h
//  Chess
//
//  Created by Сергей Сейтов on 10.10.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FigureView;

@interface LostFigures : UIView

- (void)clear;
- (void)addFigure:(FigureView*)figure;
- (void)removeFigure:(FigureView*)figure;

@end
