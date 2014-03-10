//
//  OCFourthViewController.m
//  OpenCVBasics
//
//  Created by Mohit Athwani on 20/10/11.
//  Copyright (c) 2011 Geeks Incorporated. All rights reserved.
//

#import "MainViewController.h"
//File name for the Haar Cascade XML file
static const char *HAAR_RESOURCE = "haarcascade_frontalface_alt_tree.xml";
static const char *HAAR_RESOURCE_NOSE = "haarcascade_nose.xml";

//Temporary storage for the Haar resource
static CvMemStorage *cvStorage = NULL;

//Pointer to the Resource
static CvHaarClassifierCascade *haarCascade = NULL;
static CvHaarClassifierCascade *haarCascadeNose = NULL;


@implementation MainViewController
@synthesize originalImageView;

#pragma mark UIImage to IplImage
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    CGSize imgViewSize = CGSizeMake(originalImageView.frame.size.width, originalImageView.frame.size.height);
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(imgViewSize.width,imgViewSize.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, imgViewSize.width, imgViewSize.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
 
    return iplimage;
}

#pragma mark Iplimage to UIImage
//Convert Image to RGB before calling this
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef)data);
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}

#pragma mark Face detection
-(void) drawOnFaceAt:(CvRect *)rect inImage:(IplImage *)image color:(CvScalar)colorScalar{
    
    //We need points to draw a rectangle
    cvRectangle(image, cvPoint(rect->x, rect->y), cvPoint(rect->x+rect->width, rect->y+rect->height), colorScalar,4,8,0);
}

-(CGRect)CGRectFromCvRectForFootbal:(CvRect*)rect
{
    return CGRectMake(rect->x, rect->y, rect->width , rect->height);
}

-(void)addFootbalOnNose:(CvRect*)rect
{
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"football_PNG1085.png"]];
    [iv setFrame:[self CGRectFromCvRectForFootbal:rect]];
    [originalImageView addSubview:iv];
}

-(BOOL)isPointInRect:(CvRect*)rect point:(CvPoint)point
{
    if(point.x < rect->x)
        return false;
    if(point.x > (rect->x + rect->width))
        return false;
    if(point.y < rect->y)
        return false;
    if(point.y > (rect->y + rect->height))
        return false;
    return true;
}

-(CvPoint)getCenterFromRect:(CvRect*)rect
{
    return cvPoint(rect->x + rect->width/2,rect->y + rect->height/2);
}

-(void) detectFaces {
    IplImage *src = [self CreateIplImageFromUIImage:[originalImageView image]];
    
    // Face detection logic comes here
    //Clear the memory incase previous faces were detected
    cvClearMemStorage(cvStorage);
    
    //Detect Faces and get rectangular coordinates
    CvSeq* faces = cvHaarDetectObjects(src, //Input Image
                                       haarCascade, // Cascade to be used
                                       cvStorage, //Temporary storage
                                       1.1,// Size increase for features at each scan
                                       2, //Min number of neighbouring rectangle matches
                                       CV_HAAR_DO_CANNY_PRUNING,//Optimization
                                       cvSize(100, 100)); // Starting feature size
    
    //Detect Faces and get rectangular coordinates
    CvSeq* noses = cvHaarDetectObjects(src, //Input Image
                                       haarCascadeNose, // Cascade to be used
                                       cvStorage, //Temporary storage
                                       1.1,// Size increase for features at each scan
                                       2, //Min number of neighbouring rectangle matches
                                       CV_HAAR_DO_CANNY_PRUNING,//Optimization
                                       cvSize(10, 10), // Starting feature size
                                       cvSize(50, 50)); // max feature size
    
    //CvSeq is a linked list with tree feeatures. "faces" is a list of bounding rectangles for each face
    
    for (int i=0; i<faces->total; i++) {
        //cvGetSeqElem is used for random access to CvSeqs
        CvRect *rect = (CvRect *)cvGetSeqElem(faces, i);
        [self drawOnFaceAt:rect inImage:src color:cvScalar(255,0,0,255)];
        
        for (int i=0; i<noses->total; i++) {
            //cvGetSeqElem is used for random access to CvSeqs
            CvRect *rectNose = (CvRect *)cvGetSeqElem(noses, i);
            CvPoint noseCenter = [self getCenterFromRect:rectNose];
            if([self isPointInRect:rect point:noseCenter]){
                [self drawOnFaceAt:rectNose inImage:src color:cvScalar(0,255,0,255)];
                [self addFootbalOnNose:rectNose];
                break;
            }
        }
    }
    
    
    
    UIImage *newImage = [self UIImageFromIplImage:src];
    cvReleaseImage(&src);
    //cvCvtColor(newImage, newImage, CV_HSV2RGB);
    [originalImageView setImage:newImage];
}


#pragma mark App Stuff
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Face Detection", @"Face Detection");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    baseImage=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"p4" ofType:@"jpg"]];
    [originalImageView setImage:baseImage];
    
    //Parsing the XML file
    cvStorage = cvCreateMemStorage(0);
    NSString *resourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithUTF8String:HAAR_RESOURCE]];
    NSString *resourcePathNose = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithUTF8String:HAAR_RESOURCE_NOSE]];
    
    haarCascade = (CvHaarClassifierCascade *)cvLoad([resourcePath UTF8String],0,0,0);
    haarCascadeNose = (CvHaarClassifierCascade *)cvLoad([resourcePathNose UTF8String],0,0,0);
    
    [self detectFaces];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

@end
