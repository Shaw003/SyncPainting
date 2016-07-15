//
//  NDTeacherLineModel.h
//  NDBag
//
//  Created by 新界教育 on 16/7/5.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NDPathInfo.h"


@interface NDTeacherLineModel : NSObject

@property (nonatomic, strong) NSString *function;

@property (nonatomic, strong) NDPathInfo *pathInfo;

@property (nonatomic, assign) int pencolor;


@end
