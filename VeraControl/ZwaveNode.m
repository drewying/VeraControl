//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"
#import "VeraSceneTrigger.h"
#import "VeraSceneAction.h"

@implementation ZwaveNode

-(id)initWithDictionary:(NSDictionary*)dictionary{
    self = [super init];
    if (self){
        self.identifier = dictionary[@"id"];
        [self updateWithDictionary:dictionary];
    }
    return self;
}

-(void)updateWithDictionary:(NSDictionary *)dictionary {
    self.name = dictionary[@"name"];
    self.veraDeviceFileName = [dictionary[@"device_file"] stringByReplacingOccurrencesOfString:@"xml" withString:@"json"];
    self.room = dictionary[@"room"];
}

-(void)performAction:(NSString*)action usingService:(NSString*)service completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=action&output_format=json&DeviceNum=%@&serviceId=%@&action=%@", self.controllerUrl, self.identifier, service, action];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(response, data, error);
            });
        }
    }];
}

-(void)getDeviceFileInformation:(void(^)(NSDictionary *deviceInfo))callback{
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=file&parameters=%@", self.controllerUrl, self.veraDeviceFileName];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (callback){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(dict);
            });
        }
    }];
    
}

-(void)getSceneActionFactories:(void(^)(NSArray *actions))callback{
    [self getDeviceFileInformation:^(NSDictionary *deviceInformation){
        NSArray *array = @[];
        NSDictionary *dictionary = deviceInformation[@"sceneList"][@"group_1"];
        for (NSString *key in [dictionary allKeys]){
            NSDictionary *actionDictionary = dictionary[key];
            VeraSceneAction *action = [[VeraSceneAction alloc] init];
            action.actionActionName = actionDictionary[@"label"];
            action.actionDevice = self.identifier;
            action.actionService = actionDictionary[@"serviceId"];
            action.actionAction = actionDictionary[@"action"];
            //System Defined Argument
            if (actionDictionary[@"arguments"]){
                VeraSceneActionArgument *argument = [[VeraSceneActionArgument alloc] init];
                NSDictionary *argumentDictionary = actionDictionary[@"arguments"];
                NSString *variable = [[argumentDictionary allKeys] firstObject];
                argument.argumentName = variable;
                argument.argumentValue = [argumentDictionary objectForKey:variable];
                action.actionArgumentSystemDefined = argument;
            }
            
            //User Defined Argument
            if (actionDictionary[@"argumentList"]){
                NSDictionary *argumentDictionary = actionDictionary[@"argumentList"];
                NSArray *keys = [argumentDictionary allKeys];
                for (NSString *string in keys){
                    VeraSceneActionArgument *argument = [[VeraSceneActionArgument alloc] init];
                    NSDictionary *dic = argumentDictionary[string];
                    argument.argumentName = dic[@"name"];
                    action.actionArgumentUserDefined = argument;
                }
            }
            
            array = [array arrayByAddingObject:action];
        }
        if (callback){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(array);
            });
        }
    }];
}

-(void)getSceneTriggerFactories:(void(^)(NSArray *triggers))callback{
    //This method is a mess. Need to clean up.
    [self getDeviceFileInformation:^(NSDictionary *deviceInformation){
        NSArray *array = @[];
        for (NSDictionary *dict in deviceInformation[@"eventList2"]){
            VeraSceneTrigger *trigger = [[VeraSceneTrigger alloc] init];
            
            trigger.triggerIdentifier = dict[@"id"];
            trigger.triggerDescription = dict[@"label"][@"text"];
            trigger.triggerDevice = self.identifier;
            trigger.triggerEnabled = YES;
            trigger.triggerTemplate = trigger.triggerIdentifier;
            
            NSMutableArray *args = [[NSMutableArray alloc] init];
            
            for (NSDictionary *argsDict in dict[@"argumentList"]){
                VeraSceneTriggerArgument *arg = [[VeraSceneTriggerArgument alloc] init];
                arg.argumentIdentifier = argsDict[@"id"];
                arg.argumentAllowedValues = @[];
                
                if ([argsDict[@"dataType"] isEqualToString:@"boolean"]){
                    //arg.argumentDataType = kDataTypeBool;
                    for (NSDictionary *allowedValueListDict in argsDict[@"allowedValueList"]){
                        
                        NSMutableArray *values = [[allowedValueListDict allKeys] mutableCopy];
                        [values removeObjectIdenticalTo:@"HumanFriendlyText"];
                        
                        NSString *formattedString = allowedValueListDict[@"HumanFriendlyText"][@"text"];
                        formattedString = [formattedString stringByReplacingOccurrencesOfString:@"_DEVICE_NAME_" withString:self.name];
                        
                        NSDictionary *formattedDictionary = @{@"description":formattedString, @"value":allowedValueListDict[[values firstObject]]};
                        
                        arg.argumentAllowedValues = [arg.argumentAllowedValues arrayByAddingObject:formattedDictionary];
                    }
                }
                else{
                    arg.argumentDescription = argsDict[@"HumanFriendlyText"][@"text"];
                }
                
                [args addObject:arg];
            }
            trigger.triggerArguments = [args copy];
            array = [array arrayByAddingObject:trigger];
        }
        if (callback){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(array);
            });
        }
    }];
    
}

/*-(void)getSceneTriggerFactories:(void(^)(NSArray *triggers))callback{
    //This method is a mess. Need to clean up.
    [self getDeviceFileInformation:^(NSDictionary *deviceInformation){
        NSArray *array = @[];
        for (NSDictionary *dict in deviceInformation[@"eventList2"]){
            VeraSceneTriggerFactory *triggerFactory = [[VeraSceneTriggerFactory alloc] init];
            triggerFactory.triggerIdentifier = dict[@"id"];
            triggerFactory.triggerDescription = dict[@"label"][@"text"];
            triggerFactory.triggerDevice = self.identifier;
            //NSLog(@"%@",dict);
            NSMutableArray *args = [[NSMutableArray alloc] init];
            for (NSDictionary *argsDict in dict[@"argumentList"]){
                VeraSceneTriggerArgumentFactory *arg = [[VeraSceneTriggerArgumentFactory alloc] init];
                arg.argumentIdentifier = argsDict[@"id"];
                arg.argumentAllowedValues = @[];
                
                if ([argsDict[@"dataType"] isEqualToString:@"boolean"]){
                    arg.argumentDataType = kDataTypeBool;
                    for (NSDictionary *allowedValueListDict in argsDict[@"allowedValueList"]){
                        
                        NSMutableArray *values = [[allowedValueListDict allKeys] mutableCopy];
                        [values removeObjectIdenticalTo:@"HumanFriendlyText"];
                        
                        NSString *formattedString = allowedValueListDict[@"HumanFriendlyText"][@"text"];
                        formattedString = [formattedString stringByReplacingOccurrencesOfString:@"_DEVICE_NAME_" withString:self.name];
                        
                        NSDictionary *formattedDictionary = @{@"description":formattedString, @"value":allowedValueListDict[[values firstObject]]};
                        
                        arg.argumentAllowedValues = [arg.argumentAllowedValues arrayByAddingObject:formattedDictionary];
                    }
                }
                else{
                    arg.argumentDescription = argsDict[@"HumanFriendlyText"][@"text"];
                    arg.argumentDataType = kDataTypeInteger;
                }
                
                [args addObject:arg];
            }
            triggerFactory.triggerArguments = [args copy];
            array = [array arrayByAddingObject:triggerFactory];
        }
        callback(array);
    }];
    
}*/


@end