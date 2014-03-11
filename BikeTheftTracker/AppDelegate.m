//
//  AppDelegate.m
//  BikeTheftTracker
//
//  Created by Russell Barnes on 1/12/14.
//  Copyright (c) 2014 SeniorDesign2014. All rights reserved.
//

#import "AppDelegate.h"
#include "GAEData.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Registered for notification w/ token");
    
    NSString *deviceTokenString = [[NSString alloc] initWithString: [[[[deviceToken description]
                                                      stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                                     stringByReplacingOccurrencesOfString: @">" withString: @""]
                                                    stringByReplacingOccurrencesOfString: @" " withString: @""]];
    
    GAEData *oregonStateAccount = [[GAEData alloc] init];
    NSString *const SetPushTokenURL = [NSString stringWithFormat:@"%@?clientid=00000001&pushtoken=%@", oregonStateAccount.SetPushTokenURL, deviceTokenString];
    
    // Push request
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:SetPushTokenURL]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                NSLog(@"Request completed.");
                if (error)
                    NSLog(@"Error: %@", error);
            }
      ] resume];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Received push notification!");
    
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
