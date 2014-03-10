#import "MainViewController.h"

//File name for the Haar Cascade XML file
static const char *HAAR_RESOURCE = "haarcascade_frontalface_alt_tree.xml";
static const char *HAAR_RESOURCE_NOSE = "haarcascade_nose.xml";

static CvMemStorage *cvStorage = NULL;

static CvHaarClassifierCascade *haarCascade = NULL;
static CvHaarClassifierCascade *haarCascadeNose = NULL;

@interface MainViewController ()

@end

@implementation MainViewController
@synthesize originalImageView;

#pragma mark UIImage to IplImage
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    CGSize imgViewSize = CGSizeMake(originalImageView.frame.size.width, originalImageView.frame.size.height);
    
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    
    IplImage *iplimage = cvCreateImage(
                       cvSize(imgViewSize.width,imgViewSize.height), IPL_DEPTH_8U, 4
                       );
    
    
    CGContextRef contextRef = CGBitmapContextCreate(
                        iplimage->imageData, iplimage->width, iplimage->height,
                        iplimage->depth, iplimage->widthStep,
                        colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                        );
    
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

-(void) drawOnFaceAt:(CvRect *)rect inImage:(IplImage *)image color:(CvScalar)colorScalar
{
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
    
    CvSeq* faces = cvHaarDetectObjects(src,
                                       haarCascade,
                                       cvStorage,
                                       1.1,
                                       2,
                                       CV_HAAR_DO_CANNY_PRUNING,
                                       cvSize(100, 100));
    
    //Detect Faces and get rectangular coordinates
    CvSeq* noses = cvHaarDetectObjects(src,
                                       haarCascadeNose,
                                       cvStorage,
                                       1.1,
                                       2,
                                       CV_HAAR_DO_CANNY_PRUNING,
                                       cvSize(10, 10),
                                       cvSize(50, 50));
    
    
    for (int i=0; i<faces->total; i++) {

        CvRect *rect = (CvRect *)cvGetSeqElem(faces, i);
        [self drawOnFaceAt:rect inImage:src color:cvScalar(255,0,0,255)];
        
        // Draw noses found in face
        for (int i=0; i<noses->total; i++) {
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
    [originalImageView setImage:newImage];
}


#pragma mark App General

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    baseImage=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"p4" ofType:@"jpg"]];
    [originalImageView setImage:baseImage];
    
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
