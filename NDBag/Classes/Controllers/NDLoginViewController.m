//
//  NDLoginViewController.m
//  NDBag
//
//  Created by 新界教育 on 16/6/30.
//  Copyright © 2016年 新界教育. All rights reserved.
//


#define CHECKBOX_SIDELENGTH 36.f
#define CHECKBOX_SELECTED @"radio2"
#define CHECKBOX_UNSELECTED @"radio1"
#define PHOTOBTN_SELECTED @"button_picture1"
#define PHOTOBTN_UNSELECTED @"button_picture2"
#define GALLERYBTN_SELECTED @"button_album1"
#define GALLERYBTN_UNSELECTED @"button_album2"
#define PHOTO_IMAGE @"icon_photograph"
#define GALLERY_IMAGE @"icon_picture"
#define BTN_WIDTH 168.f
#define BTN_HEIGHT 55.f



#import "NDLoginViewController.h"

#import "NDMainViewController.h"


#import "NDOrientationTool.h"

@interface NDLoginViewController () <UIImagePickerControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) UITextField *nameTF;
@property (nonatomic, strong) UIImageView *backgroundIV;
@property (nonatomic, strong) UIButton *studentCheckbox;
@property (nonatomic, strong) UIButton *teacherCheckbox;
@property (nonatomic, strong) UIButton *takePhotoBtn;
@property (nonatomic, strong) UIButton *galleryBtn;
@property (nonatomic, strong) UIImageView *bottomIV;
@property (nonatomic, strong) UIButton *centerBtn;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *pickedImage;
@property (nonatomic, strong) NSFileManager *manager;
@end

@implementation NDLoginViewController

singleton_implementation(NDLoginViewController);

- (void)viewDidAppear:(BOOL)animated {
    NSString *savedName = [[NSUserDefaults standardUserDefaults] valueForKey:@"USER_NAME"];
    if (savedName.length) {
    
        NDMainViewController *mainVC = [NDMainViewController new];
        [self presentViewController:mainVC animated:YES completion:nil];
        
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [MBProgressHUD hideHUD];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [self initUI];

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)initUI {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    _backgroundIV = [UIImageView new];
    _backgroundIV.image = BACKGROUND_IMAGE;
    [self.view addSubview:_backgroundIV];
    [_backgroundIV mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(20, 0, 0, 0));
        } else if (CURRENT_DEVICE >= 4 && CURRENT_DEVICE < 8){
            make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 0, 0));
        }
    }];
    _backgroundIV.userInteractionEnabled = YES;
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = @"ND笔记";

    titleLabel.font = [UIFont systemFontOfSize:22.f];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    [_backgroundIV addSubview:titleLabel];
    titleLabel.backgroundColor = ColorFromHex(0x1d95d4);
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.equalTo(_backgroundIV);
        if (CURRENT_DEVICE == 8) {
            make.height.mas_equalTo(TOPVIEW_HEIGHT);
        } else if (CURRENT_DEVICE == 6){
            make.height.mas_equalTo(34);
        } else if (CURRENT_DEVICE == 5) {
            make.height.mas_equalTo(30);
        }
        
    }];
    
    UIImageView *inputBg = [UIImageView new];
    [_backgroundIV addSubview:inputBg];
    inputBg.image = [UIImage imageNamed:@"input_bg"];
    [inputBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_backgroundIV);
        if (CURRENT_DEVICE == 8) {
            make.top.equalTo(titleLabel.mas_bottom).offset(60);
            make.width.mas_equalTo(324);
            make.height.equalTo(@52);
        } else if (CURRENT_DEVICE == 6) {
            make.top.equalTo(titleLabel.mas_bottom).offset(25);
            make.width.mas_equalTo(284);
            make.height.equalTo(@40);
        } else if (CURRENT_DEVICE == 5) {
            make.top.equalTo(titleLabel.mas_bottom).offset(20);
            make.width.mas_equalTo(264);
            make.height.equalTo(@30);
        }
    }];
    _nameTF = [UITextField new];
    _nameTF.placeholder = @"请输入姓名";
    _nameTF.borderStyle = UITextBorderStyleNone;
    [_backgroundIV addSubview:_nameTF];
    [_nameTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(inputBg).offset(10);
        make.centerY.height.equalTo(inputBg);
        if (CURRENT_DEVICE == 8) {
            make.width.mas_equalTo(314);
        } else if (CURRENT_DEVICE == 6) {
            make.width.mas_equalTo(274);
        } else if (CURRENT_DEVICE == 5) {
            make.width.mas_equalTo(264);
        }
    }];
    
    
    
    
    [self configCheckBox];
    [self configBtns];
    [self configBottomViews];
    
}

- (void)configCheckBox {
    //学生用户按钮
    _studentCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
    _studentCheckbox.tag = 101;
    [_backgroundIV addSubview:_studentCheckbox];
    [_studentCheckbox mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.leading.mas_equalTo(400);
            make.top.equalTo(_nameTF.mas_bottom).offset(26);
            make.width.height.mas_equalTo(CHECKBOX_SIDELENGTH);
        } else if (CURRENT_DEVICE == 6) {
            make.leading.mas_equalTo(235);
            make.top.equalTo(_nameTF.mas_bottom).offset(16);
            make.width.height.mas_equalTo(28);
        } else if (CURRENT_DEVICE == 5) {
            make.leading.mas_equalTo(195);
            make.top.equalTo(_nameTF.mas_bottom).offset(12);
            make.width.height.mas_equalTo(24);
        }
    }];
    [_studentCheckbox setImage:[UIImage imageNamed:CHECKBOX_UNSELECTED] forState:UIControlStateNormal];
    [_studentCheckbox setImage:[UIImage imageNamed:CHECKBOX_SELECTED] forState:UIControlStateSelected];
    [_studentCheckbox addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_studentCheckbox setSelected:YES];
    UILabel *studentLabel = [UILabel new];
    studentLabel.text = @"学生";
    [_backgroundIV addSubview:studentLabel];
    [studentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_studentCheckbox.mas_trailing).offset(12);
        make.height.centerY.equalTo(_studentCheckbox);
    }];
    
    
    
    //教师用户按钮
    _teacherCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
    _teacherCheckbox.tag = 102;
    [_backgroundIV addSubview:_teacherCheckbox];
    [_teacherCheckbox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_studentCheckbox);
        make.width.height.equalTo(_studentCheckbox);
        make.leading.equalTo(studentLabel.mas_trailing).offset(46);
    }];
    UILabel *teacherLabel = [UILabel new];
    teacherLabel.text = @"教师";
    [_backgroundIV addSubview:teacherLabel];
    [teacherLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_teacherCheckbox.mas_trailing).offset(12);
        make.height.centerY.equalTo(_teacherCheckbox);
    }];
    [_teacherCheckbox setImage:[UIImage imageNamed:CHECKBOX_UNSELECTED] forState:UIControlStateNormal];
    [_teacherCheckbox setImage:[UIImage imageNamed:CHECKBOX_SELECTED] forState:UIControlStateSelected];
    [_teacherCheckbox addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_teacherCheckbox setSelected:NO];
}

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        _imagePickerController = [UIImagePickerController new];
        _imagePickerController.delegate = self;
        _imagePickerController.allowsEditing = NO;
    }
    return _imagePickerController;
}

-(void)btnClick:(UIButton *)btn
{
    if (btn.isSelected) {
        return;
    }
    if (btn.tag == 101) {//学生单选按钮
        btn.selected = !btn.selected;
        _teacherCheckbox.selected = !btn.selected;
    } else if (btn.tag == 102) {//教师单选按钮
        btn.selected = !btn.selected;
        _studentCheckbox.selected = !btn.selected;
    } else if (btn.tag == 103) {//拍照选项按钮
        btn.selected = !btn.selected;
        _galleryBtn.selected = !btn.selected;
        [_centerBtn setImage:[UIImage imageNamed:PHOTO_IMAGE] forState:UIControlStateNormal];
    } else if (btn.tag == 104) {//相册选项按钮
        btn.selected = !btn.selected;
        _takePhotoBtn.selected = !btn.selected;
        [_centerBtn setImage:[UIImage imageNamed:GALLERY_IMAGE] forState:UIControlStateNormal];
    } else if (btn.tag == 105) {//拍照/相册按钮
        AppDelegate * app = [UIApplication sharedApplication].delegate;
        app.shouldChangeOrientation = NO;
        if (_takePhotoBtn.isSelected) {
            BOOL isCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] || [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
            if (isCamera) {
                self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                [self presentViewController:self.imagePickerController animated:YES completion:^{
                    
                }];
            } else {
                LogRed(@"当前是模拟器，无法调用摄像头");
                return;
            }
        } else {
            self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
            
        }
    } else if (btn.tag == 106) {//保存按钮
        [self willLogin];
    } else if (btn.tag == 107) {//取消按钮
        if (_takePhotoBtn.isSelected) {
            [_centerBtn setImage:[UIImage imageNamed:PHOTO_IMAGE] forState:UIControlStateNormal];
        } else {
            [_centerBtn setImage:[UIImage imageNamed:GALLERY_IMAGE] forState:UIControlStateNormal];
        }
        self.pickedImage = nil;
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 必须手动,关闭照片选择器
    
    
    AppDelegate * app = [UIApplication sharedApplication].delegate;
    app.shouldChangeOrientation = YES;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    self.pickedImage = [[NDOrientationTool sharedNDOrientationTool] fixOrientation:pickedImage];
    
    [_centerBtn setImage:self.pickedImage forState:UIControlStateNormal];
}



- (void)configBtns {
    _takePhotoBtn = [UIButton new];
    _takePhotoBtn.tag = 103;
    [_takePhotoBtn setImage:[UIImage imageNamed:PHOTOBTN_SELECTED] forState:UIControlStateSelected];
    [_takePhotoBtn setImage:[UIImage imageNamed:PHOTOBTN_UNSELECTED] forState:UIControlStateNormal];
    [_takePhotoBtn setSelected:YES];
    [_backgroundIV addSubview:_takePhotoBtn];
    [_takePhotoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.leading.equalTo(_backgroundIV.mas_leading).offset(134);
            make.top.equalTo(_studentCheckbox.mas_bottom).offset(78);
            make.width.mas_equalTo(BTN_WIDTH);
            make.height.mas_equalTo(BTN_HEIGHT);
        } else if (CURRENT_DEVICE == 6) {
            make.leading.equalTo(_backgroundIV.mas_leading).offset(84);
            make.top.equalTo(_studentCheckbox.mas_bottom).offset(25);
            make.width.mas_equalTo(108);
            make.height.mas_equalTo(35);
        } else if (CURRENT_DEVICE == 5) {
            make.leading.equalTo(_backgroundIV.mas_leading).offset(84);
            make.top.equalTo(_studentCheckbox.mas_bottom).offset(20);
            make.width.mas_equalTo(88);
            make.height.mas_equalTo(28);
        }
        
    }];
    [_takePhotoBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _galleryBtn = [UIButton new];
    _galleryBtn.tag = 104;
    [_galleryBtn setImage:[UIImage imageNamed:GALLERYBTN_SELECTED] forState:UIControlStateSelected];
    [_galleryBtn setImage:[UIImage imageNamed:GALLERYBTN_UNSELECTED] forState:UIControlStateNormal];
    [_backgroundIV addSubview:_galleryBtn];
    [_galleryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.width.height.equalTo(_takePhotoBtn);
        if (CURRENT_DEVICE == 8) {
            make.leading.equalTo(_takePhotoBtn.mas_trailing).offset(18);
        } else if (CURRENT_DEVICE == 6) {
            make.leading.equalTo(_takePhotoBtn.mas_trailing).offset(12);
        } else if (CURRENT_DEVICE == 5) {
            make.leading.equalTo(_takePhotoBtn.mas_trailing).offset(9);
        }
        
    }];
    [_galleryBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
}

- (UIButton *)centerBtn {
    if (!_centerBtn) {
        _centerBtn = [UIButton new];
        [_bottomIV addSubview:_centerBtn];
        _centerBtn.tag = 105;
        [_centerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_bottomIV);
            if (CURRENT_DEVICE == 8) {
                make.width.height.equalTo(@186);
                make.top.equalTo(_bottomIV).offset(48);
            } else if (CURRENT_DEVICE == 6) {
                make.width.height.equalTo(@88);
                make.top.equalTo(_bottomIV).offset(12);
            } else if (CURRENT_DEVICE == 5) {
                make.width.height.equalTo(@88);
                make.top.equalTo(_bottomIV).offset(12);
            }
            
        }];
        [_centerBtn setImage:[UIImage imageNamed:PHOTO_IMAGE] forState:UIControlStateNormal];
        [_centerBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _centerBtn;
}

- (void)configBottomViews {
    
    _bottomIV = [UIImageView new];
    _bottomIV.image = [UIImage imageNamed:@"background"];
    _bottomIV.userInteractionEnabled = YES;
    [_backgroundIV addSubview:_bottomIV];
    [_bottomIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_takePhotoBtn.mas_leading);
        make.top.equalTo(_takePhotoBtn.mas_bottom);
        if (CURRENT_DEVICE == 8) {
            make.bottom.equalTo(_backgroundIV.mas_bottom).offset(-66);
            make.width.equalTo(@754);
        } else if (CURRENT_DEVICE == 6) {
            make.bottom.equalTo(_backgroundIV.mas_bottom).offset(-16);
            make.width.equalTo(@484);
        } else if (CURRENT_DEVICE == 5) {
            make.bottom.equalTo(_backgroundIV.mas_bottom).offset(-12);
            make.width.equalTo(@394);
        }
        
    }];
    self.centerBtn.hidden = NO;
    UIButton *saveBtn = [UIButton new];
    saveBtn.tag = 106;
    [saveBtn setImage:[UIImage imageNamed:@"button_save1"] forState:UIControlStateNormal];
    [saveBtn setImage:[UIImage imageNamed:@"button_save2"] forState:UIControlStateHighlighted];
    [_bottomIV addSubview:saveBtn];
    [saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (CURRENT_DEVICE == 8) {
            make.width.equalTo(@142);
            make.height.equalTo(@42);
            make.leading.equalTo(_bottomIV).offset(214);
            make.top.equalTo(_centerBtn.mas_bottom).offset(40);
        } else if (CURRENT_DEVICE == 6) {
            make.width.equalTo(@98);
            make.height.equalTo(@30);
            make.leading.equalTo(_bottomIV).offset(124);
            make.top.equalTo(_centerBtn.mas_bottom).offset(10);
        } else if (CURRENT_DEVICE ==5) {
            make.width.equalTo(@78);
            make.height.equalTo(@23);
            make.leading.equalTo(_bottomIV).offset(100);
            make.top.equalTo(_centerBtn.mas_bottom).offset(8);
        }
        
    }];
    [saveBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *cancelBtn = [UIButton new];
    cancelBtn.tag = 107;
    [cancelBtn setImage:[UIImage imageNamed:@"button_cancel1"] forState:UIControlStateNormal];
    [cancelBtn setImage:[UIImage imageNamed:@"button_cancel2"] forState:UIControlStateHighlighted];
    [_bottomIV addSubview:cancelBtn];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(saveBtn.mas_trailing).offset(40);
        make.centerY.height.width.equalTo(saveBtn);
    }];
    [cancelBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
}

- (void)showToast:(NSString *)text
{
    [self.view.window makeToast:text duration:3 position:CSToastPositionCenter];
}

- (void)willLogin {
    if (!_nameTF.text.length) {
        [self showToast:@"请填写用户名"];
        return;
    }
    if (!self.pickedImage) {
        [self showToast:@"请设置头像"];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NDMainViewController *mainVC = [NDMainViewController new];
        [self presentViewController:mainVC animated:YES completion:^{
            _studentCheckbox.selected = YES;
            _teacherCheckbox.selected = NO;
            _takePhotoBtn.selected = YES;
            _galleryBtn.selected = NO;
            [_centerBtn setImage:[UIImage imageNamed:PHOTO_IMAGE] forState:UIControlStateNormal];
            _nameTF.text = nil;
        }];
    });
    [self saveUserData];
    
}

- (void)saveUserData {
    
    
    [[NDLocalCacheManager sharedManager] clearLocalCache];
    
    //存储头像到本地
    UIImage *scaledImage;
    scaledImage = [self scalingAndCroppingImage:self.pickedImage toSize:CGSizeMake(186.f, 186.f)];
    NSString *imageStr = [self imageToNSString:scaledImage];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *avatarFilePath = [documentsPath stringByAppendingPathComponent:@"UserAvatarData.txt"];
    
    [[NSUserDefaults standardUserDefaults] setBool:_teacherCheckbox.isSelected?YES:NO forKey:@"IS_TEACHER"];
    [[NSUserDefaults standardUserDefaults] setValue:_nameTF.text forKey:@"USER_NAME"];
    
    [self.manager createFileAtPath:avatarFilePath contents:nil attributes:nil];
    NSData *data = [imageStr dataUsingEncoding:NSUTF8StringEncoding];
    BOOL isSuccess = [data writeToFile:avatarFilePath atomically:YES];
    if (!isSuccess) {
        LogRed(@"写入文件失败");
    }
    
}

//图片压缩到指定大小
- (UIImage*)scalingAndCroppingImage:(UIImage *)sourceImage toSize:(CGSize)targetSize
{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; //缩放适应高
        } else {
            scaleFactor = heightFactor; //缩放适应宽
        }
        scaledWidth= width * scaleFactor;
        scaledHeight = height * scaleFactor;
        //居中图片
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor < heightFactor)
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(targetSize); //裁剪
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width= scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) {
        LogRed(@"压缩图片失败");
    }
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSString *)imageToNSString:(UIImage *)image
{
    NSData *data = UIImageJPEGRepresentation(image, 1.f);
    
    return [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.pickedImage = nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_nameTF endEditing:YES];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
}

- (void)injected {
    [self viewDidLoad];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

@end
