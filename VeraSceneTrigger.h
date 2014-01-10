//
//  VeraSceneTrigger.h
//  Home
//
//  Created by Drew Ingebretsen on 12/19/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VeraSceneTrigger : NSObject

@property (nonatomic, strong) NSArray *triggerArguments;
@property (nonatomic, strong) NSString *triggerDevice;
@property (nonatomic, assign) BOOL triggerEnabled;
@property (nonatomic, strong) NSDate *triggerLastRun;
@property (nonatomic, strong) NSString *triggerName;
@property (nonatomic, strong) NSString *triggerTemplate;
@property (nonatomic, strong) NSString *triggerIdentifier;
@property (nonatomic, strong) NSString *triggerDescription;

-(VeraSceneTrigger*)initWithDictionary:(NSDictionary*)dictionary;

-(NSDictionary*)triggerDictionary;

@end

@interface VeraSceneTriggerArgument : NSObject

@property (nonatomic, strong) NSString *argumentIdentifier;
@property (nonatomic, strong) NSString *argumentValue;
@property (nonatomic, strong) NSString *argumentDescription;

@property (nonatomic, strong) NSArray *argumentAllowedValues;

@end