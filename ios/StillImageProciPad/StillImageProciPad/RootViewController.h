/**
 * RootViewController -- main application logic
 */

#import <UIKit/UIKit.h>

/**
 * Main application logic: Initialize application, set up the view and handle user input.
 */
@interface RootViewController : UIViewController {
    UIView *baseView;       // view fundament on which all other views are added
    UIImageView *imgView;   // image view for example images and GPGPU process output images
    
    int selectedTestImg;    // currently selected test image
    BOOL displayingOutput;  // is true if the image processing output is displayed
    
    UIImage *testImg;           // current test image
    unsigned char *testImgData; // current test image RGBA data
    int testImgW;   // test image width
    int testImgH;   // test image height

    UIImage *outputImg;         // current output image
    unsigned char *outputBuf;   // current output image RGBA data
}

@end
