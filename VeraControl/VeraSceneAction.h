//
//  VeraSceneAction.h
//  Home
//
//  Created by Drew Ingebretsen on 12/29/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VeraSceneActionArgument;

@interface VeraSceneAction : NSObject

@property (nonatomic, strong) NSString *actionActionName;
@property (nonatomic, strong) NSString *actionDevice;
@property (nonatomic, strong) NSString *actionService;
@property (nonatomic, strong) NSString *actionAction;

@property (nonatomic, strong) VeraSceneActionArgument *actionArgumentUserDefined; //This argument requires a user defined value
@property (nonatomic, strong) VeraSceneActionArgument *actionArgumentSystemDefined; //This argument does not require a user defined valie.

-(NSDictionary*)actionDictionary;

@end

@interface VeraSceneActionArgument : NSObject

@property (nonatomic, strong) NSString *argumentName;
@property (nonatomic, strong) NSString *argumentValue;

@end
