//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveLock.h"

#define UPNP_SERVICE_DOOR_LOCK @"urn:micasaverde-com:serviceId:DoorLock1"

@implementation ZwaveLock

-(ZwaveLock*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self){
        for (NSDictionary *serviceDictionary in dictionary[@"states"]){
            NSString *service = serviceDictionary[@"service"];
            NSString *variable = serviceDictionary[@"variable"];
            if ([service isEqualToString:UPNP_SERVICE_DOOR_LOCK] && [variable isEqualToString:@"Status"]){
                self.locked = [serviceDictionary[@"value"] integerValue];
            }
            if ([service isEqualToString:UPNP_SERVICE_DOOR_LOCK] && [variable isEqualToString:@"PinCodes"]){
                self.pinCodes = @[];
                NSString *pinCodeString = serviceDictionary[@"value"];
                pinCodeString = [pinCodeString substringFromIndex:[pinCodeString rangeOfString:@"1"].location];
                
                NSArray *codes = [pinCodeString componentsSeparatedByString:@";\t"];
                for (NSString *codeString in codes){
                    ZwaveLockPinCode *pinCode = [[ZwaveLockPinCode alloc] init];
                    NSArray *array = [codeString componentsSeparatedByString:@";"];
                    if (array.count>1){
                        NSString *timeString = [array lastObject];
                        NSArray *timeArray = [timeString componentsSeparatedByString:@","];
                        pinCode.startingValidDate = [NSDate dateWithTimeIntervalSince1970:[[timeArray objectAtIndex:timeArray.count-2] integerValue]];
                        pinCode.endingValidDate = [NSDate dateWithTimeIntervalSince1970:[[timeArray objectAtIndex:timeArray.count-1] integerValue]];
                    }
                    
                    NSString *formattedString = [[array firstObject] stringByReplacingOccurrencesOfString:@" " withString:@""];
                    if (formattedString.length > 6){
                        pinCode.name = [[formattedString componentsSeparatedByString:@","] lastObject];
                        pinCode.pinIndex = [[[formattedString componentsSeparatedByString:@","] firstObject] integerValue];
                        self.pinCodes = [self.pinCodes arrayByAddingObject:pinCode];
                    }
                }
            }
        }
    }
    return self;
}

-(void)setLocked:(BOOL)locked completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(locked == YES)] usingService:UPNP_SERVICE_DOOR_LOCK completion:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback();
        }
    }];
}

//<VERSION=3>73	1,1,2013-08-12 23:30:56,2013-10-07 11:42:07,****,Drew;	2,1,,2013-12-18 21:32:25,****,Master;	3,1,2013-09-03 23:23:28,,****,Shanon;	4,0;	5,1,2013-11-15 23:10:54,2013-12-18 19:08:52,****,Arm;	6,1,2013-12-10 21:47:57,,****,Rex;	7,0;	8,0;	9,0;	10,0;	11,0;	12,0;	13,0;	14,0;	15,0;	16,0;	17,0;	18,0;	19,0;

//http://192.168.81.1:3480/data_request?id=action&DeviceNum=6&serviceId=urn:micasaverde-com:serviceId:DoorLock1&action=SetPinValidityDate&UserCode=1&StartDate=2012-09-03%2014:00:00&StopDate=2012-09-03%2015:00:00&Replace=1

-(void)createPin:(NSString*)pin withName:(NSString*)name completion:(void(^)())callback{
    NSInteger lastIndex = [[[self.pinCodes lastObject] valueForKey:@"pinIndex"] integerValue];
    
    NSLog(@"%@",[NSString stringWithFormat:@"SetPin&UserCodeName=%@&newPin=%@&user=%@", [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pin, [NSString stringWithFormat:@"%i", lastIndex+1]]);
    
    /*
     [self performAction:[NSString stringWithFormat:@"SetPin&UserCodeName=%@&newPin=%@&user=%@", [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pin, [NSString stringWithFormat:@"%i", lastIndex+1]] usingService:UPNP_SERVICE_DOOR_LOCK completion:^(NSURLResponse *response, NSData *data, NSError *error){
     NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
     if (callback){
     callback();
     }
     }];
     */
    
    [self performAction:[NSString stringWithFormat:@"SetPin&UserCodeName=%@&newPin=%@", [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pin] usingService:UPNP_SERVICE_DOOR_LOCK completion:^(NSURLResponse *response, NSData *data, NSError *error){
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (callback){
            callback();
        }
    }];
}

-(void)deletePin:(NSInteger)pinIndex completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"ClearPin&UserCode=%i", pinIndex] usingService:UPNP_SERVICE_DOOR_LOCK completion:^(NSURLResponse *response, NSData *data, NSError *error){
        NSMutableArray *array = [self.pinCodes mutableCopy];
        ZwaveLockPinCode *pinCode;
        for (ZwaveLockPinCode *code in self.pinCodes){
            if (code.pinIndex == pinIndex){
                pinCode = code;
                break;
            }
        }
        
        [array removeObject:pinCode];
        self.pinCodes = array;
        
        if (callback){
            callback();
        }
    }];
}

-(void)setPinValidity:(NSInteger)pinIndex fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate completion:(void(^)())callback{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //2012-09-03 15:00:00
    //2013-12-19 02:34:34
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *url = [NSString stringWithFormat:@"SetPinValidityDate&UserCode=%@&StartDate=%@&StopDate=%@&Replace=1",[NSString stringWithFormat:@"%i",pinIndex], [[dateFormatter stringFromDate:fromDate] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] , [[dateFormatter stringFromDate:toDate] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [self performAction:url usingService:UPNP_SERVICE_DOOR_LOCK completion:^(NSURLResponse *response, NSData *data, NSError *error){
        NSLog(@"Response:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (callback){
            callback();
        }
    }];
}

@end

@implementation ZwaveLockPinCode

@end