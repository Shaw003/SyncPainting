//
//  NDCanvasView.h
//  NDBag
//
//  Created by 新界教育 on 16/7/4.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NDTeacherLineModel.h"
#import "NDPathInfo.h"
#import "NDLine.h"

#import "NDStudentLineModel.h"

@protocol NDCanvasViewDelegate <NSObject>

- (void)didDraw;


@end

@interface NDCanvasView : UIView
// 所有笔画
@property (nonatomic, strong) NSMutableArray *strokesArr;
// 丢弃(撤销)的笔画
@property (nonatomic, strong) NSMutableArray *abandonedStrokesArr;
// 当前笔刷颜色
@property (nonatomic, strong) UIColor *currentColor;
// 当前的笔刷大小
@property (nonatomic, assign) CGFloat currentSize;

@property (nonatomic, assign) id<NDCanvasViewDelegate> delegate;




/**  线条 ***/
@property (nonatomic, strong) NDTeacherLineModel *currentLine;

@property (nonatomic, strong) NDPathInfo *pathInfo;


//接收的内容
@property (nonatomic, strong) NDTeacherLineModel *receivedLine;

@property (nonatomic, strong) NDPathInfo *receivedPathInfo;

@property (nonatomic, assign) int receivedAction;

@property (nonatomic, strong) NSMutableArray *receivedStrokesArr;

//学生
@property (nonatomic, strong) NDStudentLineModel *studentLine;
@property (nonatomic, strong) NSMutableArray *receivedStudentStrokesArr;

@property (nonatomic, strong) NDStudentLineModel *tempLine;
//画笔光标
@property (nonatomic, strong) UIImageView *penIV;
@end
