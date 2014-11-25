#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "CamView.h"

// Camera parameters

#define CAM_SESSION_PRESET  AVCaptureSessionPresetHigh
#define CAM_POSITION        AVCaptureDevicePositionBack

/**
 * Main view controller.
 * Handles UI initialization and interactions. Handles camera frame input.
 */
@interface RootViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession *camSession;               // controlls the camera session
    AVCaptureDeviceInput *camDeviceInput;       // input device: camera
    AVCaptureVideoDataOutput *vidDataOutput;    // controlls the video output

    BOOL showCamPreview;
    BOOL firstFrame;
    
    unsigned char *curFrame;            // currently grabbed camera frame (grayscale)
    CGSize frameSize;                   // currently grabbed camera frame size
    
    UIView *baseView;           // root view
    UIImageView *procFrameView; // view for processed frames
    CamView *camView;           // shows the grabbed video frames ("camera preview")
}

@end
