//
//  ZBView.m
//  OpenGLES_索引
//
//  Created by Sangxiedong on 2019/6/13.
//  Copyright © 2019 ZB. All rights reserved.
//

#import "ZBView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface ZBView () {
    float _xDegree;
    float _yDegree;
    float _zDegree;
    BOOL _bX;
    BOOL _bY;
    BOOL _bZ;
    NSTimer *_myTimer;
}

@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, strong) EAGLContext *myContext;

@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;

@property (nonatomic, assign) GLuint myProgram;
@property (nonatomic, assign) GLuint myVertices;

@property (nonatomic, strong) UIButton *xButton;
@property (nonatomic, strong) UIButton *yButton;
@property (nonatomic, strong) UIButton *zButton;

@end

@implementation ZBView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configUI];
    }
    return self;
}

- (void)configUI {
    [self addSubview:self.xButton];
    [self addSubview:self.yButton];
    [self addSubview:self.zButton];
    
}

- (void)layoutSubviews {
    //1.设置图层
    [self setupLayer];
    
    //2.设置上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deleteRenderAndFrameBuffer];
    
    //4.设置renderBuffer;
    [self setupRenderBuffer];
    
    //5.设置frameBuffer
    [self setupFrameBuffer];
    
    //6.绘制
    [self render];
}

- (void)setupLayer {
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    float scale = [UIScreen mainScreen].scale;
    [self setContentScaleFactor:scale];
    self.myEagLayer.opaque = YES;
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupContext {
    self.myContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.myContext) {
        NSLog(@"create Context failed");
        return;
    }
    
    if (![EAGLContext setCurrentContext:self.myContext]) {
        NSLog(@"set Current Context failed");
        return;
    }
}

- (void)deleteRenderAndFrameBuffer {
    glDeleteBuffers(1, &_myColorRenderBuffer);
    _myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    _myColorFrameBuffer = 0;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    
    glBindRenderbuffer(GL_RENDERBUFFER, _myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (void)render {
    //1.清屏颜色
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2.设置视口
    float scale = [UIScreen mainScreen].scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //3.获取顶点着色程序、片元着色器程序文件位置
    NSString *vecFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    //4.判断self.myProgram是否存在，存在则清空其文件
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    //5.加载程序到myProgram中来。
    self.myProgram = [self loadShaderByVec:vecFile frag:fragFile];
    
    //6.链接
    glLinkProgram(self.myProgram);
    
    //7.获取链接状态
    GLint linkStatus;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[520];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"error -- %@", messageString);
        return;
    }else {
        glUseProgram(self.myProgram);
    }
    
    NSLog(@"Link Program Success");
    
    [self createVertor];
    
}

- (void)createVertor {
    //8.创建顶点数组 & 索引数组
    // 顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB) 后2位纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,   0.0f, 1.0f,        //左上0
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,   1.0f, 1.0f,        //右上1
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,   1.0f, 0.0f,        //右下2
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,   0.0f, 0.0f,        //左下3
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,   0.5f, 0.5f,        //顶点4
    };
    
    // 索引数组
    GLuint indices[] =
    {
        0, 1, 2,
        0, 2, 3,
        0, 4, 1,
        1, 4, 2,
        2, 4, 3,
        3, 4, 0,
    };
    
    // 判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    
    //9.-----处理顶点数据-------
    //(1).将_myVertices绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //(2).把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //(3).将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
    //3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    //(4).打开position
    glEnableVertexAttribArray(position);
    //(5).设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, NULL);
    
    //10.--------处理顶点颜色值-------
    //(1).glGetAttribLocation,用来获取vertex attribute的入口的.
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    //(2).打开positionColor
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (float *)NULL + 3);
    
    // 纹理坐标
    GLuint textCoord = glGetAttribLocation(self.myProgram, "textCoordinate");
    glEnableVertexAttribArray(textCoord);
    glVertexAttribPointer(textCoord, 2, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (float *)NULL + 6);
    
    // 加载纹理
    [self setupTexture:@"test"];
    
    //设置纹理采样器 sampler2D
    glUniform1f(glGetAttribLocation(self.myProgram, "colorMap"), 0);
    
    //11.找到myProgram中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象。
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    //12.创建4 * 4投影矩阵
    KSMatrix4 _projectMat;
    //(1)获取单元矩阵
    ksMatrixLoadIdentity(&_projectMat);
    //(2)计算纵横比例
    float aspect = self.frame.size.width / self.frame.size.height;
    //(3)获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     */
    ksPerspective(&_projectMat, 35, aspect, 5, 20);
    //(4)将投影矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectMat.m[0][0]);
    
    //13.创建一个4 * 4 矩阵，模型视图矩阵
    KSMatrix4 _modelViewMat;
    //(1)获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMat);
    //(2)平移，z轴平移-10
    ksTranslate(&_modelViewMat, 0, 0, -10);
    //(3)创建一个4 * 4 矩阵，旋转矩阵
    KSMatrix4 _rotationMat;
    //(4)初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMat);
    //(5)旋转 分别绕X、Y、Z轴
    ksRotate(&_rotationMat, _xDegree, 1, 0, 0);
    ksRotate(&_rotationMat, _yDegree, 0, 1, 0);
    ksRotate(&_rotationMat, _zDegree, 0, 0, 1);
    //(6)把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
    ksMatrixMultiply(&_modelViewMat, &_rotationMat, &_modelViewMat);
    //(7)将模型视图矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMat.m[0][0]);
    //14.开启剔除操作效果
    glEnable(GL_CULL_FACE);
    
    
    //15.使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
     GL_POINTS
     GL_LINES
     GL_LINE_LOOP
     GL_LINE_STRIP
     GL_TRIANGLES
     GL_TRIANGLE_STRIP
     GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
     GL_BYTE
     GL_UNSIGNED_BYTE
     GL_SHORT
     GL_UNSIGNED_SHORT
     GL_INT
     GL_UNSIGNED_INT
     indices：绘制索引数组
     
     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    //16.从渲染缓冲区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

- (void)setupTexture:(NSString *)imageName {
    
    CGImageRef imageRef = [UIImage imageNamed:imageName].CGImage;
    if (!imageRef) {
        NSLog(@"Fail to load image %@", imageName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    GLubyte *spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef spriteContext  = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextDrawImage(spriteContext, rect, imageRef);
    
    CGContextRelease(spriteContext);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    
}

- (GLuint)loadShaderByVec:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLuint program = glCreateProgram();
    
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    
    NSString *context = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    const GLchar *source = (GLchar *)[context UTF8String];
    
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
    
}

#pragma mark - 按钮 - 事件
- (void)buttonAction:(UIButton *)sender {
    //开启定时器
    if (!_myTimer) {
        _myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    if (sender.tag == 100) {
        _bX = !_bX;
    }else if (sender.tag == 200) {
        _bY = !_bY;
    }else if (sender.tag == 300) {
        _bZ = !_bZ;
    }
}

- (void)reDegree {
    
    _xDegree += _bX * 5;
    _yDegree += _bY * 5;
    _zDegree += _bZ * 5;
    
    [self render];
    
}

#pragma mark - lazy
- (UIButton *)xButton {
    if (!_xButton) {
        _xButton = [self createButtonByTitle:@"x" frame:CGRectMake(100, [UIScreen mainScreen].bounds.size.height - 100, 50, 50) action:@selector(buttonAction:) tag:100];
    }
    return _xButton;
}

- (UIButton *)yButton {
    if (!_yButton) {
        _yButton = [self createButtonByTitle:@"y" frame:CGRectMake(CGRectGetMaxX(_xButton.frame) + 50, [UIScreen mainScreen].bounds.size.height - 100, 50, 50) action:@selector(buttonAction:) tag:200];
    }
    return _yButton;
}

- (UIButton *)zButton {
    if (!_zButton) {
        _zButton = [self createButtonByTitle:@"z" frame:CGRectMake(CGRectGetMaxX(_yButton.frame) + 50, [UIScreen mainScreen].bounds.size.height - 100, 50, 50) action:@selector(buttonAction:) tag:300];
    }
    return _zButton;
}

- (UIButton *)createButtonByTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:[UIColor blueColor]];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.frame = frame;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.tag = tag;
    
    return button;
}

@end
