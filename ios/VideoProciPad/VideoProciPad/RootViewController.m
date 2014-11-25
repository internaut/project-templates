#import "RootViewController.h"

/**
 * Small helper function to convert a fourCC <code> to
 * a character string <fourCC> for printf and the like
 */
void fourCCStringFromCode(int code, char fourCC[5]) {
    for (int i = 0; i < 4; i++) {
        fourCC[3 - i] = code >> (i * 8);
    }
    fourCC[4] = '\0';
}

@interface RootViewController(Private)
/**
 * initialize camera
 */
- (void)initCam;

/**
 * Notify the video session about the interface orientation change
 */
- (void)interfaceOrientationChanged:(UIInterfaceOrientation)o;

/**
 * handler that is called when a output selection button is pressed
 */
- (void)procOutputSelectBtnAction:(UIButton *)sender;

/**
 * force to redraw views. this method is only to display the intermediate
 * frame processing output for debugging
 */
- (void)updateViews;

- (void)prepareForFramesOfSize:(CGSize)size;

- (void)setCorrectedFrameForViews:(NSValue *)newFrameRect;

/**
 * Convert a sample buffer <buf> from the camera (YUV 4:2:0 [NV12] pixel format) to a
 * data buffer <grayData> that will contain only the luminance (grayscale) data
 * See http://www.fourcc.org/yuv.php#NV12 and https://wiki.videolan.org/YUV/#NV12.2FNV21
 * for details about the pixel format
 * If <grayData> points to NULL, the pixel buffer will be created first.
 * Return the sample buffer frame size.
 */
- (CGSize)convertYUVSampleBuffer:(CMSampleBufferRef)buf toGrayscaleData:(unsigned char **)grayData;

/**
 * Convert grayscale pixel values in <grayData> to an UIImage.
 */
- (UIImage *)uiImageFromGrayscaleData:(unsigned char *)grayData size:(CGSize)imgSize;

@end


@implementation RootViewController


#pragma mark init/dealloc

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        curFrame = NULL;
        showCamPreview = YES;
        firstFrame = YES;
    }
    
    return self;
}

- (void)dealloc {
    // release camera stuff
    [vidDataOutput release];
    [camDeviceInput release];
    [camSession release];
    
    // release views
    [camView release];
    [procFrameView release];
    [baseView release];
    
    [super dealloc];
}

#pragma mark parent methods

- (void)didReceiveMemoryWarning {
    NSLog(@"memory warning!!!");
    
    [super didReceiveMemoryWarning];
}

- (void)loadView {
    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    NSLog(@"loading view of size %dx%d", (int)screenRect.size.width, (int)screenRect.size.height);
    
    // create an empty base view
    CGRect baseFrame = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width);
    baseView = [[UIView alloc] initWithFrame:baseFrame];
    
    // create the image view for the camera frames
    camView = [[CamView alloc] initWithFrame:baseFrame];
    [baseView addSubview:camView];
    
    // create view for processed frames
    procFrameView = [[UIImageView alloc] initWithFrame:baseFrame];
    [procFrameView setHidden:YES];  // initially hidden
    [baseView addSubview:procFrameView];
    
    // set a list of buttons for processing output display
    NSArray *btnTitles = [NSArray arrayWithObjects:
                          @"Normal",
                          @"Processed",
                          nil];
    for (int btnIdx = 0; btnIdx < btnTitles.count; btnIdx++) {
        UIButton *procOutputSelectBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [procOutputSelectBtn setTag:btnIdx - 1];
        [procOutputSelectBtn setTitle:[btnTitles objectAtIndex:btnIdx]
                             forState:UIControlStateNormal];
        int btnW = 120;
        [procOutputSelectBtn setFrame:CGRectMake(10 + (btnW + 20) * btnIdx, 10, btnW, 35)];
        [procOutputSelectBtn setOpaque:YES];
        [procOutputSelectBtn addTarget:self
                                action:@selector(procOutputSelectBtnAction:)
                      forControlEvents:UIControlEventTouchUpInside];
        
        [baseView addSubview:procOutputSelectBtn];
    }
    
    // finally set the base view as view for this controller
    [self setView:baseView];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"view will appear - start camera session");
    
    [camSession startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"view did disappear - stop camera session");
    
    [camSession stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up camera
    [self initCam];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o duration:(NSTimeInterval)duration {
    [self interfaceOrientationChanged:o];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // note that this method does *not* run in the main thread!
    if (!showCamPreview) {
        frameSize = [self convertYUVSampleBuffer:sampleBuffer toGrayscaleData:&curFrame];
        
        if (firstFrame) {
            [self prepareForFramesOfSize:frameSize];
            firstFrame = NO;
        }
        
        [self performSelectorOnMainThread:@selector(updateViews)
                               withObject:nil
                            waitUntilDone:NO];
    }
}

#pragma mark private methods

- (void)updateViews {
    // this method is only to display the intermediate frame processing
    // output of the detector.
    // (it is slow but it's only for debugging)
    
    // when we have a frame to display in "procFrameView" ...
    // ... convert it to an UIImage
    UIImage *dispUIImage = [self uiImageFromGrayscaleData:curFrame size:frameSize];
        
    // and display it with the UIImageView "procFrameView"
    [procFrameView setImage:dispUIImage];
    [procFrameView setNeedsDisplay];
}

- (void)initCam {
    NSLog(@"initializing cam");
    
    NSError *error = nil;
    
    // set up the camera capture session
    camSession = [[AVCaptureSession alloc] init];
    [camSession setSessionPreset:CAM_SESSION_PRESET];
    [camView setSession:camSession];
    
    // get the camera device
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    assert(devices.count > 0);
    
	AVCaptureDevice *camDevice = [devices firstObject];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == CAM_POSITION) {
			camDevice = device;
			break;
		}
	}
    
    camDeviceInput = [[AVCaptureDeviceInput deviceInputWithDevice:camDevice error:&error] retain];
    
    if (error) {
        NSLog(@"error getting camera device: %@", error);
        return;
    }
    
    assert(camDeviceInput);
    
    // add the camera device to the session
    if ([camSession canAddInput:camDeviceInput]) {
        [camSession addInput:camDeviceInput];
        [self interfaceOrientationChanged:self.interfaceOrientation];
    }
    
    // create camera output
    vidDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [camSession addOutput:vidDataOutput];
    
    // set output delegate to self
    dispatch_queue_t queue = dispatch_queue_create("vid_output_queue", NULL);
    [vidDataOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // get best output video format
    NSArray *outputPixelFormats = vidDataOutput.availableVideoCVPixelFormatTypes;
    int bestPixelFormatCode = -1;
    for (NSNumber *format in outputPixelFormats) {
        int code = [format intValue];
        if (bestPixelFormatCode == -1) bestPixelFormatCode = code;  // choose the first as best
        char fourCC[5];
        fourCCStringFromCode(code, fourCC);
        NSLog(@"available video output format: %s (code %d)", fourCC, code);
    }

    // specify output video format
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:bestPixelFormatCode]
                                                               forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [vidDataOutput setVideoSettings:outputSettings];
    
//    // cap to 15 fps
//    [vidDataOutput setMinFrameDuration:CMTimeMake(1, 15)];
}

- (void)procOutputSelectBtnAction:(UIButton *)sender {
    NSLog(@"proc output selection button pressed: %@ (proc type %ld)",
          [sender titleForState:UIControlStateNormal], (long)sender.tag);
    
    showCamPreview = (sender.tag < 0);
    [camView setHidden:!showCamPreview];       // only show original camera frames in "normal" display mode
    [procFrameView setHidden:showCamPreview];  // only show processed frames for other than "normal" display mode
}

- (void)interfaceOrientationChanged:(UIInterfaceOrientation)o {
    [[(AVCaptureVideoPreviewLayer *)camView.layer connection] setVideoOrientation:(AVCaptureVideoOrientation)o];
}

- (void)prepareForFramesOfSize:(CGSize)size {
    // WARNING: this method will not be called from the main thead!
    
    float frameAspectRatio = size.width / size.height;
    NSLog(@"camera frames are of size %dx%d (aspect %f)", (int)size.width, (int)size.height, frameAspectRatio);
    
    // update proc frame view size
    float newViewH = procFrameView.frame.size.width / frameAspectRatio;   // calc new height
    float viewYOff = (procFrameView.frame.size.height - newViewH) / 2;
    
    CGRect correctedViewRect = CGRectMake(0, viewYOff, procFrameView.frame.size.width, newViewH);
    [self performSelectorOnMainThread:@selector(setCorrectedFrameForViews:)         // we need to execute this on the main thead
                           withObject:[NSValue valueWithCGRect:correctedViewRect]   // otherwise it will have no effect
                        waitUntilDone:NO];
}

- (void)setCorrectedFrameForViews:(NSValue *)newFrameRect {
    // WARNING: this *must* be executed on the main thread
    
    // set the corrected frame for the proc frame view
    CGRect r = [newFrameRect CGRectValue];
    [procFrameView setFrame:r];
}

- (CGSize)convertYUVSampleBuffer:(CMSampleBufferRef)buf toGrayscaleData:(unsigned char **)grayData {
    CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(buf);
    
    // lock the buffer
    CVPixelBufferLockBaseAddress(imgBuf, 0);
    
    // get the address to the image data
    //    void *imgBufAddr = CVPixelBufferGetBaseAddress(imgBuf);   // this is wrong! see http://stackoverflow.com/a/4109153
    void *imgBufAddr = CVPixelBufferGetBaseAddressOfPlane(imgBuf, 0);
    
    // get image properties
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);
    
    if (*grayData == NULL) {    // if grayData points to NULL, create the empty buffer first
        *grayData = malloc(sizeof(unsigned char) * w * h);
    }
    
    memcpy(*grayData, imgBufAddr, w * h);    // the first plane contains the grayscale data
    // therefore we use <imgBufAddr> as source
    
    // unlock again
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);
    
    return CGSizeMake(w, h);
}

- (UIImage *)uiImageFromGrayscaleData:(unsigned char *)grayData size:(CGSize)imgSize {
    // code from Patrick O'Keefe (http://www.patokeefe.com/archives/721)
    NSData *data = [NSData dataWithBytes:grayData length:imgSize.width * imgSize.height];
    
    CGColorSpaceRef colorSpace;
    
    colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(imgSize.width,                              //width
                                        imgSize.height,                             //height
                                        8,                                          //bits per component
                                        8,                                          //bits per pixel
                                        imgSize.width,                              //bytesPerRow
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
