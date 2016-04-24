//
//  ViewController.m
//  MyLuna
//
//  Created by Froilan Yap on 23/04/2016.
//  Copyright © 2016 Aquinas Solutions. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "ViewController.h"
#import "LunarCalc.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(degrees) ((degrees) / 180.0 * M_PI)

#define AQUA_PEER (8.0f)
#define AQUA_SUPER (20.0f)

static NSString * const kmoonImage = @"moon";
static NSString * const kUpArrowImage = @"upArrow";
static NSString * const knetImage = @"net";
static NSString * const knasa1Image = @"nasa1";
static NSString * const knasa2Image = @"nasa2";

@interface ViewController ()

@property (weak, nonatomic) UIImageView *moonImageView;
@property (weak, nonatomic) UIImageView *upArrow;
@property (weak, nonatomic) UIImageView *downArrow;
@property (weak, nonatomic) UIImageView *leftArrow;
@property (weak, nonatomic) UIImageView *rightArrow;
@property (weak, nonatomic) UIImageView *net;
@property (weak, nonatomic) UIButton *resetButton;
@property (weak, nonatomic) UIImageView *img1;
@property (weak, nonatomic) UIImageView *img2;

@property (readonly, nonatomic) CLLocationManager *locManager;
@property (readonly, nonatomic) CMMotionManager *motionManager;
@property (readonly, nonatomic) LunarCalc *lunarCalc;
@property (weak, nonatomic) IBOutlet UILabel *headingLabel;
@property (strong, readonly, nonatomic) NSOperationQueue *opQueue;
@property (strong, atomic) CLHeading *heading;
@property (atomic) BOOL isUpdatingUI;
@property (atomic) BOOL moonLocked;

@end

/*
<div>Icons made by <a href="http://www.flaticon.com/authors/hanan" title="Hanan">Hanan</a> from <a href="http://www.flaticon.com" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>
*/

@implementation ViewController

@synthesize locManager = _locManager;
@synthesize motionManager = _motionManager;
@synthesize lunarCalc = _lunarCalc;
@synthesize opQueue = _opQueue;

- (NSOperationQueue *)opQueue
{
    if (_opQueue == nil) {
        _opQueue = [[NSOperationQueue alloc] init];
    }
    return _opQueue;
}

- (CLLocationManager *)locManager
{
    if (_locManager == nil) {
        _locManager = [[CLLocationManager alloc] init];
        _locManager.delegate = self;
        [_locManager requestWhenInUseAuthorization];
    }
    
    return _locManager;
}

- (CMMotionManager *)motionManager
{
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
        [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
    }
    return _motionManager;
}

- (LunarCalc *)lunarCalc
{
    if (_lunarCalc == nil) {
        _lunarCalc = [[LunarCalc alloc] init];
    }
    return _lunarCalc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Moon image
    UIImageView *moonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kmoonImage]];
    [self.view addSubview:moonImageView];
    self.moonImageView = moonImageView;
    
    // Build up UI
    [self buildUI];
    
    // Moon's initial position on screen
    [self moonToInitialScreenPosition];
    
    // Set up heading updating
    if ([CLLocationManager headingAvailable]) {
        self.locManager.headingFilter = 0.5; // Update every N degrees of change in heading
        [self.locManager startUpdatingHeading];
    }
    
    // Set up location updating
    if ([CLLocationManager locationServicesEnabled]) {
        self.locManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locManager.distanceFilter = 1;
        [self.locManager startUpdatingLocation];
    }

    // Set up accelerometer to update UI
    self.motionManager.accelerometerUpdateInterval = .2;
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self.opQueue addOperationWithBlock:^{
                                                     [self updateUI];
                                                 }];
                                             }];
    
}

- (void)buildUI
{
    // Up arrow
    UIImageView *upArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kUpArrowImage]];
    upArrow.translatesAutoresizingMaskIntoConstraints = NO;
    upArrow.hidden = YES;
    [self.view addSubview:upArrow];
    self.upArrow = upArrow;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:upArrow attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0f constant:AQUA_SUPER]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:upArrow attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    
    // Down arrow
    UIImageView *downArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kUpArrowImage]];
    downArrow.translatesAutoresizingMaskIntoConstraints = NO;
    downArrow.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    downArrow.hidden = YES;
    [self.view addSubview:downArrow];
    self.downArrow = downArrow;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:downArrow attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0f constant:-AQUA_SUPER]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:downArrow attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];

    // Left arrow
    UIImageView *leftArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kUpArrowImage]];
    leftArrow.translatesAutoresizingMaskIntoConstraints = NO;
    leftArrow.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
    leftArrow.hidden = YES;
    [self.view addSubview:leftArrow];
    self.leftArrow = leftArrow;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leftArrow attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeftMargin multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leftArrow attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];

    // Right arrow
    UIImageView *rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kUpArrowImage]];
    rightArrow.translatesAutoresizingMaskIntoConstraints = NO;
    rightArrow.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
    rightArrow.hidden = YES;
    [self.view addSubview:rightArrow];
    self.rightArrow = rightArrow;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:rightArrow attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRightMargin multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:rightArrow attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    // net
    UIImageView *net = [[UIImageView alloc] initWithImage:[UIImage imageNamed:knetImage]];
    net.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:net];
    self.net = net;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:net attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:30.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:net attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:30.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:net attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:0 attribute:0 multiplier:1.0f constant:120.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:net attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:net attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];
    [self.view sendSubviewToBack:net];

    // data
    UILabel *headingLabel = [[UILabel alloc] init];
    headingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headingLabel.numberOfLines = 0;
    headingLabel.textColor = [UIColor lightGrayColor];
    headingLabel.font = [UIFont systemFontOfSize:12.0f];
    [self.view addSubview:headingLabel];
    self.headingLabel = headingLabel;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.headingLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.headingLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeftMargin multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.headingLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0f constant:0.0f]];
    
    // Reset button
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    resetButton.translatesAutoresizingMaskIntoConstraints = NO;
    [resetButton setTitle:NSLocalizedString(@"Reset", nil) forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(didTapReset:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resetButton];
    self.resetButton = resetButton;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resetButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headingLabel attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resetButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headingLabel attribute:NSLayoutAttributeTop multiplier:1.0f constant:-AQUA_PEER]];
}

- (void)updateUI
{
    if (self.isUpdatingUI || self.moonLocked) return;
    self.isUpdatingUI = YES;
    
    LunarCalc *lc = self.lunarCalc;
    
    lc.observerDateTime = [NSDate date];

    // Test using a fixed date.
//    NSDateComponents *comp = [[NSDateComponents alloc] init];
//    comp.year = 2016;
//    comp.month = 4;
//    comp.day = 23;
//    comp.hour = 20;
//    comp.minute = 0;
//    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
//    gregorian.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"AEST"];
//    lc.observerDateTime = [gregorian dateFromComponents:comp];

    // Calculate lunar position.
    [lc calc];
    
    CMDeviceMotion *motion = self.motionManager.deviceMotion;
    
    CLLocationDirection trueHeading = self.heading.trueHeading;
    
    CGFloat p = RADIANS_TO_DEGREES(motion.attitude.pitch);
//    CGFloat deviceAltitude = motion.gravity.z < 0 ? 90.0f + p : 90.0f - p;
    CGFloat deviceAltitude = motion.gravity.z < 0 ? p - 90.0f : 90.0f - p;
    
    CGFloat hOffset = lc.azimuth - trueHeading;
    CGFloat vOffset = deviceAltitude - lc.altitude;
    
    const CGFloat kArmLengthDistance = 1024 * 2.5; // arm-length distance to device from eye in points
    
    CGFloat deltaX = kArmLengthDistance * tan(DEGREES_TO_RADIANS(hOffset/2)) * 2;
    CGFloat deltaY = kArmLengthDistance * tan(DEGREES_TO_RADIANS(vOffset/2)) * 2;
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    CGPoint newCenter = CGPointMake(center.x + deltaX, center.y + deltaY);
    
    CGRect rect = [self.view convertRect:self.moonImageView.bounds fromView:self.moonImageView];
    if (CGRectContainsPoint(rect, center)) {
        self.moonLocked = YES;
        newCenter = center;
    }

    // Update the UI
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        // Show/hide directional arrows.
        self.upArrow.hidden = (newCenter.y >= 0);
        self.downArrow.hidden = (newCenter.y < CGRectGetMaxY(self.view.bounds));
        self.leftArrow.hidden = (newCenter.x >= 0);
        self.rightArrow.hidden = (newCenter.x < CGRectGetMaxX(self.view.bounds));

        // Move moon
        [UIView animateWithDuration:0.1f animations:^{
            self.moonImageView.center = newCenter;
        } completion:^(BOOL finished) {
            
            // moon locked
            if (self.moonLocked) {
                [UIView animateWithDuration:1.0f animations:^{
                    self.net.layer.opacity = 0.0f;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:1.0f delay:1.0f usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        self.moonImageView.center = CGPointMake(40, 60);
                    } completion:^(BOOL finished) {
                        [self showMoonInfo];
                    }];
                    
                    [UIView animateWithDuration:1.0f delay:0.5f options:UIViewAnimationOptionCurveLinear animations:^{
                        self.view.backgroundColor = [UIColor blackColor];
                    } completion:^(BOOL finished) {
                    }];
                }];
            }
        }];
        
        self.headingLabel.text = [NSString stringWithFormat:
                                  @" Lat/Long: %.4f/%.4f\n Local time: %@ \n UTC time: %@ \n True heading: %.2f\n Alt: %.2f\n Az: %.2f\n Attitude: %@\n Tilt: %@\n Upright pitch: %.1f\n Offset (Az,Alt): %.1f, %.1f\n Moon center: %.1f,%.1f\n Delta: %@",
                                  
                                  self.lunarCalc.latitude,self.lunarCalc.longitude,
                                  self.lunarCalc.observerLocalDateTimeString,
                                  self.lunarCalc.observerUTCDateTimeString,
                                  trueHeading,
                                  lc.altitude,
                                  lc.azimuth,
                                  [NSString stringWithFormat:@"P %.1f R %.1f Y %.1f",
                                   RADIANS_TO_DEGREES(motion.attitude.pitch),
                                   RADIANS_TO_DEGREES(motion.attitude.roll),
                                   RADIANS_TO_DEGREES(motion.attitude.yaw)],
                                  motion.gravity.z > 0 ? @"fwd" : @"bwd",
                                  deviceAltitude,
                                  hOffset,
                                  vOffset,
                                  newCenter.x, newCenter.y,
                                  [NSString stringWithFormat:@"%.0f,%.0f", deltaX, deltaY]
                                  ];
        
        self.isUpdatingUI = NO;
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    self.heading = newHeading;
    [self.opQueue addOperationWithBlock:^{
        [self updateUI];
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *latestLoc = (CLLocation *)[locations lastObject];
    if (latestLoc) {
        self.lunarCalc.latitude = latestLoc.coordinate.latitude;
        self.lunarCalc.longitude = latestLoc.coordinate.longitude;
        [self.opQueue addOperationWithBlock:^{
            [self updateUI];
        }];
    }
}

- (IBAction)didTapReset:(id)sender
{
    self.moonLocked = NO;
    [self moonToInitialScreenPosition];
    self.net.layer.opacity = 1.0f;
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.img1) {
        self.img1.hidden = YES;
    }
    if (self.img2) {
        self.img2.hidden = YES;
    }
}

- (void)moonToInitialScreenPosition
{
    self.moonImageView.frame = CGRectMake(-100, -100, 60, 60);
}

- (void)showMoonInfo
{
    if (self.img1 == nil) {
        UIImageView *img1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:knasa1Image]];
        img1.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:img1];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:img1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.moonImageView attribute:NSLayoutAttributeRight multiplier:1.0f constant:50.0f]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:img1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.moonImageView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
        self.img1 = img1;
        
        UIImageView *img2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:knasa2Image]];
        img2.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:img2];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:img2 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.moonImageView attribute:NSLayoutAttributeRight multiplier:1.0f constant:50.0f]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:img2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:img1 attribute:NSLayoutAttributeBottom multiplier:1.0f constant:30.0f]];
        self.img2 = img2;
    } else {
        self.img1.hidden = NO;
        self.img2.hidden = NO;
    }
}

@end
