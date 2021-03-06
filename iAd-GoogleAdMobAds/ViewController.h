//
//  ViewController.h
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

#import <UIKit/UIKit.h>

//Ads
#import <iAd/iAd.h>
#import "GADBannerView.h"
#import "GADBannerViewDelegate.h"
#import "GADInterstitial.h"
#import "GADInterstitialDelegate.h"

@interface ViewController : UIViewController<ADBannerViewDelegate,ADInterstitialAdDelegate,GADBannerViewDelegate,GADInterstitialDelegate>

@property (nonatomic, strong) UIButton *btnSetting;

//Ads广告
@property (nonatomic, strong) ADBannerView     *iAdView;
@property (nonatomic, strong) ADInterstitialAd *iAdFull;
@property (nonatomic, strong) GADBannerView    *gAdView;
@property (nonatomic, strong) GADInterstitial  *gAdFull;
@end
