//
//  ViewController.m
//  WIApp
//
//  Created by admin on 9/12/15.
//  Copyright © 2015 infy. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stepCountLabel;

@end

@implementation RootViewController

@synthesize healthStore;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([HKHealthStore isHealthDataAvailable])
    {
        NSSet *readDataTypes = [self dataTypesToRead];
        [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success)
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"You are running this app on iPad. Go get an iPhone" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                return ;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                //Update the main User Interface here
                [self updateUsersStepCount];
            });
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)dataTypesToRead
{
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    HKCharacteristicType *biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
    HKQuantityType *stepCount = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    return [NSSet setWithObjects:weightType, birthdayType, biologicalSexType,stepCount, nil];
}

-(void)updateUsersStepCount
{
//    NSLengthFormatter *lengthFormatter = [[NSLengthFormatter alloc] init];
//    lengthFormatter.unitStyle = NSFormattingUnitStyleLong;
//    NSLengthFormatterUnit distanceFormatterUnit = NSLengthFormatterUnitMile;
    
    HKQuantityType *stepCount = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [self mostRecentDataOfType:stepCount withCompletion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        int stepCounter = 0;
        if (mostRecentQuantity!=nil) {
            stepCounter = [mostRecentQuantity doubleValueForUnit:[HKUnit countUnit]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stepCountLabel.text = [NSNumberFormatter localizedStringFromNumber:@(stepCounter) numberStyle:NSNumberFormatterNoStyle];
        });
    }];
    
}

-(void)mostRecentDataOfType:(HKQuantityType*)dataType withCompletion:(void(^)(HKQuantity *mostRecentQuantity, NSError *error))completion
{
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:dataType
                                                           predicate:nil
                                                               limit:1
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
    {
        if([results count]!=0)
        {
            HKQuantitySample *quantitySample = [results firstObject];
            HKQuantity *quantity = [quantitySample quantity];
            if(completion)
                completion(quantity,error);
            else
                completion(nil,error);
        }
            
    }];
    [self.healthStore executeQuery:query];
    
}

@end
