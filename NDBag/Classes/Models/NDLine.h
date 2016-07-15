//
//  NDLine.h
//  NDBag
//
//  Created by 新界教育 on 16/7/7.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NDLine : NSObject

@property (nonatomic, strong) NSMutableArray *points;

@property (nonatomic, strong) UIColor *color;

@property (nonatomic, assign) CGFloat size;

@end
