//
//  airCommon.m
//
//  Air Vision Touch Serial
//
//  http://airflypan.com
//  airflypan@msn.com
//  QQ:1272000
//  Tel:+86 159 7771 0035
//
//  Created by Airfly Pan on 09-3-13.
//  Copyright (c) 2009-2013 Air Vision Studio. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "airCommon.h"

@implementation airCommon
#pragma mark -
#pragma mark - Device information
+ (BOOL)isiPadModel {
    BOOL result = NO;
    NSRange ideviceRange = [[[UIDevice currentDevice] model] rangeOfString:@"iPad"];
	if (ideviceRange.location == 0)
        result = YES;
    return result;
}

+ (float)iosVersion {
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

+ (CGRect)clientBounds {
    return [self clientBoundsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

+ (CGRect)clientBoundsForOrientation:(UIInterfaceOrientation)_orientation {
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullClientRect = screen.applicationFrame; //implicitly in Portrait orientation.
    
    CGRect temp;
    temp.size.width = fullClientRect.size.width;
    temp.size.height = fullClientRect.size.height;
    temp.origin.x = 0;
    temp.origin.y = 0;  //fix it to 0
    
    if (UIInterfaceOrientationIsLandscape(_orientation)) {
        temp.size.width = fullClientRect.size.height;
        temp.size.height = fullClientRect.size.width;
    }
    fullClientRect = temp;
    return fullClientRect;
}
@end
