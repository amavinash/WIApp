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
        NSSet *writeDataTypes = [self dataTypesToWrite];
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
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
    HKQuantityType *waterConsumption = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    return [NSSet setWithObjects:weightType, birthdayType, biologicalSexType,stepCount,waterConsumption, nil];
}
// Returns the types of data that Fit wishes to write to HealthKit.
- (NSSet *)dataTypesToWrite
{
    HKQuantityType *waterConsumption = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    return [NSSet setWithObjects:waterConsumption, nil];
}


-(void)addWaterIntake
{
    HKUnit *liters = [HKUnit literUnit];
    HKQuantity *waterQuantity = [HKQuantity quantityWithUnit:liters doubleValue:1.0];
    HKQuantityType *waterConsumption = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    NSDate *now = [NSDate date];
    HKQuantitySample *waterSample = [HKQuantitySample quantitySampleWithType:waterConsumption quantity:waterQuantity startDate:now endDate:now];
    [self.healthStore saveObject:waterSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the height sample %@. In your app, try to handle this gracefully. The error was: %@.", waterSample, error);
            abort();
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stepCountLabel.text = [NSString stringWithFormat:@"You Drank %d litres of water today!",1];
        });
    }];
}

-(void)updateUsersStepCount
{

    NSDate *startDate, *endDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    HKQuantityType *stepCount = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    startDate = [calendar dateBySettingHour:0  minute:0  second:0  ofDate:now options:0];
    endDate   = [calendar dateBySettingHour:23 minute:59 second:59 ofDate:now options:0];
    NSPredicate *today = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    HKStatisticsOptions sumOptions = HKStatisticsOptionCumulativeSum;
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc]initWithQuantityType:stepCount
                                                      quantitySamplePredicate:today
                                                                      options:sumOptions
                                                            completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                                                HKQuantity *sum = [result sumQuantity];
                                                                NSLog(@"Steps: %lf",[sum doubleValueForUnit:[HKUnit countUnit]]);
                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                    self.stepCountLabel.text = [NSNumberFormatter localizedStringFromNumber:@([sum doubleValueForUnit:[HKUnit countUnit]]) numberStyle:NSNumberFormatterNoStyle];
                                                                });
                                                            }];
    [self.healthStore executeQuery:query];
    
}

-(void)mostRecentDataOfType:(HKQuantityType*)dataType withCompletion:(void(^)(HKQuantity *mostRecentQuantity, NSError *error))completion
{
    NSDate *startDate, *endDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    startDate = [calendar dateBySettingHour:0  minute:0  second:0  ofDate:now options:0];
    endDate   = [calendar dateBySettingHour:23 minute:59 second:59 ofDate:now options:0];
    NSPredicate *today = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:dataType
                                                           predicate:today
                                                               limit:100
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

- (IBAction)addWaterConsumption:(id)sender {
    [self addWaterIntake];
}
@end
