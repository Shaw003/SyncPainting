//
//  NDPathInfo.h
//  NDBag
//
//  Created by 新界教育 on 16/7/6.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NDPathInfo : NSObject

@property (nonatomic, assign) CGFloat x;

@property (nonatomic, assign) CGFloat y;

@property (nonatomic, strong) NSString *current_time;

@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, assign) int action;

@property (nonatomic, assign) CGFloat screenHeight;

@property (nonatomic, assign) CGFloat screenWidth;


@end
