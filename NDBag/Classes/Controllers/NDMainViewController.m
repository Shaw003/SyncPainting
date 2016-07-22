//
//  NDMainViewController.m
//  NDBag
//
//  Created by 新界教育 on 16/6/30.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#define BTN_SIDELENGTH 44.f

#import "NDMainViewController.h"

#import "NDLoginViewController.h"
#import "NDCanvasView.h"
#import "XMPPManager.h"
#import "LoginTool.h"
//总体
#import "XMPP.h"
//聊天室
#import "XMPPRoom.h"
//取XMPPStream对象
#import "XMPPManager.h"
//聊天室储存
#import "XMPPRoomCoreDataStorage.h"
//XMPP查询
#import "XMPPIQ.h"
//XMPP聊天室仓库
#import "XMPPRoomHybridStorage.h"


#import "NDTeacherLineModel.h"
#import "NDPathInfo.h"

#import "NDUser.h"

#import "NDUserCell.h"

#import "MJExtension.h"
//调用震动
//iPad 没有震动
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>



@interface NDMainViewController () <XMPPManagerDelegate, XMPPRoomDelegate, XMPPStreamDelegate, NDCanvasViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>



/** 背景视图*/
@property (nonatomic, strong) UIImageView *backgroundIV;
/** 顶部栏*/
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *titleLabel;
/** 清空屏幕按钮*/
@property (nonatomic, strong) UIButton *clearBtn;
/** 切换用户按钮*/
@property (nonatomic, strong) UIButton *switchUserBtn;

/** 保存按钮*/
@property (nonatomic, strong) UIButton *saveBtn;
/** 工具栏*/
@property (nonatomic, strong) UIView *toolBar;
/** 颜色选择按钮*/
@property (nonatomic, strong) UIButton *trackColorBtn;
/** 画笔尺寸选择按钮*/
@property (nonatomic, strong) UIButton *penSizeBtn;
/** 回退按钮*/
@property (nonatomic, strong) UIButton *undoBtn;
/** 学生用户列表按钮*/
@property (nonatomic, strong) UIButton *userListBtn;
/** 学生用户列表背景视图*/
@property (nonatomic, strong) UIImageView *bottomView;
/** 学生用户列表滚动视图*/
@property (nonatomic, strong) UICollectionView *userCollectionView;
/** 画板视图*/
@property (nonatomic, strong) NDCanvasView *canvasView;
/** 清空警告视图*/
@property (nonatomic, strong) UIImageView *alertView;
/** 画笔尺寸视图*/
@property (nonatomic, strong) UIImageView *penSizePickerIV;
/** 画笔尺寸单选按钮数组*/
@property (nonatomic, strong) NSMutableArray *checkboxes;
/** 保存的尺寸*/
@property (nonatomic, strong) NSMutableDictionary *savedSize;
/** XMPP房间*/
@property (nonatomic, strong) XMPPRoom *xmppRoom;
/** XMPP流*/
@property (nonatomic, strong) XMPPStream *xmppStream;
/** XMPP数据库*/
@property (nonatomic, strong) XMPPRoomHybridStorage *xmppRoomStorage;
/** 开启应用的次数*/
@property (nonatomic, assign) NSInteger appOpenCount;
/** 是否第一次开启应用*/
@property (nonatomic, assign) BOOL notFirstStart;
/** XMPP登陆的ID*/
@property (nonatomic, strong) NSString *userID;
/** XMPP加入房间时的NickName*/
@property (nonatomic, strong) NSString *nickName;
/** 学生用户头像视图*/
@property (nonatomic, strong) UIButton *userAvatarBtn;
/** 所有已加入聊天室的学生数组*/
@property (nonatomic, strong) NSMutableArray *allStudentsArray;
/** 合成器*/
@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;
/** 观察者*/
@property (nonatomic, assign, getter=isObserver) BOOL observer;
/** 自己作为老师加入聊天室的时间*/
@property (nonatomic, strong) NSString *joinedTime;
/** 缓存的临时时间*/
@property (nonatomic, strong) NSString *tempTime;
/** 缓存临时时间的数组*/
@property (nonatomic, strong) NSMutableArray *tempTimeArray;
/** 网络状态监听*/
@property (nonatomic, strong) Reachability *hostReach;
@end

@implementation NDMainViewController

singleton_implementation(NDMainViewController)

static NSString * const reuseIdentifier = @"user";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    AppDelegate * app = [UIApplication sharedApplication].delegate;
    app.shouldChangeOrientation = YES;
    
    //初始化界面并对角色做判断
    [self initUI];
    
    self.canvasView.delegate = self;
    
    
    //XMPP部分
    //配置用户设置
    [self configUserDefaults];
    [XMPPManager defaultManager].delegate = self;
    
    //注册单元格
    [self.userCollectionView registerClass:[NDUserCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    //开启网络状况的监听
    
    [[NSNotificationCenter defaultCenter] addObserver:self
     
                                             selector:@selector(reachabilityChanged:)
     
                                                 name: kReachabilityChangedNotification
     
                                               object: nil];
    
    _hostReach = [Reachability reachabilityForLocalWiFi];//可以以多种形式初始化
    
    [_hostReach startNotifier]; //开始监听,会启动一个run loop
    
    

}

// 连接改变
- (void)reachabilityChanged:(NSNotification*)note
{
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}


//处理连接改变后的情况
- (void)updateInterfaceWithReachability: (Reachability*)curReach

{
    //对连接改变做出响应的处理动作。
    NetworkStatus status=[curReach currentReachabilityStatus];
    
    [self netStatusDidChangedWith:status];
    
}

- (void)netStatusDidChangedWith:(NetworkStatus)status {
    NSString *message = nil;
    [MBProgressHUD hideHUD];
    switch (status) {
        case NotReachable:
        {
            message = @"当前网络不可用,请检查网络是否正常";
            [MBProgressHUD showError:message];
            _netBtn.enabled = NO;
        }
            break;
        case ReachableViaWiFi:
        {
            message = @"当前为Wi-Fi网络";
            [MBProgressHUD showSuccess:message];
            _netBtn.enabled = YES;
        }
            break;
        case ReachableViaWWAN:
        {
            message = @"当前为移动网络";
            [MBProgressHUD showSuccess:message];
            _netBtn.enabled = YES;
        }
            break;
    }
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self btnEnable:YES];
    
    if (IS_TEACHER) {//如果是教师用户的话就显示学生列表
        self.bottomView.hidden = NO;
    } else {
        self.bottomView.hidden = YES;
    }
    
    [self updateInterfaceWithReachability:_hostReach];
}

//从本地文件获取图片数据
- (NSString *)getImageStringFromFile {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *avatarFilePath = [documentsPath stringByAppendingPathComponent:@"UserAvatarData.txt"];
    NSData *data = [NSData dataWithContentsOfFile:avatarFilePath];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}
//从本地文件直接拿到本地头像图片
- (UIImage *)getImageFromPath {
    
    NSString *str = [self getImageStringFromFile];
    
    return [self stringToUIImage:str];
}
//将图片数据转换为图片
- (UIImage *)stringToUIImage:(NSString *)string
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return [UIImage imageWithData:data];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark 懒加载学生列表视图
- (UIImageView *)bottomView {
    if (!_bottomView) {
        _bottomView = [UIImageView new];
        _bottomView.userInteractionEnabled = YES;
        _bottomView.image = [UIImage imageNamed:@"pic_people_bg"];
        [_backgroundIV addSubview:_bottomView];
        [self.view bringSubviewToFront:_bottomView];
        [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(_backgroundIV);
            if (CURRENT_DEVICE == 8) {
                make.top.equalTo(_backgroundIV.mas_bottom).offset(-28);
                make.height.equalTo(@150);
            } else if (CURRENT_DEVICE == 6) {
                make.top.equalTo(_backgroundIV.mas_bottom).offset(-22);
                make.height.equalTo(@120);
            } else if (CURRENT_DEVICE == 5) {
                make.top.equalTo(_backgroundIV.mas_bottom).offset(-18);
                make.height.equalTo(@110);
            }
            
            
        }];
        
        _userListBtn = [UIButton new];
        _userListBtn.tag = 106;
        [_bottomView addSubview:_userListBtn];
        [_userListBtn setImage:[UIImage imageNamed:@"button_arrows2"] forState:UIControlStateNormal];
        [_userListBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.top.equalTo(_bottomView);
            if (CURRENT_DEVICE == 8) {
                make.height.equalTo(@28);
            } else if (CURRENT_DEVICE == 6) {
                make.height.equalTo(@22);
            } else if (CURRENT_DEVICE == 5) {
                make.height.equalTo(@18);
            }
            
            
        }];
        [_userListBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];//设置其布局方向
        if (CURRENT_DEVICE == 8) {
            [flowLayout setItemSize:CGSizeMake(98.f, 98.f)];//设置cell的尺寸
            flowLayout.sectionInset = UIEdgeInsetsMake(10.f, 12.f, 14.f, 12.f);//设置其边界
            _userCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(4.f, 28.f, SCREEN_WIDTH, 122.f) collectionViewLayout:flowLayout];
        } else if (CURRENT_DEVICE == 6) {
            [flowLayout setItemSize:CGSizeMake(78.f, 78.f)];//设置cell的尺寸
            flowLayout.sectionInset = UIEdgeInsetsMake(10.f, 12.f, 10.f, 12.f);//设置其边界
            _userCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(4.f, 34.f, SCREEN_WIDTH, 98.f) collectionViewLayout:flowLayout];
        } else if (CURRENT_DEVICE == 5) {
            [flowLayout setItemSize:CGSizeMake(68.f, 68.f)];//设置cell的尺寸
            flowLayout.sectionInset = UIEdgeInsetsMake(10.f, 12.f, 20.f, 12.f);//设置其边界
            _userCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(4.f, 0.f, SCREEN_WIDTH, 98.f) collectionViewLayout:flowLayout];
        }
        
        
        _userCollectionView.backgroundColor = [UIColor clearColor];
        [_userCollectionView setCollectionViewLayout:flowLayout];
        [_bottomView addSubview:_userCollectionView];
        [_userCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(_bottomView);
            make.top.equalTo(_userListBtn.mas_bottom);
            if (CURRENT_DEVICE == 8) {
                make.height.equalTo(@122);
            } else if (CURRENT_DEVICE == 6) {
                make.height.equalTo(@98);
            } else if (CURRENT_DEVICE == 5) {
                make.height.equalTo(@98);
            }
            
        }];
        _userCollectionView.delegate = self;
        _userCollectionView.dataSource = self;
        
    }
    
    return _bottomView;
}
#pragma mark 初始化界面
- (void)initUI {
    
    _backgroundIV = [UIImageView new];
    _backgroundIV.image = BACKGROUND_IMAGE;
    [self.view addSubview:_backgroundIV];
    [_backgroundIV mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(20, 0, 0, 0));
        } else if (CURRENT_DEVICE >= 4 && CURRENT_DEVICE < 8) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 0, 0));
        }
    }];
    _backgroundIV.userInteractionEnabled = YES;
    
    
    
    self.canvasView = [[NDCanvasView alloc] init];
    [_backgroundIV addSubview:self.canvasView];
    [self.canvasView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(100, 0, 0, 0));
        } else if (CURRENT_DEVICE == 6) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(64, 0, 0, 0));
        } else if (CURRENT_DEVICE == 5) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(60, 0, 0, 0));
        }
    }];
    self.canvasView.backgroundColor = [UIColor clearColor];
    
    if (IS_TEACHER) {
        self.bottomView.hidden = NO;
    } else {
        self.bottomView.hidden = YES;
    }
    
    
    [self configTopView];
    [self configToolBar];
    [self configBtnEvents];
}
#pragma mark 配置顶部栏界面
- (void)configTopView {
    
    _topView = [UIView new];
    [_backgroundIV addSubview:_topView];
    _topView.backgroundColor = ColorFromHex(0x1d95d4);
    [_topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.equalTo(_backgroundIV);
        if (CURRENT_DEVICE == 8) {
            make.height.mas_equalTo(TOPVIEW_HEIGHT);
        } else if (CURRENT_DEVICE == 6) {
            make.height.mas_equalTo(TOPVIEW_HEIGHT);
        } else if (CURRENT_DEVICE == 5) {
            make.height.mas_equalTo(30);
        }
        
    }];
    
    _clearBtn = [UIButton new];
    _clearBtn.tag = 100;
    [_topView addSubview:_clearBtn];
    [_clearBtn setImage:[UIImage imageNamed:@"header_icon-_-delete1"] forState:UIControlStateNormal];
    [_clearBtn setImage:[UIImage imageNamed:@"header_icon-_-delete2"] forState:UIControlStateHighlighted];
    [_clearBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_topView);
        if (CURRENT_DEVICE == 8) {
            make.leading.equalTo(@16);
            make.width.height.mas_equalTo(BTN_SIDELENGTH);
        } else if (CURRENT_DEVICE == 6) {
            make.leading.equalTo(@10);
            make.width.height.mas_equalTo(34);
        } else if (CURRENT_DEVICE == 5) {
            make.leading.equalTo(@8);
            make.width.height.mas_equalTo(30);
        }
        
    }];
    
    _saveBtn = [UIButton new];
    _saveBtn.tag = 101;
    [_topView addSubview:_saveBtn];
    [_saveBtn setImage:[UIImage imageNamed:@"header_icon_save1"] forState:UIControlStateNormal];
    [_saveBtn setImage:[UIImage imageNamed:@"header_icon_save2"] forState:UIControlStateHighlighted];
    [_saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.height.width.equalTo(_clearBtn);
        if (CURRENT_DEVICE == 8) {
            make.trailing.equalTo(_topView).offset(-16);
        } else if (CURRENT_DEVICE == 6) {
            make.trailing.equalTo(_topView).offset(-10);
        } else if (CURRENT_DEVICE == 5) {
            make.trailing.equalTo(_topView).offset(-8);
        }
        
    }];
    
    _netBtn = [UIButton new];
    _netBtn.tag = 102;
    [_topView addSubview:_netBtn];
    [_netBtn setImage:[UIImage imageNamed:@"header_icon_share1"] forState:UIControlStateNormal];
    [_netBtn setImage:[UIImage imageNamed:@"header_icon_share2"] forState:UIControlStateSelected];
    [_netBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.height.width.equalTo(_clearBtn);
        if (CURRENT_DEVICE == 8) {
            make.trailing.equalTo(_saveBtn.mas_leading).offset(-26);
        } else if (CURRENT_DEVICE == 6) {
            make.trailing.equalTo(_saveBtn.mas_leading).offset(-16);
        } else if (CURRENT_DEVICE == 5) {
            make.trailing.equalTo(_saveBtn.mas_leading).offset(-8);
        }
        
    }];
    
    _switchUserBtn = [UIButton new];
    _switchUserBtn.tag = 103;
    [_topView addSubview:_switchUserBtn];
    [_switchUserBtn setImage:[UIImage imageNamed:@"header_icon-_user1"] forState:UIControlStateNormal];
    [_switchUserBtn setImage:[UIImage imageNamed:@"header_icon-_user2"] forState:UIControlStateHighlighted];
    [_switchUserBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.height.width.equalTo(_clearBtn);
        if (CURRENT_DEVICE == 8) {
            make.trailing.equalTo(_netBtn.mas_leading).offset(-26);
        } else if (CURRENT_DEVICE == 6) {
            make.trailing.equalTo(_netBtn.mas_leading).offset(-16);
        } else if (CURRENT_DEVICE == 5) {
            make.trailing.equalTo(_netBtn.mas_leading).offset(-8);
        }
    }];
    
    _titleLabel = [UILabel new];
    _titleLabel.text = @"ND笔记";
    _titleLabel.font = [UIFont systemFontOfSize:22.f];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor whiteColor];
    [_topView addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.height.equalTo(_topView);
    }];
    
    
}
#pragma mark 配置工具栏界面
- (void)configToolBar {
    _toolBar = [UIView new];
    [_backgroundIV addSubview:_toolBar];
    _toolBar.backgroundColor = ColorFromHex(0xe6e6e6);
    [_toolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(_topView);
        make.top.equalTo(_topView.mas_bottom);
        if (CURRENT_DEVICE == 8) {
            make.height.mas_equalTo(TOOLBAR_HEIGHT);
        } else if (CURRENT_DEVICE == 6) {
            make.height.mas_equalTo(30);
        } else if (CURRENT_DEVICE == 5) {
            make.height.mas_equalTo(30);
        }
        
    }];
    
    _trackColorBtn = [UIButton new];
    [_toolBar addSubview:_trackColorBtn];
    [_trackColorBtn setImage:[UIImage imageNamed:@"icon_straw1"] forState:UIControlStateNormal];
    [_trackColorBtn setImage:[UIImage imageNamed:@"icon_straw2"] forState:UIControlStateHighlighted];
    [_trackColorBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_toolBar);
        if (CURRENT_DEVICE == 8) {
            make.leading.equalTo(_toolBar).offset(22);
            make.height.width.mas_equalTo(BTN_SIDELENGTH);
        } else if (CURRENT_DEVICE == 6) {
            make.leading.equalTo(_toolBar).offset(12);
            make.height.width.mas_equalTo(30);
        } else if (CURRENT_DEVICE == 5) {
            make.leading.equalTo(_toolBar).offset(10);
            make.height.width.mas_equalTo(30);
        }
        
    }];
    
    _penSizeBtn = [UIButton new];
    _penSizeBtn.tag = 104;
    [_toolBar addSubview:_penSizeBtn];
    [_penSizeBtn setImage:[UIImage imageNamed:@"icon_pen1"] forState:UIControlStateNormal];
    [_penSizeBtn setImage:[UIImage imageNamed:@"icon_pen2"] forState:UIControlStateHighlighted];
    [_penSizeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.width.height.equalTo(_trackColorBtn);
        if (CURRENT_DEVICE == 8) {
            make.leading.equalTo(_trackColorBtn.mas_trailing).offset(26);
        } else if (CURRENT_DEVICE == 6) {
            make.leading.equalTo(_trackColorBtn.mas_trailing).offset(16);
        } else if (CURRENT_DEVICE == 5) {
            make.leading.equalTo(_trackColorBtn.mas_trailing).offset(8);
        }
        
    }];
    
    _undoBtn = [UIButton new];
    _undoBtn.tag = 105;
    [_toolBar addSubview:_undoBtn];
    [_undoBtn setImage:[UIImage imageNamed:@"icon_return1"] forState:UIControlStateNormal];
    [_undoBtn setImage:[UIImage imageNamed:@"icon_return2"] forState:UIControlStateHighlighted];
    [_undoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.width.height.equalTo(_trackColorBtn);
        if (CURRENT_DEVICE == 8) {
            make.leading.equalTo(_penSizeBtn.mas_trailing).offset(26);
        } else if (CURRENT_DEVICE == 6) {
            make.leading.equalTo(_penSizeBtn.mas_trailing).offset(16);
        } else if (CURRENT_DEVICE == 5) {
            make.leading.equalTo(_penSizeBtn.mas_trailing).offset(8);
        }
        
    }];
}
#pragma mark 配置按钮点击事件
- (void)configBtnEvents {
    [_clearBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_switchUserBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_netBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_saveBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_penSizeBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_undoBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
}
#pragma mark 显示清空面板警告
- (void)showAlertView {
    self.canvasView.userInteractionEnabled = NO;
    _clearBtn.enabled = NO;
    _penSizeBtn.enabled = YES;
    [self.penSizePickerIV removeFromSuperview];
    
    _alertView = [UIImageView new];
    _alertView.userInteractionEnabled = YES;
    [[UIApplication sharedApplication].keyWindow addSubview:_alertView];
    _alertView.image = [UIImage imageNamed:@"pop_bg"];
    [_alertView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        if (CURRENT_DEVICE == 8) {
            make.height.width.equalTo(_alertView);
        } else if (CURRENT_DEVICE == 6) {
            make.width.mas_equalTo(428*.6f);
            make.height.mas_equalTo(250*.6f);
        } else if (CURRENT_DEVICE == 5) {
            make.width.mas_equalTo(428*.5f);
            make.height.mas_equalTo(250*.5f);
        }
        
    }];
    UILabel *label = [UILabel new];
    [_alertView addSubview:label];
    label.text = @"是否清空面板？";
    if (CURRENT_DEVICE == 8) {
        label.font = [UIFont systemFontOfSize:26.f];
    } else if (CURRENT_DEVICE == 6) {
        label.font = [UIFont systemFontOfSize:18.f];
    } else if (CURRENT_DEVICE == 5) {
        label.font = [UIFont systemFontOfSize:16.f];
    }
    
    label.textColor = ColorFromHex(0x3a3a3a);
    label.textAlignment = NSTextAlignmentCenter;
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_alertView);
        if (CURRENT_DEVICE == 8) {
            make.top.equalTo(_alertView).offset(100);
        } else if (CURRENT_DEVICE == 6) {
            make.top.equalTo(_alertView).offset(60);
        } else if (CURRENT_DEVICE == 5) {
            make.top.equalTo(_alertView).offset(50);
        }
        
    }];
    
    UIButton *confirmBtn = [UIButton new];
    confirmBtn.tag = 107;
    [confirmBtn setImage:[UIImage imageNamed:@"pop_button_yes1"] forState:UIControlStateNormal];
    [confirmBtn setImage:[UIImage imageNamed:@"pop_button_yes2"] forState:UIControlStateHighlighted];
    [_alertView addSubview:confirmBtn];
    [confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.width.height.equalTo(confirmBtn);
            make.trailing.equalTo(_alertView.mas_centerX).offset(-24);
            make.top.equalTo(label.mas_bottom).offset(52);
        } else if (CURRENT_DEVICE == 6) {
            make.width.mas_equalTo(140*.6f);
            make.height.mas_equalTo(42*.6f);
            make.trailing.equalTo(_alertView.mas_centerX).offset(-24);
            make.top.equalTo(label.mas_bottom).offset(26);
        } else if (CURRENT_DEVICE == 5) {
            make.width.mas_equalTo(140*.5f);
            make.height.mas_equalTo(42*.5f);
            make.trailing.equalTo(_alertView.mas_centerX).offset(-24);
            make.top.equalTo(label.mas_bottom).offset(26);
        }
        
    }];
    
    UIButton *cancelBtn = [UIButton new];
    
    [cancelBtn setImage:[UIImage imageNamed:@"pop_button_no1"] forState:UIControlStateNormal];
    [cancelBtn setImage:[UIImage imageNamed:@"pop_button_no2"] forState:UIControlStateHighlighted];
    [_alertView addSubview:cancelBtn];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_alertView.mas_centerX).offset(24);
        make.width.height.centerY.equalTo(confirmBtn);
    }];
    [confirmBtn addTarget:self action:@selector(clearAlertBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [cancelBtn addTarget:self action:@selector(clearAlertBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
}
#pragma mark 按钮点击事件
- (void)btnClicked:(UIButton *)btn {
    
    switch (btn.tag) {
#pragma mark 清空屏幕功能
        case 100://清空屏幕按钮
        {
            btn.enabled = YES;
            if ([self.canvasView.strokesArr count] > 0 || (self.canvasView.receivedStudentStrokesArr.count > 0 && IS_TEACHER)) {
                
                [self showAlertView];
                
            }
            
        }
            break;
#pragma mark 保存功能
        case 101://保存按钮
        {
            NSString *message = @"保存成功";
            //            [[UIApplication sharedApplication].keyWindow makeToast:message duration:3 position:CSToastPositionCenter];
            [MBProgressHUD hideHUD];
            [MBProgressHUD showSuccess:message];
        }
            break;
#pragma mark 联网功能
        case 102://联网按钮
        {
            _netBtn.enabled = NO;
            
            [self login];
        }
            break;
#pragma mark 切换用户功能
        case 103://切换用户按钮
        {
            [[NDLocalCacheManager sharedManager] clearLocalCache];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [MBProgressHUD hideHUD];
                [MBProgressHUD showSuccess:@"退出登录成功"];
                [self.savedSize setValue:[NSNumber numberWithInteger:109] forKey:@"SAVED_SIZE"];
                if (self.alertView) {
                    [self.alertView removeFromSuperview];
                }
                if (self.penSizePickerIV) {
                    [self.penSizePickerIV removeFromSuperview];
                }
            }];
            
        }
            break;
#pragma mark 画笔粗细选择功能
        case 104://选择按钮
        {
            btn.enabled = btn.selected;
            [self showPenSizePickerView];
        }
            break;
#pragma mark 回退功能
        case 105://回退按钮
        {
            if ([self.canvasView.strokesArr count]>0) {
                [self undoAction];
            }
        }
            break;
#pragma mark 学生用户列表功能
        case 106://学生用户列表按钮
        {
            if (btn.selected) {
                [UIView animateWithDuration:.4f animations:^{
                    [_userListBtn setImage:[UIImage imageNamed:@"button_arrows2"] forState:UIControlStateNormal];
                    [_bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                        if (CURRENT_DEVICE == 8) {
                            make.top.equalTo(_backgroundIV.mas_bottom).offset(-28);
                        } else if (CURRENT_DEVICE == 6) {
                            make.top.equalTo(_backgroundIV.mas_bottom).offset(-22);
                        } else if (CURRENT_DEVICE == 5) {
                            make.top.equalTo(_backgroundIV.mas_bottom).offset(-18);
                        }
                        
                    }];
                    [_bottomView layoutIfNeeded];
                }];
            } else {
                [UIView animateWithDuration:.4f animations:^{
                    [_userListBtn setImage:[UIImage imageNamed:@"button_arrows1"] forState:UIControlStateNormal];
                    [_bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                        if (CURRENT_DEVICE == 8) {
                            make.top.equalTo(_backgroundIV.mas_bottom).offset(-150);
                        } else if (CURRENT_DEVICE == 6) {
                            make.top.equalTo(_backgroundIV.mas_bottom).offset(-120);
                        } else if (CURRENT_DEVICE == 5) {
                            make.top.equalTo(_backgroundIV.mas_bottom).offset(-110);
                        }
                        
                    }];
                    [_bottomView layoutIfNeeded];
                }];
            }
            btn.selected = !btn.selected;
        }
            break;
            
    }
}
#pragma mark 撤销回退方法
- (void)undoAction {
    
    if (IS_TEACHER) {
        [self.xmppRoom sendMessageWithBody:@"{\"msg\":{\"function\":\"Undo\",\"pencolor\":0}}"];
    }
    // 最后一个笔画字典,即,被丢弃的笔画字典
    NSMutableDictionary* abandonedStrokeDict = [self.canvasView.strokesArr lastObject];
    // 将最后一个笔画字典,添加到被丢弃的笔画字典数组里面保存,以供drawRect
    [self.canvasView.abandonedStrokesArr addObject:abandonedStrokeDict];
    // 从所有笔画数组中移除掉最后一笔
    [self.canvasView.strokesArr removeLastObject];
    
#pragma mark 回退时需要把自己画的内容在数组中清除，当前自己画完后，老师点名时仍会发出未清空的数组
    LogRed(@"删除前数组数量%lu", self.canvasView.studentLine.pathInfos.count);
    NDLine *line = (NDLine *)abandonedStrokeDict;
    NSArray *points = line.points;
    for (NSString *point in points) {
        [self.canvasView.studentLine.pathInfos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NDPathInfo class]]) {
                NDPathInfo *pathInfo = obj;
                CGFloat x = pathInfo.x;
                CGFloat y = pathInfo.y;
                CGPoint p = CGPointMake(x, y);
                NSString *pointStr = NSStringFromCGPoint(p);
                if ([point isEqualToString:pointStr]) {
                    [self.canvasView.studentLine.pathInfos removeObject:pathInfo];
                }
            }
        }];
    }
    LogRed(@"删除后数组数量%lu", self.canvasView.studentLine.pathInfos.count);
    
    // 重新调用drawRect进行绘制
    [self.canvasView setNeedsDisplay];
    
    
}
//懒加载保存的尺寸
- (NSMutableDictionary *)savedSize {
    if (!_savedSize) {
        _savedSize = [NSMutableDictionary dictionary];
    }
    return _savedSize;
}
//显示笔粗细选择视图
- (void)showPenSizePickerView {
    
    self.canvasView.userInteractionEnabled = NO;
    
    _clearBtn.enabled = YES;
    _penSizeBtn.enabled = NO;
    [self.alertView removeFromSuperview];
    
    _penSizePickerIV = [UIImageView new];
    _penSizePickerIV.userInteractionEnabled = YES;
    _penSizePickerIV.image = [UIImage imageNamed:@"pop_pen_bg"];
    [[UIApplication sharedApplication].keyWindow addSubview:_penSizePickerIV];
    [_penSizePickerIV mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.top.equalTo(_toolBar.mas_bottom).offset(6);
            make.leading.equalTo(self.canvasView).offset(100);
            make.height.width.equalTo(_penSizePickerIV);
        } else if (CURRENT_DEVICE == 6) {
            make.top.equalTo(_toolBar.mas_bottom).offset(6);
            make.leading.equalTo(self.canvasView).offset(80);
            make.width.mas_equalTo(322*.55f);
            make.height.mas_equalTo(462*.55f);
        } else if (CURRENT_DEVICE == 5) {
            make.top.equalTo(_toolBar.mas_bottom).offset(6);
            make.leading.equalTo(self.canvasView).offset(80);
            make.width.mas_equalTo(322*.35f);
            make.height.mas_equalTo(462*.35f);
        }
        
    }];
    self.checkboxes = [NSMutableArray arrayWithCapacity:6];
    for (int i = 1; i <= 6; i++) {
        UILabel *label = [UILabel new];
        label.text = [NSString stringWithFormat:@"%d", i * 5];
        if (CURRENT_DEVICE == 8) {
            label.font = [UIFont systemFontOfSize:22.f];
        } else if (CURRENT_DEVICE == 6) {
            label.font = [UIFont systemFontOfSize:16.f];
        } else if (CURRENT_DEVICE == 5) {
            label.font = [UIFont systemFontOfSize:12.f];
        }
        
        label.textColor = ColorFromHex(0x2c2c2c);
        [_penSizePickerIV addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            if (CURRENT_DEVICE == 8) {
                make.top.mas_equalTo(20 + 56 * i);
                make.leading.equalTo(_penSizePickerIV).offset(16);
            } else if (CURRENT_DEVICE == 6) {
                make.top.mas_equalTo(7 + 31 * i);
                make.leading.equalTo(_penSizePickerIV).offset(10);
            } else if (CURRENT_DEVICE == 5) {
                make.top.mas_equalTo(3 + 19.5 * i);
                make.leading.equalTo(_penSizePickerIV).offset(8);
            }
            
        }];
        UIButton *checkbox = [UIButton buttonWithType:UIButtonTypeCustom];
        checkbox.tag = 108 + i;
        
        
        NSNumber *num = [self.savedSize valueForKey:@"SAVED_SIZE"];
        if (!num && i == 1) {
            checkbox.selected = YES;
        } else {
            NSInteger integer = [num integerValue];
            if (i == integer - 108) {
                checkbox.selected = YES;
            }
        }
        
        [_penSizePickerIV addSubview:checkbox];
        [checkbox setImage:[UIImage imageNamed:@"radio3"] forState:UIControlStateNormal];
        [checkbox setImage:[UIImage imageNamed:@"radio4"] forState:UIControlStateSelected];
        [checkbox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(label);
            if (CURRENT_DEVICE == 8) {
                make.width.height.mas_equalTo(20);
                make.trailing.equalTo(_penSizePickerIV).offset(-26);
            } else if (CURRENT_DEVICE == 6) {
                make.width.height.mas_equalTo(16);
                make.trailing.equalTo(_penSizePickerIV).offset(-10);
            } else if (CURRENT_DEVICE == 5) {
                make.width.height.mas_equalTo(12);
                make.trailing.equalTo(_penSizePickerIV).offset(-8);
            }
            
        }];
        [checkbox addTarget:self action:@selector(checkboxBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.checkboxes addObject:checkbox];
        if (i == 6) {
            UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            cancelBtn.tag = 108;
            [cancelBtn setImage:[UIImage imageNamed:@"icon_cancel1"] forState:UIControlStateNormal];
            [cancelBtn setImage:[UIImage imageNamed:@"icon_cancel2"] forState:UIControlStateHighlighted];
            [_penSizePickerIV addSubview:cancelBtn];
            [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(_penSizePickerIV);
                
                if (CURRENT_DEVICE == 8) {
                    make.top.equalTo(label.mas_centerY).offset(46);
                    make.width.height.equalTo(cancelBtn);
                } else if (CURRENT_DEVICE == 6) {
                    make.top.equalTo(label.mas_centerY).offset(22);
                    make.width.height.equalTo(cancelBtn);
                } else if (CURRENT_DEVICE == 5) {
                    make.top.equalTo(label.mas_centerY).offset(18);
                    make.width.mas_equalTo(90*.45f);
                    make.height.mas_equalTo(44*.45f);
                }
                
            }];
            [cancelBtn addTarget:self action:@selector(clearAlertBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
}
//单选按钮点击事件
- (void)checkboxBtnClicked:(UIButton *)checkbox {
    
    [self.alertView removeFromSuperview];
    
    for (UIButton *checkboxBtn in self.checkboxes) {
        if (checkboxBtn.tag != checkbox.tag) {
            checkboxBtn.selected = NO;
        } else {
            checkboxBtn.selected = YES;
            [self.savedSize setValue:[NSNumber numberWithInteger:checkboxBtn.tag] forKey:@"SAVED_SIZE"];
        }
    }
    CGFloat currentSize = (checkbox.tag - 108) * 5.f;
    [self.canvasView setCurrentSize:currentSize];
    
    [_penSizePickerIV removeFromSuperview];
    self.canvasView.userInteractionEnabled = YES;
    _penSizeBtn.enabled = YES;
}
//清屏警告中的按钮点击事件
- (void)clearAlertBtnClicked:(UIButton *)btn {
    // 清空画布,只需清空【所有笔画数组】和【被丢弃的笔画数组】
    if (btn.tag == 107) {//确认清屏
        
        if (IS_TEACHER) {//只有教师能发清屏消息
            NSString *message = [NSString stringWithFormat:@"{\"msg\":{\"function\":\"ClearPaint\",\"pencolor\":\"0\"}}"];
            [self.xmppRoom sendMessageWithBody:message];
        }
        [self.canvasView.receivedStudentStrokesArr removeAllObjects];
        [self.canvasView.strokesArr removeAllObjects];
        [self.canvasView.abandonedStrokesArr removeAllObjects];
        [self.canvasView.studentLine.pathInfos removeAllObjects];
        // 重新调用drawRect进行绘制
        [self.canvasView setNeedsDisplay];
        
    } else if (btn.tag == 108) {//取消按钮
        [self.penSizePickerIV removeFromSuperview];
        
        _penSizeBtn.enabled = YES;
    }
    self.canvasView.userInteractionEnabled = YES;
    [self.alertView removeFromSuperview];
    
    _clearBtn.enabled = YES;
}

- (void)injected {
    [self viewDidLoad];
}
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////XMPP部分////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
#pragma mark XMPP部分
//配置应用程序用户配置
- (void)configUserDefaults
{
    
    
    
    
    self.notFirstStart = [[[NSUserDefaults standardUserDefaults] valueForKey:@"notfirstStart"] boolValue];
    
    if (!self.notFirstStart) {//用户第一次打开APP
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"appOpenCount"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"notfirstStart"];
        self.appOpenCount = [[[NSUserDefaults standardUserDefaults] valueForKey:@"appOpenCount"] integerValue];
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"appOpenCount"];
        //生成一个用于登录xmpp服务器的用户名
        self.userID = [[LoginTool sharedLoginTool] generateAUserNameForLoginToXMPPServer];
        [[NSUserDefaults standardUserDefaults] setValue:self.userID forKey:@"USER_ID"];
        
        
    } else {
        self.appOpenCount = [[[NSUserDefaults standardUserDefaults] valueForKey:@"appOpenCount"] integerValue];
        [[NSUserDefaults standardUserDefaults] setInteger:self.appOpenCount + 1 forKey:@"appOpenCount"];
    }
}

//XMPP登录
- (void)login {
    XMPPManager *manager = [XMPPManager defaultManager];
    self.userID = [[NSUserDefaults standardUserDefaults] valueForKey:@"USER_ID"];
    LogBlue(@"self.userID = %@", self.userID);
    BOOL registed = [[[NSUserDefaults standardUserDefaults] valueForKey:@"haveRegisted"] boolValue];
    if (!registed) {
        LogBlue(@"没有注册过,使用生成的userID = %@去注册", self.userID);
        [manager registerWithName:self.userID andPassword:PASSWORD];
    } else {//不是第一次打开应用了
        self.userID = [[NSUserDefaults standardUserDefaults] valueForKey:@"USER_ID"];
        LogBlue(@"不是第一次打开应用了,使用本地存储的userID = %@去登录", self.userID);
        [manager loginwithName:self.userID andPassword:PASSWORD];
    }
    
    //    //管理员账号
    //    [manager loginwithName:@"admin" andPassword:@"13269372595"];
}
//懒加载XMPP流
- (XMPPStream *)xmppStream {
    if (!_xmppStream) {
        _xmppStream = [XMPPManager defaultManager].xmppStream;
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppStream;
}

//创建或加入一个房间
- (void)joinOrCreateRoom {
    
    XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
    XMPPJID *roomJID = [XMPPJID jidWithString:ROOM_JID];
    //初始化聊天室
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:roomJID dispatchQueue:dispatch_get_main_queue()];
    [self.xmppRoom configureRoomUsingOptions:nil];
    
    [self.xmppRoom activate:self.xmppStream];
    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    //接收历史消息
    NSXMLElement *p = [NSXMLElement elementWithName:@"history"];
    //后面的stringValue为接收历史消息的条数，因为无法判断历史消息和当前发送消息的区别，因此暂时不接收历史消息
    [p addAttributeWithName:@"maxstanzas" stringValue:@"0"];
    //加入房间时使用的昵称
    
    self.nickName = [[LoginTool sharedLoginTool] generateNickNameForJoinToXMPPRoom];
    LogGreen(@"加入房间时使用的昵称self.nickName = %@", self.nickName);
    [self.xmppRoom joinRoomUsingNickname:self.nickName history:p];
}

#pragma mark XMPPRoomDelegate 协议中的方法
//确认已经收到聊天室的消息
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID {
    if (![message.body containsString:@"userIcon"]) {//不打印用户头像数据
        LogGreen(@"从occupantJID.resource = %@\n接收到的字符串 = %@", occupantJID.resource, message.body);
    }
    NSData *jsonData = [message.body dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    
    NSString *function = jsonDic[@"msg"][@"function"];
    
    NSString *userID = jsonDic[@"msg"][@"user"][@"userID"];
    
    NSDictionary *dict = jsonDic[@"msg"];
#pragma mark 屏蔽自己发的消息
    if (![occupantJID.resource isEqualToString:self.nickName]) {//接收消息时屏蔽自己

        if ([function isEqualToString:@"setPathInfoByTeacher"]) {//教师画图
            
            [self teacherDrawWith:dict];

        } else if ([function isEqualToString:@"setPathInfoByStudent"]) {//学生画图
            
            [self studentDrawWith:dict];
            
        } else if ([function isEqualToString:@"user_join"]) {//有用户加入了
            LogRed(@"occupantJID.resource = %@\n", occupantJID.resource);
            
            [self newStudentJoinedTheRoomWith:jsonDic student:occupantJID];

        } else if ([function isEqualToString:@"ClearPaint"]) {//清空屏幕
            
            [self clearScreen];
            

        } else if ([function isEqualToString:@"Online"]) {//如果教师上线了，再次发送学生信息
            
            [self teacherOnline];

        } else if ([function isEqualToString:@"Rollcall"]) {//老师点名了
            if ([userID isEqualToString:self.nickName]) {//点的是自己
                
                [self teacherRollCall];
            }

        } else if ([function isEqualToString:@"Undo"]) {
            
            [self teacherUndo];

        } else if ([function isEqualToString:@"isExisted"] && IS_TEACHER && !self.isObserver) {//如果收到了有教师进入聊天室的消息且自己是老师且自己不是观察者
            NSString *time = dict[@"currentTime"];
            
            [self moreThanOneTeacher:time];
           
        }
        
    }
    
}
#pragma mark 教师画图功能
- (void)teacherDrawWith:(NSDictionary *)dict {
    NDTeacherLineModel *lineModel = [NDTeacherLineModel mj_objectWithKeyValues:dict];
    [self.canvasView setValue:lineModel forKey:@"receivedLine"];
}
#pragma mark 学生画图功能
- (void)studentDrawWith:(NSDictionary *)dict {
    //先清空别人画的
    [self.canvasView.receivedStudentStrokesArr removeAllObjects];
    
    [self.canvasView setNeedsDisplay];
    
    NDStudentLineModel *lineModel = [NDStudentLineModel mj_objectWithKeyValues:dict];
    
    for (NDPathInfo *pathInfo in lineModel.pathInfos) {
        LogRed(@"pathInfo.currentSize = %g", pathInfo.currentSize);
    }
    self.canvasView.tempLine = lineModel;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"needDraw" object:nil];

}
#pragma mark 新的学生用户加入刷新学生列表功能
- (void)newStudentJoinedTheRoomWith:(NSDictionary *)jsonDic student:(XMPPJID *)occupantJID {
    if (IS_TEACHER) {//如果接收到的消息不是自己发出的，且自己是老师
        
        NSString *userIconString = jsonDic[@"msg"][@"user"][@"userIcon"];
        NDUser *user = [NDUser new];
        user.userID = occupantJID.resource;
        user.userIcon = userIconString;
//        if (!self.allStudentsArray.count) {
//            
//            [self.allStudentsArray addObject:user];
//            //刷新学生列表屏幕显示
//            [self.userCollectionView reloadData];
//        } else {
//            [self.allStudentsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                if ([obj isKindOfClass:[NDUser class]]) {
//                    NDUser *existedUser = obj;
//                    if (![existedUser.userID isEqualToString:user.userID] && idx >= self.allStudentsArray.count) {
//                         [self.allStudentsArray addObject:user];
//                        [self.userCollectionView reloadData];
//                    }
//                }
//            }];
//        }
        [self.allStudentsArray addObject:user];
        [self.userCollectionView reloadData];
    }
}
#pragma mark 清空屏幕功能
- (void)clearScreen {
    [self.canvasView.receivedStrokesArr removeAllObjects];
    [self.canvasView.strokesArr removeAllObjects];
    [self.canvasView.receivedStudentStrokesArr removeAllObjects];
    [self.canvasView.studentLine.pathInfos removeAllObjects];
    self.canvasView.tempLine = nil;
    [self.canvasView setNeedsDisplay];
}
#pragma mark 教师上线
- (void)teacherOnline {
    if (!IS_TEACHER) {
        [self sendStudentInfo];
    }
}
#pragma mark 教师点名功能
- (void)teacherRollCall {
    if (!TARGET_IPHONE_SIMULATOR) {
        //iPad 没有震动功能，此行代码在iPad上不起作用
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        //发出声音
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"您的笔迹已被同步"];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
        utterance.rate = 0.4f;
        [self.synthesizer speakUtterance:utterance];
    }
    
    [self.canvasView.receivedStudentStrokesArr removeAllObjects];
    [self.canvasView setNeedsDisplay];
    
    if (self.canvasView.studentLine) {//有值的话才会发送消息
        self.canvasView.studentLine.userId = self.nickName;
        NSDictionary *dic = [self.canvasView.studentLine.mj_keyValues copy];
        NSDictionary *msgDic = [NSDictionary dictionaryWithObject:dic forKey:@"msg"];
        NSError *error = nil;
        NSData *msgData = [NSJSONSerialization dataWithJSONObject:msgDic options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding];
        
        LogBlue(@"%@", jsonString);
        [self.xmppRoom sendMessageWithBody:jsonString];
    }

}
#pragma mark 教师撤销回退功能
- (void)teacherUndo {
    [self.canvasView.receivedStrokesArr removeLastObject];
    [self.canvasView setNeedsDisplay];
}
#pragma mark 多名教师登录判断
- (void)moreThanOneTeacher:(NSString *)time {
    if (![self.tempTime isEqualToString:time]) {//如果这次收到的时间跟上次不一样，就把自己的时间发出去
        [self sendCheckoutMessageWithTime:self.joinedTime];
        self.tempTime = time;
    } else {
        self.tempTime = nil;
    }
    
    long otherTeacherJoinedTime = [time longLongValue];
    long myJoinedTime = [self.joinedTime longLongValue];
    LogRed(@"其他老师加入房间的时间为%ld,我自己是老师加入房间的时间是%ld", otherTeacherJoinedTime, myJoinedTime);
    
    if (otherTeacherJoinedTime < myJoinedTime) {//别的老师先加入的房间，我是老师后加入的，就变成观察者模式
        [MBProgressHUD hideHUD];
        [MBProgressHUD showError:@"房间里存在多个教师，您已成为观察者"];
        _bottomView.hidden = YES;
        [self btnEnable:NO];
    }
}

- (void)sendCheckoutMessageWithTime:(NSString *)time {
    //查询房间内是否已经有老师了
    NSDictionary *funcDic = [NSDictionary dictionaryWithObjectsAndKeys:@"isExisted", @"function", time, @"currentTime", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:funcDic forKey:@"msg"];
    NSError *error = nil;
    NSData *msgData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *checkout = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding];
    LogRed(@"checkout = %@", checkout);
    [self.xmppRoom sendMessageWithBody:checkout];
    
}

//向聊天室发送消息成功
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    LogGreen(@"发送消息成功");
}
//向聊天室发送消息失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {
    LogRed(@"发送消息失败,失败原因:%@", error);
}

#pragma mark 配置房间为永久房间
//配置聊天室房间
-(void)sendDefaultRoomConfig
{
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    
    NSXMLElement *field = [NSXMLElement elementWithName:@"field"];
    NSXMLElement *value = [NSXMLElement elementWithName:@"value"];
    
    NSXMLElement *fieldowners = [NSXMLElement elementWithName:@"field"];
    NSXMLElement *valueowners = [NSXMLElement elementWithName:@"value"];
    
    
//    [field addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];  // 永久属性
    [fieldowners addAttributeWithName:@"var" stringValue:@"muc#roomconfig_roomowners"];  // 谁创建的房间
    
    
    [field addAttributeWithName:@"type" stringValue:@"boolean"];
    [fieldowners addAttributeWithName:@"type" stringValue:@"jid-multi"];
    
    [value setStringValue:@"1"];
    NSString *jid = [NSString stringWithFormat:@"%@", [XMPPManager defaultManager].xmppStream.myJID];
    LogBlue(@"XMPP自己的JID = %@", jid);
    [valueowners setStringValue:jid]; //创建者的Jid
    
    [x addChild:field];
    [x addChild:fieldowners];
    [field addChild:value];
    [fieldowners addChild:valueowners];
    
    [self.xmppRoom configureRoomUsingOptions:x];
    
}



- (void)xmppRoomDidLeave:(XMPPRoom *)sender {
    LogRed(@"已经退出聊天室");
    [self logoutXMPP];
    _netBtn.enabled = YES;
}
- (void)xmppRoomDidJoin:(XMPPRoom *)sender {
    
    NSString *text = @"已经成功加入进了聊天室";
    LogGreen(@"%@", text);
    
    [MBProgressHUD hideHUD];
    [MBProgressHUD showSuccess:text];
    //    [self.view.window makeToast:text duration:3 position:CSToastPositionCenter];
    
    
    if (IS_TEACHER) {
        NSString *message = [NSString stringWithFormat:@"{\"msg\":{\"function\":\"Online\",\"pencolor\":\"0\"}}"];
        LogBlue(@"发送的内容为 %@", message);
        [self.xmppRoom sendMessageWithBody:message];
        
        UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
        NSString *currentTime = [NSString stringWithFormat:@"%llu", recordTime];
        //记录一下自己加入房间时的时间
        self.joinedTime = currentTime;
        
        [self sendCheckoutMessageWithTime:currentTime];
        
        //如果自己是老师的话，在成功加入聊天室后初始化学生列表数组
        self.allStudentsArray = [NSMutableArray array];
    } else {//如果自己是学生的话，在成功加入聊天室后发送自己的信息，包括ID和头像等
        
        [self sendStudentInfo];
    }
    
}



//房间确实已经创建了
- (void)xmppRoomDidCreate:(XMPPRoom *)sender {
    LogGreen(@"%@", @"聊天室创建成功了");
    
    //发送房间的配置信息
    [self sendDefaultRoomConfig];
}
//新的用户加入了聊天室
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence {
    LogGreen(@"有用户加入进了聊天室%@", occupantJID);
    
    
    for (NDUser *user in self.allStudentsArray) {
        if ([user.userID isEqualToString:occupantJID.resource]) {
            [self.userCollectionView reloadData];
        }
    }
    
}
//有用户离开了聊天室
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence {
    
    LogGreen(@"有用户离开了聊天室%@", occupantJID);
    
    [self.allStudentsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NDUser class]]) {
            NDUser *user = obj;
            if ([user.userID isEqualToString:occupantJID.resource]) {
                [self.allStudentsArray removeObject:user];
                [self.userCollectionView reloadData];
                *stop = YES;
            }
        }
    }];
    
}



//查找聊天室的房间信息
- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm{
    LogGreen(@"已经从服务器上获取到房间配置信息");
    NSXMLElement *newConfig = [configForm copy];
    LogPurple(@"确认新的房间配置信息 %@",newConfig);
    NSArray *fields = [newConfig elementsForName:@"field"];
    
    for (NSXMLElement *field in fields)
    {
        NSString *var = [field attributeStringValueForName:@"var"];
        // Make Room Persistent
        if ([var isEqualToString:@"muc#roomconfig_persistentroom"]) {
            [field removeChildAtIndex:0];
            [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
        }
    }
    LogGreen(@"配置后的房间信息 %@",newConfig);
    [sender configureRoomUsingOptions:newConfig];
}
//视图将要消失的方法
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self logoutXMPP];
    
    [self clearScreen];
    
    self.canvasView.penIV.hidden = YES;
    
    self.canvasView.penIV = nil;
}
//退出聊天室的方法
- (void)logoutXMPP {
    LogRed(@"%s", __func__);
    //    [[XMPPManager defaultManager] logout];
    [self.xmppRoom deactivate];
    self.xmppRoom = nil;
    _netBtn.enabled = YES;
    [MBProgressHUD hideHUD];

}

#pragma mark XMPPManagerDelegate 协议中的方法
- (void)authenticatedSuccess {
    LogGreen(@"登录授权成功");
    //XMPP创建或加入一个房间
    [self joinOrCreateRoom];
}

#pragma mark NDCanvasViewDelegate 协议中的方法
- (void)didDraw {
    
    if (!self.observer) {
        NSDictionary *dic = self.canvasView.currentLine.mj_keyValues;
        NSDictionary *msgDic = [NSDictionary dictionaryWithObject:dic forKey:@"msg"];
        NSError *error = nil;
        NSData *msgData = [NSJSONSerialization dataWithJSONObject:msgDic options:NSJSONWritingPrettyPrinted error:&error];
        
        
        NSString *jsonString = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding];
        
        LogBlue(@"%@", jsonString);
        [self.xmppRoom sendMessageWithBody:jsonString];
    }
    
}

//collectionView的代理方法
#pragma mark - UICollectionViewDataSource 和 UICollectionViewDelegate中的方法

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section

{
    return self.allStudentsArray.count;
//    return 40;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView

{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath

{
    NDUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    NDUser *user = self.allStudentsArray[indexPath.row];
    cell.user = user;
    //测试
//    cell.backgroundColor = [UIColor redColor];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath

{
    NDUser *user = self.allStudentsArray[indexPath.row];
    
    LogRed(@"点击的学生ID为%@", user.userID);
    
    NDUserCell *cell = (NDUserCell *)[collectionView cellForItemAtIndexPath:indexPath];
    //头像震动
    [self shakeCell:cell];
    //点名并发送消息
    [self rollCall:user];
}
#pragma mark 老师点名方法
- (void)rollCall:(NDUser *)user {
    NSDictionary *userDic = [NSDictionary dictionaryWithObject:user.userID forKey:@"userID"];
    NSDictionary *funcDic = [NSDictionary dictionaryWithObjectsAndKeys:@"Rollcall",@"function",userDic,@"user",[NSNumber numberWithInteger:0],@"pencolor", nil];
    NSMutableDictionary *rollCallDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:funcDic, @"msg", nil];
    LogBlue(@"rollCallDic = %@", rollCallDic);
    NSError *error = nil;
    NSData *msgData = [NSJSONSerialization dataWithJSONObject:rollCallDic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding];
    LogBlue(@"%@", jsonString);
    [self.xmppRoom sendMessageWithBody:jsonString];
}
#pragma mark 学生头像震动方法
- (void)shakeCell:(NDUserCell *)cell {
    
    CALayer *layer = cell.layer;
    CGPoint position = layer.position;
    //移动的两个终点位置
    CGPoint beginPosition = CGPointMake(position.x, position.y - 5.f);
    CGPoint endPosition = CGPointMake(position.x, position.y + 5.f);
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    //设置开始位置
    [animation setFromValue:[NSValue valueWithCGPoint:beginPosition]];
    //设置结束位置
    [animation setToValue:[NSValue valueWithCGPoint:endPosition]];
    //设置时间
    [animation setDuration:.2f];
    //设置次数
    [animation setRepeatCount:5];
    [layer addAnimation:animation forKey:nil];
}
#pragma mark 发送学生信息方法
- (void)sendStudentInfo {
    NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:@"USER_NAME"];
    NDUser *user = [NDUser new];
    user.username = userName;
    user.userID = self.nickName;
    user.userIcon = [self getImageStringFromFile];
    
    NSDictionary *dic = user.mj_keyValues;
    NSMutableDictionary *funcDic = [NSMutableDictionary dictionaryWithObject:dic forKey:@"user"];
    [funcDic setObject:@"user_join" forKey:@"function"];
    [funcDic setObject:[NSNumber numberWithInt:0] forKey:@"pencolor"];

    NSDictionary *msgDic = [NSDictionary dictionaryWithObject:funcDic forKey:@"msg"];
    
    NSError *error = nil;
    NSData *msgData = [NSJSONSerialization dataWithJSONObject:msgDic options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding];
    
    [self.xmppRoom sendMessageWithBody:jsonString];
}
#pragma mark 懒加载声音合成器
- (AVSpeechSynthesizer *)synthesizer {
    if(_synthesizer == nil) {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    return _synthesizer;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)btnEnable:(BOOL)state {
    
    self.observer = !state;
    _titleLabel.text = state?@"ND笔记":@"观察者";
    if (!state) {
        _bottomView.hidden = !state;
    }
    _canvasView.userInteractionEnabled =
    _trackColorBtn.enabled =
    _clearBtn.enabled =
    _undoBtn.enabled =
    _penSizeBtn.enabled =
    _saveBtn.enabled = state;
    
}
@end
