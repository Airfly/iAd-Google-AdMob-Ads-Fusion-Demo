//
//  ViewController.h
//  iAd-GoogleAdMobAds
//
//  Air Vision Touch Serial
//
//  http://airflypan.com
//  airflypan@msn.com
//  QQ:1272000
//  Tel:+86 159 7771 0035
//
//  Created by Airfly Pan on 10-3-13.
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

#import <UIKit/UIKit.h>

//Ads
#import <iAd/iAd.h>
#import "GADBannerView.h"
#import "GADBannerViewDelegate.h"

@interface ViewController : UIViewController<ADBannerViewDelegate,GADBannerViewDelegate> {
	//Ads
	ADBannerView *iAdView;
	GADBannerView *gAdView;

    UIButton *iLink;
}

//Ads
@property (nonatomic, strong) ADBannerView *iAdView;
@property (nonatomic, strong) GADBannerView *gAdView;

@property (nonatomic, strong) UIButton *iLink;


- (void)rotateContent;

- (void)iLinkTap:(id)sender;


//Ads
- (BOOL)isiAdSupported;
- (BOOL)isiAdAvailable;
- (void)creategAd;
- (void)createiAd;
- (void)planAds;
- (void)destroyAds;
- (void)tryiAdWhenGAdFailed;
- (void)tryGAdWheniAdFailed;
- (void)layoutGADBannerView;
- (GADAdSize)sizeGADBanner;

//iAd Delegate
- (void)cancelBannerViewAction;
- (void)bannerViewDidLoadAd:(ADBannerView *)banner;
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error;
- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave;
- (void)bannerViewActionDidFinish:(ADBannerView *)banner;
@end
