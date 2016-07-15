//
//  NDLocalCacheManager.m
//  NDBag
//
//  Created by 新界教育 on 16/7/4.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import "NDLocalCacheManager.h"

@implementation NDLocalCacheManager

+ (NDLocalCacheManager *)sharedManager {
    
    static dispatch_once_t onceToken;
    static NDLocalCacheManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[NDLocalCacheManager alloc] init];
    });
    return manager;
    
}

- (void)clearLocalCache {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IS_TEACHER"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"USER_NAME"];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UserAvatarData.txt"];
    BOOL removed = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (removed) {
        NSError *err;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&err];
    }
}
@end
