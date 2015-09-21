//
//  ViewController.h
//  WIApp
//
//  Created by admin on 9/12/15.
//  Copyright © 2015 infy. All rights reserved.
//

#import <UIKit/UIKit.h>

@import HealthKit;

@interface RootViewController : UIViewController

@property (nonatomic) HKHealthStore *healthStore;
- (IBAction)addWaterConsumption:(id)sender;

@end

