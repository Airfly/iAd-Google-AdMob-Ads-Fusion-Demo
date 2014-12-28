//
//  airInlineCommon.h
//  Air Vision Touch Serial
//
//  http://airflypan.com
//  airflypan@msn.com
//  QQ:1272000
//  Tel:+86 159 7771 0035
//
//  Created by Airfly Pan on 2009-3-13.
//  Copyright (c) 2009-2020 Air Vision Studio. All rights reserved.
//

#if TARGET_OS_IPHONE

// Compiling for iOS
#import <UIKit/UIKit.h>

    #define HEXCOLOR(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#pragma mark -
#pragma mark - Empty Checking Function
static inline BOOL isEmpty(id thing) {
    @try{
        return thing == nil || thing == Nil || thing == NULL || [thing isKindOfClass:[NSNull class]]
        || ([thing isKindOfClass:[NSString class]] && [(NSString *)thing length] == 0)
        || ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0)
        || ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0)
        || ([thing respondsToSelector:@selector(count)] && [(NSDictionary *)thing count] == 0)
        || ([thing isKindOfClass:[UITextField class]] && [[(UITextField *)thing text] length] == 0);
    }
    @catch (NSException *exception){
        //NSLog (@"Caught %@%@", [exception name], [exception reason]);
        return YES;
    }
}

#else

// Compiling for Mac OS X

static inline BOOL isEmpty(id thing) {
    @try{
        return thing == nil || thing == Nil || thing == NULL || [thing isKindOfClass:[NSNull class]]
        || ([thing isKindOfClass:[NSString class]] && [(NSString *)thing length] == 0)
        || ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0)
        || ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0)
        || ([thing respondsToSelector:@selector(count)] && [(NSDictionary *)thing count] == 0)
        /*|| ([thing isKindOfClass:[NSTextField class]] && [[(NSTextField *)thing text] length] == 0)*/;
    }
    @catch (NSException *exception){
        //NSLog (@"Caught %@%@", [exception name], [exception reason]);
        return YES;
    }
}
#endif

#pragma mark -
#pragma mark - Number Checking Functions
static inline BOOL isNumeric(NSString *string) {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *number = [formatter numberFromString:string];
    [formatter release];
    return !!number; // If the string is not numeric, number will be nil
}

static inline BOOL isNonCodingNumeric(NSString *string) {
    //NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    //NSNumber *number = [formatter numberFromString:string];
    //return !!number; // If the string is not numeric, number will be nil
    
    BOOL result = isNumeric(string);
    
    if(result && ![string isEqualToString:@"0"]) {
        //if startWith "0" and more than 1 digi then think that is a Coding Serial Number
        NSString *firstCharacter = [string substringToIndex:1];
        if([firstCharacter isEqualToString:@"0"])
            result = NO;
    }
    
    return result;
}

#pragma mark -
#pragma mark - Number to String Common Functions
//- (NSString *)getRealStringByFloat:(float)aValue {
static inline NSString *getRealStringByFloat(float aValue) {
    NSString *result = [NSString stringWithFormat:@"%.2f",aValue];
    if(aValue == 0.0f || aValue == 0)
        result = @"0";
    else {
        NSString *strTmp;
        do {
            strTmp = [result substringFromIndex:[result length]-1];
            if([strTmp isEqualToString:@"0"])
                result = [result substringToIndex:[result length]-1];
        } while ([strTmp isEqualToString:@"0"]);
        //check DOT
        if([strTmp isEqualToString:@"."])
            result = [result substringToIndex:[result length]-1];
    }
    return result;
}


#if TARGET_OS_IPHONE

// Compiling for iOS

#pragma mark -
#pragma mark - UIInterface Orientation
static inline UIInterfaceOrientation airInterfaceOrientation() {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

#pragma mark -
#pragma mark - Current Screen Resolution
static inline CGRect screenBounds() {
    UIInterfaceOrientation _orientation = airInterfaceOrientation();
    
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullScreenRect = screen.bounds; //implicitly in Portrait orientation.
    
    float iOSVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    CGRect temp = fullScreenRect;
    temp.origin.x = 0;
    temp.origin.y = 0;
    
    if (iOSVer < 8.0 && UIInterfaceOrientationIsLandscape(_orientation)) {
        temp.size.width = fullScreenRect.size.height;
        temp.size.height = fullScreenRect.size.width;
    }
    
    //if(iOSVer < 7.0 && [UIApplication sharedApplication].statusBarHidden == NO)
    //    temp.origin.y = 20.0;
    
    fullScreenRect = temp;
    
    return fullScreenRect;
}

static inline CGRect screenBoundsForOrientation(UIInterfaceOrientation _orientation) {
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullScreenRect = screen.bounds; //implicitly in Portrait orientation.
    
    float iOSVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    CGRect temp = fullScreenRect;
    temp.origin.x = 0;
    temp.origin.y = 0;
    
    if (iOSVer < 8.0 && UIInterfaceOrientationIsLandscape(_orientation)) {
        temp.size.width = fullScreenRect.size.height;
        temp.size.height = fullScreenRect.size.width;
    }
    
    //if(iOSVer < 7.0 && [UIApplication sharedApplication].statusBarHidden == NO)
    //    temp.origin.y = 20.0;
    
    fullScreenRect = temp;
    
    return fullScreenRect;
}

#pragma mark -
#pragma mark - Current Client Resolution
static inline CGRect clientBounds() {
    UIInterfaceOrientation _orientation = airInterfaceOrientation();
    
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullClientRect = screen.applicationFrame; //implicitly in Portrait orientation.
    
    float iOSVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if(iOSVer >= 7.0)
        fullClientRect = screen.bounds;
    
    CGRect temp = fullClientRect;
    temp.origin.x = 0;
    temp.origin.y = 0;  //fix it to 0
    
    if (iOSVer < 8.0 && UIInterfaceOrientationIsLandscape(_orientation)) {
        temp.size.width = fullClientRect.size.height;
        temp.size.height = fullClientRect.size.width;
    }
    fullClientRect = temp;
    return fullClientRect;
}

static inline CGRect clientBoundsForOrientation(UIInterfaceOrientation _orientation) {
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullClientRect = screen.applicationFrame; //implicitly in Portrait orientation.
    
    float iOSVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if(iOSVer >= 7.0)
        fullClientRect = screen.bounds;
    
    CGRect temp = fullClientRect;
    temp.origin.x = 0;
    temp.origin.y = 0;  //fix it to 0
    
    if (iOSVer < 8.0 && UIInterfaceOrientationIsLandscape(_orientation)) {
        temp.size.width = fullClientRect.size.height;
        temp.size.height = fullClientRect.size.width;
    }
    fullClientRect = temp;
    return fullClientRect;
}

static inline CGFloat clientHeightForOrientation(UIInterfaceOrientation _orientation) {
    //UIInterfaceOrientation _orientation = airInterfaceOrientation();
    
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullClientRect = screen.applicationFrame; //implicitly in Portrait orientation.
    
    float iOSVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if(iOSVer >= 7.0)
        fullClientRect = screen.bounds;
    
    CGRect temp = fullClientRect;
    temp.origin.x = 0;
    temp.origin.y = 0;  //fix it to 0
    
    if (iOSVer < 8.0 && UIInterfaceOrientationIsLandscape(_orientation)) {
        temp.size.width = fullClientRect.size.height;
        temp.size.height = fullClientRect.size.width;
    }
    fullClientRect = temp;
    return fullClientRect.size.height;
}

static inline CGFloat clientHeight() {
    UIInterfaceOrientation _orientation = airInterfaceOrientation();
    
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullClientRect = screen.applicationFrame; //implicitly in Portrait orientation.
    
    float iOSVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if(iOSVer >= 7.0)
        fullClientRect = screen.bounds;
    
    CGRect temp = fullClientRect;
    temp.origin.x = 0;
    temp.origin.y = 0;  //fix it to 0
    
    if (iOSVer < 8.0 && UIInterfaceOrientationIsLandscape(_orientation)) {
        temp.size.width = fullClientRect.size.height;
        temp.size.height = fullClientRect.size.width;
    }
    fullClientRect = temp;
    return fullClientRect.size.height;
}

#pragma mark -
#pragma mark - Alert & Message Methods
static inline void notifyMessage(NSString *aMessage) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notification",@"")
                                                    message:aMessage
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK",@"")
                                          otherButtonTitles:nil,nil];
    [alert show];
    [alert release];
    //return YES;
}

static inline void notifyMessageWithTitle(NSString *aMessage, NSString *aTitleKey) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(aTitleKey,@"")
                                                    message:aMessage
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK",@"")
                                          otherButtonTitles:nil,nil];
    [alert show];
    [alert release];
    //return YES;
}
#endif
