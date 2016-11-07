//
//  AppDelegate.h
//  AudioSessionTest
//
//  Created by TerryChao on 2016/10/24.
//  Copyright © 2016年 czh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

