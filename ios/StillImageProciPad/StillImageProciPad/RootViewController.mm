#import "RootViewController.h"

// array with available test images
static NSArray *availableTestImages = [NSArray arrayWithObjects:
                                       @"building_2048x1536.jpg",
                                       @"leafs_1024x786.jpg",
                                       nil];

/**
 * RootViewController private methods
 */
@interface RootViewController ()

/**
 * Init views
 */
- (void)initUI;

/**
 * Action when input test image was selected (buttons on top)
 */
- (void)testImgBtnPressedAction:(id)sender;

/**
 * Present test image number <num>. Force display update <forceDisplay>.
 */
- (void)presentTestImg:(int)num forceDisplay:(BOOL)forceDisplay;

/**
 * Present the image processing output
 */
- (void)presentOutputImg;

/**
 * Run image processing.
 */
- (void)runImgProc;

/**
 * Helper method: Convert UIImage <img> to RGBA data.
 */
- (unsigned char *)uiImageToRGBABytes:(UIImage *)img;

/**
 * Helper method: Convert RGBA <data> of size <w>x<h> to UIImage object.
 */
- (UIImage *)rgbaBytesToUIImage:(unsigned char *)data width:(int)w height:(int)h;

@end



/**
 * RootViewController implementation
 */
@implementation RootViewController

#pragma mark init/dealloc

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // set defaults
        selectedTestImg = -1;
        displayingOutput = NO;
    }
    return self;
}

- (void)dealloc {
    // delete data buffers
    if (testImgData) delete [] testImgData;
    if (outputBuf) delete [] outputBuf;
    
    // release image objects
    [testImg release];
    [outputImg release];
    
    // release views
    [imgView release];
    [baseView release];
    
    [super dealloc];
}

#pragma mark event handling

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init UI
    [self initUI];
    
    // load default image
    [self presentTestImg:0 forceDisplay:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!displayingOutput) {
        NSLog(@"WILL DISPLAY OUTPUT");
        
        // run the image processing stuff on the GPU and display the output
        [self runImgProc];
        [self presentOutputImg];
        
        displayingOutput = YES;
    } else {
        NSLog(@"WILL DISPLAY TEST IMAGE");
        
        // display the test image as input image
        [self presentTestImg:selectedTestImg forceDisplay:YES];
        
        displayingOutput = NO;
    }
}

#pragma mark private methods

- (void)initUI {
    // get screen rect for landscape mode
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (screenRect.size.width < screenRect.size.height) {
        float tmp = screenRect.size.width;
        screenRect.size.width = screenRect.size.height;
        screenRect.size.height = tmp;
    }
    NSLog(@"loading view of size %dx%d", (int)screenRect.size.width, (int)screenRect.size.height);
    
    // create an empty base view
    baseView = [[UIView alloc] initWithFrame:screenRect];
    
    // create the test image view
    imgView = [[UIImageView alloc] initWithFrame:screenRect];
    [baseView addSubview:imgView];
    
    // create buttons for loading the test images
    int i = 0;
    int btnW = 180;
    int btnMrgn = 10;
    for (NSString *testImgName in availableTestImages) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn setTitle:[testImgName stringByDeletingPathExtension] forState:UIControlStateNormal];
        [btn setTag:i];
        [btn setBackgroundColor:[UIColor whiteColor]];
        [btn setFrame:CGRectMake(btnMrgn + (btnW + btnMrgn) * i, 20, btnW, 26)];
        [btn addTarget:self action:@selector(testImgBtnPressedAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [baseView addSubview:btn];
        i++;
    }
    
    // finally set the base view as view for this controller
    [self setView:baseView];
}

- (void)testImgBtnPressedAction:(id)sender {
    UIButton *btn = sender;
    [self presentTestImg:btn.tag forceDisplay:displayingOutput];
    displayingOutput = NO;
}

- (void)presentTestImg:(int)num forceDisplay:(BOOL)forceDisplay {
    if (!forceDisplay && selectedTestImg == num) return; // no change
    
    // get image file name
    NSString *testImgFile = [availableTestImages objectAtIndex:num];
    
    // release previous image object
    [testImg release];
    
    // load new image data
    testImg = [[UIImage imageNamed:testImgFile] retain];
    testImgW = (int)testImg.size.width;
    testImgH = (int)testImg.size.height;
    
    if (testImg) {
        NSLog(@"loaded test image %@ with size %dx%d", testImgFile, testImgW, testImgH);
    } else {
        NSLog(@"could not load test image %@", testImgFile);
    }
    
    // show the image object
    [imgView setImage:testImg];
    
    // release previous image data
    if (testImgData) delete [] testImgData;
    
    // get the RGBA bytes of the image
    testImgData = [self uiImageToRGBABytes:testImg];
    
    if (!testImgData) {
        NSLog(@"could not get RGBA data from test image %@", testImgFile);
    }
    
    // delete previous output data buffer
    if (outputBuf) delete [] outputBuf;
    
    // create output data buffer
    outputBuf = new unsigned char[testImgW * testImgH * 4];
    
    selectedTestImg = num;  // update
}

- (void)presentOutputImg {
    // release old image object
    [outputImg release];
    
    // create new image object from RGBA data
    outputImg = [[self rgbaBytesToUIImage:outputBuf
                                    width:testImgW
                                   height:testImgH] retain];
    if (!outputImg) {
        NSLog(@"error converting output RGBA data to UIImage");
    } else {
        NSLog(@"presenting output image of size %dx%d", (int)outputImg.size.width, (int)outputImg.size.height);
    }
    
    //    [imgView setFrame:CGRectMake(0, 0, outputImg.size.width, outputImg.size.height)];
    
    [imgView setImage:outputImg];
}

- (void)runImgProc {
    // (slow) example implementation
    for (int i = 0; i < testImgW * testImgH * 4; i+=4) {    // go through the buffer, pixel per pixel
        const unsigned char *inPtr = &testImgData[i];
        unsigned char *outPtr = &outputBuf[i];
        
        unsigned char grayVal = (unsigned char)((float)inPtr[0] * 0.299f + (float)inPtr[1] * 0.587f + (float)inPtr[2] * 0.114f);
        outPtr[0] = outPtr[1] = outPtr[2] = grayVal;
        outPtr[3] = inPtr[3];   // alpha channel
    }
}

- (unsigned char *)uiImageToRGBABytes:(UIImage *)img {
    // get image information
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(img.CGImage);
    
    const int w = [img size].width;
    const int h = [img size].height;
    
    // create the RGBA data buffer
    unsigned char *rgbaData = new unsigned char[w * h * 4];
    
    // create the CG context
    CGContextRef contextRef = CGBitmapContextCreate(rgbaData,
                                                    w, h,
                                                    8,
                                                    w * 4,
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    if (!contextRef) {
        delete rgbaData;
        
        return NULL;
    }
    
    // draw the image in the context
    CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), img.CGImage);
    
    CGContextRelease(contextRef);

    return rgbaData;
}

- (UIImage *)rgbaBytesToUIImage:(unsigned char *)rgbaData width:(int)w height:(int)h {
    // code from Patrick O'Keefe (http://www.patokeefe.com/archives/721)
    NSData *data = [NSData dataWithBytes:rgbaData length:w * h * 4];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(w,                                  //width
                                        h,                                  //height
                                        8,                                  //bits per component
                                        8 * 4,                              //bits per pixel
                                        w * 4,                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
