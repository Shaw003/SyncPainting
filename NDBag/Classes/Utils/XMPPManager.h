//
//  XMPPManager.h
//  XMPPTest0520
//
//  Created by 新界教育 on 16/5/20.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"


@protocol XMPPManagerDelegate <NSObject>

- (void)authenticatedSuccess;

@end

// 该类主要封装了xmpp的常用方法
@interface XMPPManager : NSObject <XMPPStreamDelegate>

@property(nonatomic,strong) XMPPStream * xmppStream;

@property (nonatomic, weak) id<XMPPManagerDelegate> delegate;
//单例方法
+ (XMPPManager *)defaultManager;
//登录的方法
- (void)loginwithName:(NSString *)userName andPassword:(NSString *)password;
//注册
- (void)registerWithName:(NSString *)userName andPassword:(NSString *)password;

- (void)logout;

- (void)connectToServer;



@end


