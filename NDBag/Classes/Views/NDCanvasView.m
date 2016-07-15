//
//  NDCanvasView.m
//  NDBag
//
//  Created by 新界教育 on 16/7/4.
//  Copyright © 2016年 新界教育. All rights reserved.
//

#import "NDCanvasView.h"

#define SIDE_LENGTH 40.f

@interface NDCanvasView ()

@property (nonatomic, strong) UIColor *savedColor;

@property (nonatomic, strong) UIImageView *penIV;

@end

@implementation NDCanvasView


- (void)drawRect:(CGRect)rect {
    
    //如果【笔画数组】有笔画字典,则按顺序将笔画取出，画到画布上
    [self drawStrokesArrToCanvas];
    
    if (self.receivedLine) {//如果接收的内容有值再去绘图
        [self drawReceivedLine];
    }
    
    if (self.receivedStudentStrokesArr) {
        [self drawStudentLine];
    }
}

-(instancetype) init {
    
    self = [super init];
    
    // 成员初始化
    // 【笔画数组】
    _strokesArr = [NSMutableArray array];
    // 【被丢弃的笔画数组】
    _abandonedStrokesArr = [NSMutableArray array];
    // 笔画大小
    _currentSize = 5.0f;
    // 设置笔刷 黑色
    [self setStrokeColor:[UIColor blackColor]];
    
    // 设置KVO监听
    [self addObserver:self forKeyPath:@"receivedLine" options:NSKeyValueObservingOptionNew context:nil];
    
    // 成员初始化
    // 【接收的笔画数组】
    _receivedStrokesArr = [NSMutableArray array];
    
    _receivedStudentStrokesArr = [NSMutableArray array];
    //注册学生被点名的通知观察者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needDraw) name:@"needDraw" object:nil];
    
    return self;
}



// 重要,设置笔刷 新的颜色
-(void) setStrokeColor:(UIColor*)newColor
{
    _currentColor = newColor;
}
// 撤销按钮点击事件
-(void) undo {
    // 如果笔画数组中有笔画字典
    if ([_strokesArr count] > 0) {
        
        // 最后一个笔画字典,即,被丢弃的笔画字典
        NSMutableDictionary* abandonedStrokeDict = [_strokesArr lastObject];
        
        // 将最后一个笔画字典,添加到被丢弃的笔画字典数组里面保存,以供drawRect
        [_abandonedStrokesArr addObject:abandonedStrokeDict];
        
        // 从所有笔画数组中移除掉最后一笔
        [_strokesArr removeLastObject];
        
        // 重新调用drawRect进行绘制
        [self setNeedsDisplay];
    }
    
}
// 2.如果【笔画数组】有笔画字典,则按顺序将笔画取出，画到画布上
- (void)drawStrokesArrToCanvas
{
    // 如果【笔画数组】为空,则直接返回
    if (_strokesArr.count == 0) return;
    
    // 遍历【笔画数组】,取出每一个笔画字典,每一次迭代,画一个stroke
    for (NDLine *line in _strokesArr) {
        
        [self drawLine:line];
    }
}
- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event
{
    // 一个笔画中的所有点,触摸开始时的【起点】
    NSMutableArray *pointsArrInOneStroke = [NSMutableArray array];
    NDLine *line = [[NDLine alloc] init];
    // 落笔点
    CGPoint point = [[touches anyObject] locationInView:self];
    [pointsArrInOneStroke addObject:NSStringFromCGPoint(point)];
    line.points = pointsArrInOneStroke;

    if (!IS_TEACHER) {
        if (!self.savedColor) {
            //学生的笔迹颜色为1-5
            self.savedColor = [self getColorWithColorNumber:arc4random() % 5 + 1];
            line.color = _currentColor = self.savedColor;
        } else {
            line.color = self.savedColor;
        }
    } else {
        line.color = _currentColor;
    }
    line.size = _currentSize;
    [self.strokesArr addObject:line];
    [self setNeedsDisplay];

    
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    NSString *currentTime = [NSString stringWithFormat:@"%llu", recordTime];
    
    
    if (IS_TEACHER) {
        [self generateLineModelWithPoint:point currentTime:currentTime action:0];
        
    } else {
        [self generateStudentLineModelWithPoint:point currentTime:currentTime action:0];
    }
    if (!self.penIV) {
        self.penIV = [UIImageView new];
        self.penIV.image = [UIImage imageNamed:@"cursor_pen"];
    }
    if (CURRENT_DEVICE > 7) {
        //120为状态栏高20＋蓝色顶部栏高44＋白色工具栏高56
        self.penIV.frame = CGRectMake(point.x, point.y + 20 + TOPVIEW_HEIGHT + TOOLBAR_HEIGHT, SIDE_LENGTH, SIDE_LENGTH);
    } else {
        self.penIV.frame = CGRectMake(point.x, point.y + 64, 30.f, 30.f);
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.penIV];
}

// 将每一个点添加到 点数组

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event
{
    // 移动后的一个点
    CGPoint point = [[touches anyObject] locationInView:self];
    
    NDLine *line = [_strokesArr lastObject];
    [line.points addObject:NSStringFromCGPoint(point)];
    [self setNeedsDisplay];

    UInt64 recordTime = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *currentTime = [NSString stringWithFormat:@"%llu", recordTime];

    if (IS_TEACHER) {
        [self generateLineModelWithPoint:point currentTime:currentTime action:2];
    } else {
        [self generateStudentLineModelWithPoint:point currentTime:currentTime action:2];
    }
    if (CURRENT_DEVICE > 7) {
        self.penIV.frame = CGRectMake(point.x, point.y + 20 + TOPVIEW_HEIGHT + TOOLBAR_HEIGHT, SIDE_LENGTH, SIDE_LENGTH);
    } else {
        self.penIV.frame = CGRectMake(point.x, point.y + 64, 30.f, 30.f);
    }
    
}

// 手势结束(画笔抬起)

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event
{
    [_abandonedStrokesArr removeAllObjects];
    
    //修改
    // 移动后的一个点
    CGPoint point = [[touches anyObject] locationInView:self];

    NDLine *line = [_strokesArr lastObject];
    [line.points addObject:NSStringFromCGPoint(point)];
    
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *currentTime = [NSString stringWithFormat:@"%llu", recordTime];


    if (IS_TEACHER) {
        [self generateLineModelWithPoint:point currentTime:currentTime action:1];
    } else {
        [self generateStudentLineModelWithPoint:point currentTime:currentTime action:1];
    }
    
    self.penIV.hidden = YES;
    self.penIV = nil;
}
- (void)generateStudentLineModelWithPoint:(CGPoint)point currentTime:(NSString *)currentTime action:(int)action {
    if (!self.studentLine) {
        self.studentLine = [[NDStudentLineModel alloc] init];
    }
    self.studentLine.function = @"setPathInfoByStudent";
    self.studentLine.pencolor = [self getColorNumberWithColor:_currentColor];
    self.pathInfo = [[NDPathInfo alloc] init];
    self.pathInfo.x = point.x;
    self.pathInfo.y = point.y;
    self.pathInfo.current_time = currentTime;
    self.pathInfo.lineWidth = _currentSize;
    self.pathInfo.action = action;
    self.pathInfo.screenWidth = SCREEN_WIDTH;
    if (CURRENT_DEVICE > 7) {
        //120为状态栏高20＋蓝色顶部栏高44＋白色工具栏高56
        self.pathInfo.screenHeight = SCREEN_HEIGHT - 20 - TOPVIEW_HEIGHT - TOOLBAR_HEIGHT;
    } else {
        self.pathInfo.screenHeight = SCREEN_HEIGHT - 64;
    }
    
    if (!self.studentLine.pathInfos) {
        self.studentLine.pathInfos = [NSMutableArray arrayWithObject:self.pathInfo];
    } else {
        [self.studentLine.pathInfos addObject:self.pathInfo];
    }
    
    
}

- (void)generateLineModelWithPoint:(CGPoint)point currentTime:(NSString *)currentTime action:(int)action {
    self.currentLine = [[NDTeacherLineModel alloc] init];
    self.currentLine.function = @"setPathInfoByTeacher";
    self.currentLine.pencolor = [self getColorNumberWithColor:_currentColor];
    self.pathInfo = [[NDPathInfo alloc] init];
    self.pathInfo.x = point.x;
    self.pathInfo.y = point.y;
    self.pathInfo.current_time = currentTime;
    self.pathInfo.lineWidth = _currentSize;
    self.pathInfo.action = action;
    self.pathInfo.screenWidth = SCREEN_WIDTH;
    if (CURRENT_DEVICE > 7) {
        //120为状态栏高20＋蓝色顶部栏高44＋白色工具栏高56
        self.pathInfo.screenHeight = SCREEN_HEIGHT - 20 - TOPVIEW_HEIGHT - TOOLBAR_HEIGHT;
    } else {
        self.pathInfo.screenHeight = SCREEN_HEIGHT - 64;
    }
    
    self.currentLine.pathInfo = self.pathInfo;
    [self.delegate didDraw];
    
    self.currentLine = nil;
    self.pathInfo = nil;
    
}

- (int)getColorNumberWithColor:(UIColor *)color {
    if ([color isEqual:[UIColor blackColor]]) {
        return 0;
    } else if ([color isEqual:ColorFromHex(0x057312)]) {
        return 1;
    } else if ([color isEqual:ColorFromHex(0x1080a5)]) {
        return 2;
    } else if ([color isEqual:ColorFromHex(0x0f1a9e)]) {
        return 3;
    } else if ([color isEqual:ColorFromHex(0x4700a8)]) {
        return 4;
    } else if ([color isEqual:ColorFromHex(0xa8009e)]) {
        return 5;
    } else {
        return 100;
    }
}

- (UIColor *)getColorWithColorNumber:(int)colorNumber {
    switch (colorNumber) {
        case 0:
            return [UIColor blackColor];
            break;
        case 1:
            return ColorFromHex(0x057312);
            break;
        case 2:
            return ColorFromHex(0x1080a5);
            break;
        case 3:
            return ColorFromHex(0x0f1a9e);
            break;
        case 4:
            return ColorFromHex(0x4700a8);
            break;
        case 5:
            return ColorFromHex(0xa8009e);
            break;
        default:
            return [UIColor clearColor];
            break;
    }
}

// 禁止多点触摸
-(BOOL)isMultipleTouchEnabled {
    return NO;
}

//接收别人传过来的画图消息，模拟手势识别，重写三个方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    CGFloat x = self.receivedLine.pathInfo.x;
    CGFloat y = self.receivedLine.pathInfo.y;
    CGPoint point = CGPointMake(x, y);
    LogRed(@"KVO实时被执行了,此时接收的点为%@,action为%d", NSStringFromCGPoint(point), self.receivedLine.pathInfo.action);
    int action = self.receivedLine.pathInfo.action;
    switch (action) {
        case 0:
            [self touchesBegan];
            break;
        case 2:
            [self touchesMoved];
            break;
        case 1:
            [self touchesEnded];
            break;
    }
}


//模拟手势识别的touchBegan方法
- (void)touchesBegan {
    
    // 一个笔画中的所有点,触摸开始时的【起点】
    NSMutableArray *pointsArrInOneStroke = [NSMutableArray array];
    NDLine *line = [NDLine new];
    
    
    int receivedColorNumber = self.receivedLine.pencolor;
    line.color = [self getColorWithColorNumber:receivedColorNumber];
    
    line.size = self.receivedLine.pathInfo.lineWidth;
    
    CGFloat x = self.receivedLine.pathInfo.x;
    CGFloat y = self.receivedLine.pathInfo.y;
    CGPoint point = CGPointMake(x, y);
    
    [pointsArrInOneStroke addObject:NSStringFromCGPoint(point)];
    
    line.points = pointsArrInOneStroke;
    LogRed(@"将解析完成的坐标存入Line模型对象的points数组中,接收到的坐标转换后为:%@\n此时Line模型对象的points数组元素个数为%lu", NSStringFromCGPoint(point), line.points.count);
    [_receivedStrokesArr addObject:line];
    
    [self setNeedsDisplay];
    
    if (!self.penIV) {
        self.penIV = [UIImageView new];
        self.penIV.image = [UIImage imageNamed:@"cursor_pen"];
        [[UIApplication sharedApplication].keyWindow addSubview:self.penIV];
    }
    if (CURRENT_DEVICE > 7) {
        //120为状态栏高20＋蓝色顶部栏高44＋白色工具栏高56
        self.penIV.frame = CGRectMake(point.x, point.y + 20 + TOPVIEW_HEIGHT + TOOLBAR_HEIGHT, SIDE_LENGTH, SIDE_LENGTH);
    } else {
        self.penIV.frame = CGRectMake(point.x, point.y + 64, 30.f, 30.f);
    }
    
    
}

- (void)touchesMoved {
    
    CGFloat x = self.receivedLine.pathInfo.x;
    CGFloat y = self.receivedLine.pathInfo.y;
    CGPoint point = CGPointMake(x, y);
    
    LogRed(@"自定义的移动方法被实时调用了,此时的point = %@", NSStringFromCGPoint(point));
    NDLine *line = [_receivedStrokesArr lastObject];
    [line.points addObject:NSStringFromCGPoint(point)];
    [self setNeedsDisplay];
    
    if (CURRENT_DEVICE > 7) {
        //120为状态栏高20＋蓝色顶部栏高44＋白色工具栏高56
        self.penIV.frame = CGRectMake(point.x, point.y + 20 + TOPVIEW_HEIGHT + TOOLBAR_HEIGHT, SIDE_LENGTH, SIDE_LENGTH);
    } else {

        self.penIV.frame = CGRectMake(point.x, point.y + 64, 30.f, 30.f);
    }
    
}

- (void)touchesEnded {
    LogBlue(@"%s", __func__);
    
    self.penIV.hidden = YES;
    self.penIV = nil;

}

- (void)drawReceivedLine {
    if (_receivedStrokesArr.count == 0) {
        return;
    }
    LogGreen(@"接收到消息开始画画了,接收到的数组元素个数%lu", _receivedStrokesArr.count);
    
    for (NDLine *line in _receivedStrokesArr) {
        [self drawLine:line];
    }
}

- (void)needDraw {

    for (NDPathInfo *pathInfo in self.tempLine.pathInfos) {
        int action = pathInfo.action;
        NSUInteger index;
        switch (action) {
            case 0:
            {
                index = [self.tempLine.pathInfos indexOfObject:pathInfo];
                [self touchesBeganWith:index];
                break;
            }
            case 2:
            {
                index = [self.tempLine.pathInfos indexOfObject:pathInfo];
                [self touchesMovedWith:index];
                break;
            }
            case 1:
            {
                index = [self.tempLine.pathInfos indexOfObject:pathInfo];
                [self touchesEndedWith:index];
                break;
            }
        }
        
    }
}

- (void)touchesBeganWith:(NSUInteger)index {
    // 一个笔画中的所有点,触摸开始时的【起点】
    NSMutableArray *pointsArrInOneStroke = [NSMutableArray array];
    NDLine *line = [NDLine new];
    int receivedColorNumber = self.tempLine.pencolor;
    line.color = [self getColorWithColorNumber:receivedColorNumber];
    
    NDPathInfo *pathInfo = [self.tempLine.pathInfos objectAtIndex:index];
    
    LogRed(@"pathInfo.screenWidth = %g, pathInfo.screenHeight = %g, pathInfo.x = %g, pathInfo.y = %g", pathInfo.screenWidth, pathInfo.screenHeight, pathInfo.x, pathInfo.y);
    
    line.size = pathInfo.lineWidth;
    CGFloat x = pathInfo.x;
    CGFloat y = pathInfo.y;
    
    
    CGPoint point = CGPointMake(x, y);
    [pointsArrInOneStroke addObject:NSStringFromCGPoint(point)];
    line.points = pointsArrInOneStroke;
    [_receivedStudentStrokesArr addObject:line];
    
}
- (void)touchesMovedWith:(NSUInteger)index {
    
    
    NDPathInfo *pathInfo = [self.tempLine.pathInfos objectAtIndex:index];
    CGFloat x = pathInfo.x;
    CGFloat y = pathInfo.y;
    
    CGPoint point = CGPointMake(x, y);
    NDLine *line = [_receivedStudentStrokesArr lastObject];
    [line.points addObject:NSStringFromCGPoint(point)];
    
    
}
- (void)touchesEndedWith:(NSUInteger)index {
    
    [self setNeedsDisplay];
}

- (void)drawStudentLine {
    if (_receivedStudentStrokesArr.count == 0) {
        return;
    }
    LogGreen(@"收到点名消息开始画画了,接收到的数组元素个数%lu", _receivedStudentStrokesArr.count);
    for (NDLine *line in _receivedStudentStrokesArr) {
        [self drawLine:line];
    }
}

- (void)drawLine:(NDLine *)line {
    NSArray *pointsArr = line.points;
    UIColor *color = line.color;
    CGFloat size;
    //没接收到值
    if (line.size > 0) {
        size = line.size;
    } else {
        size = 5.f;
    }
    [color set];
    // 创建一个贝塞尔路径
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    // 点数组 中的起点
    CGPoint startPoint = CGPointFromString([pointsArr objectAtIndex:0]);
    
    // 将路径移动到 起点
    [bezierPath moveToPoint:startPoint];
    
    if (pointsArr.count == 1) {//只画一个点
        CGPoint pointNext = startPoint;
        [bezierPath addLineToPoint:pointNext];
    }
    // 遍历点数组,将每一个点,依次添加到 bezierPath
    for (int i = 0; i < (pointsArr.count - 1); i++)
    {
        // 依次取出下一个点
        CGPoint pointNext = CGPointFromString([pointsArr objectAtIndex:i+1]);
        // 添加到路径
        [bezierPath addLineToPoint:pointNext];
    }
    // 设置线宽
    bezierPath.lineWidth = size;
    // 线连接处为 圆结头
    bezierPath.lineJoinStyle = kCGLineJoinRound;
    // 线两端为 圆角
    bezierPath.lineCapStyle = kCGLineCapRound;
    // 调用路径的方法 画出一条线
    [bezierPath stroke];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"receivedLine"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
