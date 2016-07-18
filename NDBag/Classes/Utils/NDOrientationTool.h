//
//  NDOrientationTool.h
//  NDBag
//
//  Created by 新界教育 on 16/7/15.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NDOrientationTool : NSObject

singleton_interface(NDOrientationTool)
- (UIImage *)fixOrientation:(UIImage *)aImage;

@end
