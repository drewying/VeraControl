//
//  VeraSchedule.h
//  Home
//
//  Created by Drew Ingebretsen on 1/5/14.
//  Copyright (c) 2014 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    kVeraScheduleInterval = 1,
    kVeraScheduleWeekly = 2,
    kVeraScheduleMonthly = 3,
    kVeraScheduleAbsolute = 4
}VeraScheduleType;

typedef enum{
    kDayOfWeekSunday = 0,
    kDayOfWeekMonday,
    kDayOfWeekTuesday,
    kDayOfWeekWednesday,
    kDayOfWeekThursday,
    kDayOfWeekFriday,
    kDayOfWeekSaturday
}DayOfWeek;


@interface VeraSchedule : NSObject

@property (nonatomic, assign) VeraScheduleType scheduleType;

-(void)addDayOfMonth:(NSInteger)day;
-(void)removeDayOfMonth:(NSInteger)day;
-(void)addDayOfWeek:(DayOfWeek)day;
-(void)removeDayOfWeek:(DayOfWeek)day;
-(void)setIntervalMinutes:(NSInteger)minutes;
-(void)setIntervalHours:(NSInteger)hours;
-(void)setScheduleTimeToTime:(NSDate*)time;
-(void)setScheduleTimeToSunset;
-(void)setScheduleTimeToSunrise;
-(NSDictionary*)scheduleDictionary;

@end
