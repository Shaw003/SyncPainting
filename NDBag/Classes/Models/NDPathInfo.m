//
//  NDPathInfo.m
//  NDBag
//
//  Created by 新界教育 on 16/7/6.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import "NDPathInfo.h"

@implementation NDPathInfo

//对接收到的坐标值根据接收到的分辨率进行转换
- (CGFloat)x {
  
    CGFloat widthFactor = SCREEN_WIDTH / _screenWidth * 1.f;
    return _x * widthFactor;
}

- (CGFloat)y {
    CGFloat heightFactor;
    if (CURRENT_DEVICE > 7) {
        heightFactor = (SCREEN_HEIGHT - 20 - TOPVIEW_HEIGHT - TOOLBAR_HEIGHT) / _screenHeight * 1.f;
    } else {
        heightFactor = (SCREEN_HEIGHT - 64) / _screenHeight * 1.f;
    }
    
    return _y * heightFactor;
}
@end
