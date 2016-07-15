//
//  NDLocalCacheManager.h
//  NDBag
//
//  Created by 新界教育 on 16/7/4.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NDLocalCacheManager : NSObject

+ (NDLocalCacheManager *)sharedManager;

- (void)clearLocalCache;

@end
