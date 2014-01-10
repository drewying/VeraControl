//
//  VeraSceneTrigger.m
//  Home
//
//  Created by Drew Ingebretsen on 12/19/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "VeraSceneTrigger.h"

@implementation VeraSceneTrigger



-(VeraSceneTrigger*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super init];
    if (self){
        self.triggerDevice = dictionary[@"device"];
        self.triggerEnabled = [NSNumber numberWithInteger:[dictionary[@"enabled"] integerValue]];
        self.triggerLastRun = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"last_run"] integerValue]];
        self.triggerName = dictionary[@"name"];
        self.triggerTemplate = dictionary[@"template"];
        
        self.triggerArguments = @[];
        for (NSDictionary *argumentDictionary in dictionary[@"arguments"]){
            VeraSceneTriggerArgument *argument = [[VeraSceneTriggerArgument alloc] init];
            argument.argumentValue = argumentDictionary[@"value"];
            argument.argumentIdentifier = argumentDictionary[@"id"];
        }
    }
    return self;
}

-(NSDictionary*)triggerDictionary{
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    VeraSceneTriggerArgument *arg = [self.triggerArguments firstObject];
    //for (VeraSceneTriggerArgument *arg in self.triggerArguments){
    [arguments addObject:@{@"id":arg.argumentIdentifier, @"value":arg.argumentValue}];
    //}
    
    return @{@"name":self.triggerName, @"enabled":[NSNumber numberWithInteger:self.triggerEnabled], @"template":@([self.triggerTemplate integerValue]), @"device":@([self.triggerDevice integerValue]), @"arguments":arguments};
}

-(NSString*)description{
    return @"new_trigger_test";
}
@end

@implementation VeraSceneTriggerArgument

@end