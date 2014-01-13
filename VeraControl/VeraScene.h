//
//  VeraSceneTrigger.h
//  C2
//
//  Created by Drew Ingebretsen on 9/22/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VeraScene : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *sceneNum;
@property (nonatomic, strong) NSString *room;
@property (nonatomic, strong) NSString *controllerUrl;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSArray *triggers;
@property (nonatomic, strong) NSArray *actions;
@property (nonatomic, strong) NSArray *schedules;

-(VeraScene*)initWithDictionary:(NSDictionary*)dictionary;

-(void)runSceneCompletion:(void(^)())callback;
-(void)SceneOffCompletion:(void(^)())callback;
-(void)saveSceneToVera:(void(^)())callback;

@end
