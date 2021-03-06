//
//  ViewController.m
//  Myonnaistick
//
//  Created by Moshe on 12/14/14.
//  Copyright (c) 2014 Moshe Berman. All rights reserved.
//

#import "ViewController.h"
#import <MyoKit/MyoKit.h>

#import "JBLineChartView.h"

/**
 *  The event types distinguish the sensors.
 */

typedef NS_ENUM(NSInteger, MYOEventType) {
    MAYOEventTypeOrientation = 0,
    MAYOEventTypeGyro,
    MAYOEventTypeAccelerometer
};

/**
 *  The axes from the various sensors.
 */

typedef NS_ENUM(NSInteger, MYOAxis) {
    MAYOValueTypeX = 0,
    MAYOValueTypeY,
    MAYOValueTypeZ,
    MAYOValueTypeW
};

/**
 *  An arbitrary number of data points. 
 *
 *  Useful because too many data points may hinder performance.
 *
 */

#define kMaxDataPoints 50

@interface ViewController () <JBLineChartViewDataSource, JBLineChartViewDelegate>

/**
 *  The chart views.
 */

@property (weak, nonatomic) IBOutlet JBLineChartView *gyroChartView;
@property (weak, nonatomic) IBOutlet JBLineChartView *accelChartView;
@property (weak, nonatomic) IBOutlet JBLineChartView *orientationChartView;

/**
 *  The legend.
 */

@property (weak, nonatomic) IBOutlet UIView *legend;

/**
 *  The labels
 */

@property (weak, nonatomic) IBOutletCollection(UILabel) NSArray *graphNames;

/**
 *  Store the data somewhere.
 */

@property (nonatomic, strong) NSMutableArray *gyro;
@property (nonatomic, strong) NSMutableArray *accel;
@property (nonatomic, strong) NSMutableArray *orientation;

/**
 *
 */

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    /**
     *  Style the view a little bit.
     */
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.27 green:0.69 blue:0.84 alpha:1.00];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.12 green:0.14 blue:0.17 alpha:1.00];

    self.title = @"MyoChart";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : self.navigationController.navigationBar.tintColor};
    
    /**
     *  Grab all the chart views...
     */
    
    NSArray *chartViews = @[self.gyroChartView, self.accelChartView, self.orientationChartView];
    
    /**
     *  ...iterate them...
     */
    
    for (JBLineChartView *chartView in chartViews) {
        
        /**
         *  ...wire them up...
         */
        
        chartView.dataSource = self;
        chartView.delegate = self;
        
        /**
         *  ...and style them.
         */
        
        chartView.layer.cornerRadius = 8.0f;
        chartView.backgroundColor = [UIColor darkGrayColor];
    }
    
    /**
     *  Style the legend.
     */
    
    self.legend.layer.cornerRadius = 8.0f;
    
    /**
     *  Prep data source.
     */
    self.gyro = [NSMutableArray new];
    self.accel = [NSMutableArray new];
    self.orientation = [NSMutableArray new];

    /**
     *  Register for notifications
     */
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePoseChange:) name:TLMMyoDidReceiveAccelerometerEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePoseChange:) name:TLMMyoDidReceiveGyroscopeEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePoseChange:) name:TLMMyoDidReceiveOrientationEventNotification object:nil];
    
    /**
     *  Refresh the UI.
     */
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(refreshUI) userInfo:nil repeats:YES];
}

- (void)didReceivePoseChange:(NSNotification*)notification {
    
    /**
     *  Grab the events.
     */
    
    TLMGyroscopeEvent *gyroData = notification.userInfo[kTLMKeyGyroscopeEvent];
    TLMAccelerometerEvent *accelData = notification.userInfo[kTLMKeyAccelerometerEvent];
    TLMOrientationEvent *orientationData = notification.userInfo[kTLMKeyOrientationEvent];

    /**
     *  If the data exists, add it to the appopriate data array.
     */
    
    if (gyroData != nil) {
        [self.gyro addObject:gyroData];
        
        if (self.gyro.count > kMaxDataPoints) {
            [self.gyro removeObjectAtIndex:0];
        }
    }
    
    if (accelData != nil) {
        [self.accel addObject:accelData];
        
        if (self.accel.count > kMaxDataPoints) {
            [self.accel removeObjectAtIndex:0];
        }
    }
    
    if (orientationData != nil)
    {
        [self.orientation addObject:orientationData];
        
        if (self.orientation.count > kMaxDataPoints)
        {
            [self.orientation removeObjectAtIndex:0];
        }
    }
    
    /**
     *
     */
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Myo Settings

/** ---
 *  @name Myo Settings
 *  ---
 */

// Presenting modally
- (IBAction)modalPresentMyoSettings:(id)sender
{
    UINavigationController *settings = [TLMSettingsViewController settingsInNavigationController];
    
    [self presentViewController:settings animated:YES completion:nil];
}

#pragma mark - Refresh the UI

/** ---
 *  @name Refresh the UI
 *  ---
 */

- (void)refreshUI {
    
    NSArray *chartViews = @[self.gyroChartView, self.accelChartView, self.orientationChartView];
    
    for (JBLineChartView *chartView in chartViews) {
        [chartView reloadData];
    }
}

#pragma mark - JBChartView


/** ---
 *  @name JBChartView
 *  ---
 */

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView {
    
    return 3; // Not charting 'w.'
    
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex {
    NSArray *dataSetTypes = @[self.orientation, self.gyro, self.accel];
    
    MYOEventType type = [self eventTypeForGraph:lineChartView];
    
    NSUInteger count = ((NSArray *)dataSetTypes[type]).count;
    
    return count;
}


- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    /**
     *  Choose the correct chart.
     */
    
    MYOEventType type = [self eventTypeForGraph:lineChartView];
    
    /**
     *  Drill down into the correct chart.
     */
    
    NSArray *dataSetTypes = @[self.orientation, self.gyro, self.accel];
    NSArray *data = dataSetTypes[type];
    
    NSObject *event = data[horizontalIndex];
    GLKVector3 vector = {0,0,0};
    
    /**
     *  Pull out the correct vector, based on event type.
     *
     *  (Orientation events have a quaternion.)
     */
    
    if ([event isKindOfClass:[TLMOrientationEvent class]])
    {
        TLMOrientationEvent *orientationEvent = (TLMOrientationEvent *)event;
        vector = GLKVector3Make(orientationEvent.quaternion.x, orientationEvent.quaternion.y, orientationEvent.quaternion.z);
    }
    else if ([event isKindOfClass:[TLMAccelerometerEvent class]]){
        TLMAccelerometerEvent *accelEvent = (TLMAccelerometerEvent *)event;
        vector = accelEvent.vector;
    }
    else if ([event isKindOfClass:[TLMGyroscopeEvent class]]) {
        TLMGyroscopeEvent *gyroEvent =  (TLMGyroscopeEvent *)event;
        vector = gyroEvent.vector;
    }
    
    /**
     *  Get a return value from the vector.
     */
    
    CGFloat retVal = 0;
    
    if (lineIndex == MAYOValueTypeX) {
        retVal = vector.x;
    }
    if (lineIndex == MAYOValueTypeY) {
        retVal = vector.y;
    }
    if (lineIndex == MAYOValueTypeZ)
    {
        retVal = vector.z;
    }
    
    return MAX(0,retVal + 1);
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex {
    
    UIColor *color = [UIColor blackColor];
    
    if (lineIndex == MAYOValueTypeX) {
        color = [UIColor blueColor];
    }
    else if(lineIndex == MAYOValueTypeY) {
        color = [UIColor greenColor];
    }
    else if (lineIndex == MAYOValueTypeZ) {
        color = [UIColor redColor];
    }
    
    return  color;
}


- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex {
    return YES;
}

#pragma mark - Index for Chart

/** ---
 *  @name Index for Chart
 *  ---
 */

- (MYOEventType)eventTypeForGraph:(JBLineChartView *)lineChart {
    MYOEventType type = MAYOEventTypeGyro;
    
    if ([lineChart isEqual:self.accelChartView]) {
        type = MAYOEventTypeAccelerometer;
    }
    else if ([lineChart isEqual:self.orientationChartView]) {
        type = MAYOEventTypeOrientation;
    }
    
    return type;
}



@end
