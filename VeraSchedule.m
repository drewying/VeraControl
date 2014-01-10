//
//  VeraSchedule.m
//  Home
//
//  Created by Drew Ingebretsen on 1/5/14.
//  Copyright (c) 2014 PeopleTech. All rights reserved.
//

#import "VeraSchedule.h"

@interface VeraSchedule()
@property (nonatomic, strong) NSString *time;
@property (nonatomic, strong) NSString *interval;
@property (nonatomic, strong) NSMutableIndexSet *daysOfWeek;
@property (nonatomic, strong) NSMutableIndexSet *daysOfMonth;
@end

@implementation VeraSchedule

-(NSMutableIndexSet*)daysOfWeek{
    if (!_daysOfWeek){
        _daysOfWeek = [[NSMutableIndexSet alloc] init];
    }
    return _daysOfWeek;
}

-(NSMutableIndexSet*)daysOfMonth{
    if (!_daysOfMonth){
        _daysOfMonth = [[NSMutableIndexSet alloc] init];
    }
    return _daysOfMonth;
}

-(void)addDayOfMonth:(NSInteger)day{
    if (day < 1 || day > 31){
        return;
    }
    [self.daysOfMonth addIndex:day];
}

-(void)removeDayOfMonth:(NSInteger)day{
    if (day < 1 || day > 31){
        return;
    }
    [self.daysOfMonth removeIndex:day];
}

-(void)addDayOfWeek:(DayOfWeek)day{
    [self.daysOfWeek addIndex:day];
}

-(void)removeDayOfWeek:(DayOfWeek)day{
    [self.daysOfWeek removeIndex:day];
}

-(void)setIntervalMinutes:(NSInteger)minutes{
    self.interval = [NSString stringWithFormat:@"%im",minutes];
}

-(void)setIntervalHours:(NSInteger)hours{
    self.interval = [NSString stringWithFormat:@"%ih",hours];
}

-(void)setScheduleTimeToTime:(NSDate*)time{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    self.time = [formatter stringFromDate:time];
}

-(void)setScheduleTimeToSunset{
    self.time = @"+0:00:0T";
}

-(void)setScheduleTimeToSunrise{
    self.time = @"+0:00:0R";
}

-(NSDictionary*)scheduleDictionary{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"type"] = [NSNumber numberWithInteger:self.scheduleType];
    dictionary[@"enabled"] = @1;
    switch (self.scheduleType) {
        case kVeraScheduleInterval:{
            dictionary[@"interval"] = self.interval;
        }
        case kVeraScheduleWeekly:{
            NSMutableString *dayString = [[NSMutableString alloc] init];
            [self.daysOfWeek enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
                [dayString appendFormat:@"%i,", index];
            }];
            dictionary[@"days_of_week"] = [dayString substringToIndex:dayString.length-2];
            
        }
        case kVeraScheduleMonthly:{
            NSMutableString *dayString = [[NSMutableString alloc] init];
            [self.daysOfMonth enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
                [dayString appendFormat:@"%i,", index];
            }];
            dictionary[@"days_of_month"] = [dayString substringToIndex:dayString.length-2];
        }
        case kVeraScheduleAbsolute:
            break;
        default:
            break;
    }
    dictionary[@"time"] = self.time;
    
    return dictionary;
}

@end
