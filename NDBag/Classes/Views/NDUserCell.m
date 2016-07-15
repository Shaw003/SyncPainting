//
//  NDUserCell.m
//  NDBag
//
//  Created by 新界教育 on 16/7/11.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import "NDUserCell.h"

@interface NDUserCell ()

@property (nonatomic, strong) UIImageView *userAvatarIV;



@end

@implementation NDUserCell

- (void)setUser:(NDUser *)user {
    
    self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pic_people.jpg"]];
    NSString *iconString = user.userIcon;
    UIImage *avatar = [self stringToUIImage:iconString];
    self.userAvatarIV = [[UIImageView alloc] initWithImage:avatar];
//    //测试
//    self.userAvatarIV.backgroundColor = [UIColor redColor];
//    //结束
    [self.backgroundView addSubview:self.userAvatarIV];
    [self.userAvatarIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.height.equalTo(@86);
    }];
}

//将图片数据转换为图片
- (UIImage *)stringToUIImage:(NSString *)string
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return [UIImage imageWithData:data];
}
@end
