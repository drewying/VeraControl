//
//  VeraSceneAction.m
//  Home
//
//  Created by Drew Ingebretsen on 12/29/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "VeraSceneAction.h"

@implementation VeraSceneAction

-(NSString*)description{
    return [NSString stringWithFormat:@"Perform %@ with device %@", self.actionActionName, self.actionDevice];
}

-(NSDictionary*)actionDictionary{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"device"] = self.actionDevice;
    dictionary[@"service"] = self.actionService;
    dictionary[@"action"] = self.actionAction;
    
    if (self.actionArgumentSystemDefined){
        dictionary[@"arguments"] = @[@{@"name":self.actionArgumentSystemDefined.argumentName, @"value":self.actionArgumentSystemDefined.argumentValue}];
    }
    else{
        dictionary[@"arguments"] = @[@{@"name":self.actionArgumentUserDefined.argumentName, @"value":self.actionArgumentUserDefined.argumentValue}];
    }
    return dictionary;
}

@end

@implementation VeraSceneActionArgument

@end