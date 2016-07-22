//
//  NDStudentLineModel.h
//  NDBag
//
//  Created by 新界教育 on 16/7/11.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NDStudentLineModel : NSObject

@property (nonatomic, strong) NSString *function;

@property (nonatomic, strong) NSMutableArray *pathInfos;

@property (nonatomic, assign) int pencolor;

//修改
@property (nonatomic, strong) NSString *userId;

@end
