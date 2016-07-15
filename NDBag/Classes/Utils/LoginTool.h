//
//  LoginTool.h
//  XMPPTest0520
//
//  Created by 新界教育 on 16/5/20.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginTool : NSObject
singleton_interface(LoginTool)

- (NSString *)generateAUserNameForLoginToXMPPServer;

- (NSString *)generateNickNameForJoinToXMPPRoom;
@end
