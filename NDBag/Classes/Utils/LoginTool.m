//
//  LoginTool.m
//  XMPPTest0520
//
//  Created by 新界教育 on 16/5/20.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import "LoginTool.h"

@implementation LoginTool
singleton_implementation(LoginTool)

- (NSString *)shuffledAlphabet {
    NSMutableString *result = [NSMutableString string];
    NSString *tempString = nil;
    for (int i = 0; i < 6; i++) {
        int number = arc4random() % 36;
        if (number < 10) {
            int figure = arc4random() % 10;
            tempString = [NSString stringWithFormat:@"%d", figure];
            while ([result containsString:tempString]) {
                int figure = arc4random() % 10;
                tempString= [NSString stringWithFormat:@"%d", figure];
            }
            [result appendString:tempString];
        } else {
            int figure = (arc4random() % 26) + 97;
            char character = figure;
            tempString = [NSString stringWithFormat:@"%c", character];
            while ([result containsString:tempString]) {
                int figure = (arc4random() % 26) + 97;
                char character = figure;
                tempString = [NSString stringWithFormat:@"%c", character];
            }
            [result appendString:tempString];
        }
        tempString =nil;
    }
    return result;
}

- (NSString *)generateAUserNameForLoginToXMPPServer {
    return [self shuffledAlphabet];
}

- (NSString *)generateNickNameForJoinToXMPPRoom {
    NSString *nickName = nil;
    if (IS_TEACHER) {
        nickName = [NSString stringWithFormat:@"%u", arc4random() % 100001 + 100000];
        LogBlue(@"产生的nickName = %@", nickName);
        return nickName;
    } else {
        nickName = [NSString stringWithFormat:@"%u", arc4random() % 100001 + 200000];
        LogBlue(@"产生的nickName = %@", nickName);
        return nickName;
        
    }
}
@end
