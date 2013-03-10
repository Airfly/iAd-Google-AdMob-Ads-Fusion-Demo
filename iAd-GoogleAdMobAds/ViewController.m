//
//  ViewController.m
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

#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"

#import "airCommon.h"

@interface ViewController ()

@end

@implementation ViewController

//Ads
@synthesize iAdView;
@synthesize gAdView;

@synthesize iLink;

#pragma mark -
#pragma mark - Private variables
static int  iAdFailedCount = 0;
static BOOL is_iAdON = NO;
static BOOL is_gAdON = NO;
static BOOL is_gAdFailed = NO;
static BOOL is_iAdWillON = NO;
static BOOL is_gAdWillON = NO;
static BOOL isAdLoaded = NO;
static NSString *AdMob_BANNER_UNIT_ID=@"a14e4381ad94b7d";

static BOOL isiPad = NO;
static CGFloat iOSVer = 4.3f;
static CGSize sizeClient;

#pragma mark -
#pragma mark - iAd Delegate
// Cancels the current in-progress banner view action. This should only be used in cases where the
// user's attention is required immediately.
- (void)cancelBannerViewAction {

}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    if (!is_iAdON) {
        [self layoutiAdBannerView:YES];
        is_iAdON = YES;
		banner.hidden = NO;
    }
    isAdLoaded = YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
	if(is_iAdON) {
        [self layoutiAdBannerView:YES];
        is_iAdON = NO;
		banner.hidden = YES;
    }
    iAdFailedCount++;
    if(iAdFailedCount == 3) {
        //just try to display AdMob Ads after iAd failed...
        [iAdView removeFromSuperview];
        [iAdView release];
        iAdView = nil;
        
        iAdFailedCount = 0;
        is_iAdON = NO;
        isAdLoaded = NO;
        [self tryGAdWheniAdFailed];
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    return YES;
    //BOOL shouldExecuteAction = [self allowActionToRun]; // your application implements this method
    //if (!willLeave && shouldExecuteAction)
    //{
    //    // insert code here to suspend any services that might conflict with the advertisement
    //}
    //return shouldExecuteAction;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    
}

#pragma mark -
#pragma mark - Google Admob Ads Delegate
// Sent when an ad request loaded an ad.  This is a good opportunity to add this
// view to the hierarchy if it has not yet been added.  If the ad was received
// as a part of the server-side auto refreshing, you can examine the
// hasAutoRefreshed property of the view.
- (void)adViewDidReceiveAd:(GADBannerView *)view {
	[self.view addSubview:gAdView];
    is_gAdFailed = NO;
    is_gAdON = YES;
    isAdLoaded = YES;
}

// Sent when an ad request failed.  Normally this is because no network
// connection was available or no ads were available (i.e. no fill).  If the
// error was received as a part of the server-side auto refreshing, you can
// examine the hasAutoRefreshed property of the view.
- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    if(is_gAdON) {
        is_gAdON = NO;
        [gAdView removeFromSuperview];
    }
    [gAdView release];
    gAdView = nil;
    isAdLoaded = NO;
    
    //try iAd when failed...
    if(!is_gAdFailed) {
        is_gAdFailed = YES;
        [self tryiAdWhenGAdFailed];
    }
}

// Sent just before presenting the user a full screen view, such as a browser,
// in response to clicking on an ad.  Use this opportunity to stop animations,
// time sensitive interactions, etc.
//
// Normally the user looks at the ad, dismisses it, and control returns to your
// application by calling adViewDidDismissScreen:.  However if the user hits the
// Home button or clicks on an App Store link your application will end.  On iOS
// 4.0+ the next method called will be applicationWillResignActive: of your
// UIViewController (UIApplicationWillResignActiveNotification).  Immediately
// after that adViewWillLeaveApplication: is called.
- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    
}

// Sent just before dismissing a full screen view.
- (void)adViewWillDismissScreen:(GADBannerView *)adView {
    
}

// Sent just after dismissing a full screen view.  Use this opportunity to
// restart anything you may have stopped as part of adViewWillPresentScreen:.
- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    
}

// Sent just before the application will background or terminate because the
// user clicked on an ad that will launch another application (such as the App
// Store).  The normal UIApplicationDelegate methods, like
// applicationDidEnterBackground:, will be called immediately before this.
- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    
}

#pragma mark -
#pragma mark - Handle Ads
// Ah ha, this project building under xcode 4.6,
// so the target will running on an iOS 4.3 at least.
- (BOOL)isiAdSupported {
    bool result = NO;
    if(isiPad && iOSVer >= 4.2f)
        result = YES;
    else if((!isiPad) && iOSVer >= 4.0f)
        result = YES;
    return result;
}

// Now I'm using WAY 2 to check iAd available
// If you has any good idea to do this, I would love to know. Thanks.
- (BOOL)isiAdAvailable {
    bool result = NO;
    
    // way 1:
    // ==========================================================================
    //if([self isiAdSupported]
    //   && ([[[NSTimeZone localTimeZone] name] rangeOfString:@"America/"].location == 0
    //       || [[[NSTimeZone localTimeZone] name] rangeOfString:@"Pacific/"].location == 0
    //       || [[[NSTimeZone localTimeZone] name] rangeOfString:@"Europe/"].location == 0
    //       || [[[NSTimeZone localTimeZone] name] rangeOfString:@"Asia/Tokyo"].location == 0)
    //       || ... )
    //{
    //    result = YES;
    //}

    // way 2:
    // ==========================================================================
    //        地区：NSLocal.localeIdentifier
    //------------------------------------------------------------------------------------
    //        美国：en_US，美国边远小岛：en_UM，美属萨摩亚：en_AS，美属维京群岛：en_VI，
    //                    夏威夷：haw_US，彻罗基：chr_US，关岛：en_GU，美国西班牙文：es_US
    //
    //2010.12 英国：en_GB，凯尔特：kw_GB，马恩岛：gv_GB，威尔士：cy_GB，
    //
    //        法国：fr_FR，法属圭亚那：fr_GF，布里多尼：br_FR，
    //
    //2011.1  德国：de_DE
    //
    //2011.?  日本：ja_JP
    //
    //2012.12 加拿大：en_CA，加拿大法文：fr_CA
    //
    //        意大利：it_IT
    //
    //        西班牙：es_ES，巴斯克：eu_ES，加利西亚：gl_ES，加泰罗尼亚：ca_ES，
    //
    //2013.2  澳大利亚：en_AU，
    //
    //        新西兰：en_NZ，
    //
    if([self isiAdSupported]) {
        NSArray *arrCheck = [NSArray arrayWithObjects:
                             @"en_US", @"en_UM", @"en_AS", @"en_VI", @"haw_US", @"chr_US", @"en_GU",@"es_US", @"_US",
                             @"en_GB", @"kw_GB", @"gv_GB", @"cy_GB", @"_GB",
                             @"fr_FR", @"fr_GF", @"br_FR", @"_FR",
                             @"de_DE", @"_DE",
                             @"ja_JP",
                             @"en_CA", @"fr_CA", @"_CA",
                             @"it_IT", @"_IT",
                             @"es_ES", @"eu_ES", @"gl_ES", @"ca_ES", @"_ES",
                             @"en_AU",
                             @"en_NZ",
                             nil];
        
        NSString *localeFullId= [[NSLocale autoupdatingCurrentLocale] localeIdentifier];
        NSString *localeSuffixId = [localeFullId substringFromIndex:[localeFullId rangeOfString:@"_"].location];
        
        if([arrCheck indexOfObject:localeFullId] != NSNotFound || [arrCheck indexOfObject:localeSuffixId] != NSNotFound)
            result = YES;
    }
    return result;
}

- (void)creategAd {
    gAdView = [[GADBannerView alloc] initWithFrame:CGRectZero];
    
    gAdView.layer.shadowOffset = CGSizeMake(5, 3);
    gAdView.layer.shadowOpacity = 0.9;
    gAdView.layer.shadowColor = [UIColor grayColor].CGColor;
    //[gAdView.layer setMasksToBounds:YES];
    //[gAdView.layer setCornerRadius:kCornerRadius];
    
    gAdView.adUnitID = AdMob_BANNER_UNIT_ID;
    gAdView.delegate = self;
    [gAdView setRootViewController:self];
    gAdView.adSize = [self sizeGADBanner];
    [self layoutGADBannerView];
    GADRequest * request = [GADRequest request];
    request.testing = NO;
    [gAdView loadRequest:request];
}

- (void)createiAd {
    // On iOS 6 ADBannerView introduces a new initializer, use it when available.
    if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
        iAdView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    } else {
        iAdView = [[ADBannerView alloc] init];
    }
    iAdView.delegate = self;
    
    [iAdView.layer setMasksToBounds:YES];
    [iAdView.layer setCornerRadius:5.0f];
    
    [self.view addSubview:iAdView];
    iAdView.hidden = YES;
}

- (void)planAds {
	is_iAdWillON = NO;
	is_gAdWillON = NO;
	
	//if iAd available, we'll display iAd
	if([self isiAdAvailable])
        is_iAdWillON = YES;
	else
		is_gAdWillON = YES;
    
	if(is_gAdWillON || is_iAdWillON) {
		if(is_gAdWillON) {
            if(gAdView) {
                [gAdView removeFromSuperview];
                [gAdView release];
                gAdView = nil;
            }
            
			if(!gAdView) {
                [self creategAd];
			}
		}
		else {
            if(iAdView) {
                [iAdView removeFromSuperview];
                [iAdView release];
                iAdView = nil;
            }
            
			if(!iAdView) {
                [self createiAd];
			}
		}
	}
	else {
		if(gAdView) {
			if(is_gAdON) {
                is_gAdON = NO;
                [gAdView removeFromSuperview];
            }
			[gAdView release];
			gAdView = nil;
		}
		else if(iAdView) {
			if(is_iAdON) {
                [self layoutiAdBannerView:YES];
				is_iAdON = NO;
				iAdView.hidden = YES;
			}
            
			[iAdView removeFromSuperview];
			[iAdView release];
			iAdView = nil;
		}
	}
}

- (void)destroyAds {
    if(gAdView) {
        [gAdView removeFromSuperview];
        [gAdView release];
        gAdView = nil;
    }
    
    if(iAdView) {
        [iAdView removeFromSuperview];
        [iAdView release];
        iAdView = nil;
    }
    
    isAdLoaded = NO;
    is_gAdON = NO;
    is_iAdON = NO;
}

- (void)tryiAdWhenGAdFailed {
    is_gAdFailed = YES;
    is_iAdWillON = [self isiAdSupported];
	
	if(is_iAdWillON) {
        if(gAdView) {
            [gAdView removeFromSuperview];
            [gAdView release];
            gAdView = nil;
        }
        
		if(!iAdView) {
			[self createiAd];
		}
	}
}

- (void)tryGAdWheniAdFailed {
    iAdFailedCount = 0;
    is_gAdWillON = YES;
	
	if(is_gAdWillON) {
        if(!gAdView) {
            [self creategAd];
        }
	}
}

// Set the origin of the adView frame per the selected size for the banner.
- (void)layoutGADBannerView {
    CGSize bannerCGSize = CGSizeFromGADAdSize(gAdView.adSize);
    CGRect frame = gAdView.frame;
    frame.origin.x = (sizeClient.width - bannerCGSize.width) / 2.0;
    frame.origin.y = 0;
    //frame.origin.y = sizeClient.height - bannerCGSize.height;
    gAdView.frame = frame;
    if (gAdView.hidden) {
        gAdView.hidden = NO;
    }
}

- (void)layoutiAdBannerView:(BOOL)animated
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    } else {
        iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }
    
    //CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = iAdView.frame;
    if (iAdView.bannerLoaded) {
        //contentFrame.size.height -= iAdView.frame.size.height;
        //bannerFrame.origin.y = contentFrame.size.height;
        bannerFrame.origin.y = 0;
    } else {
        //bannerFrame.origin.y = contentFrame.size.height;
        bannerFrame.origin.y -= iAdView.frame.size.height;
    }
    
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        iAdView.frame = bannerFrame;
    }];
}

// Returns the currently selected BannerSize's GADAdSize to load.
- (GADAdSize)sizeGADBanner {
    //current orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    GADAdSize result;
    if(UIInterfaceOrientationIsLandscape(orientation))
        result = kGADAdSizeSmartBannerLandscape;
    else
        result = kGADAdSizeSmartBannerPortrait;
    return result;
}

#pragma mark -
#pragma mark - Refresh Content
-(void)rotateContent {
    [self destroyAds];
    [self planAds];

    CGRect tmpFrame = iLink.frame;
    tmpFrame.origin.x = sizeClient.width - 8 - tmpFrame.size.width;
    tmpFrame.origin.y = sizeClient.height - 8 - tmpFrame.size.height;
    iLink.frame = tmpFrame;
}

#pragma mark -
#pragma mark - About/Information/Web
- (void)iLinkTap:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://airflypan.com"]];
}

#pragma mark -
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor grayColor]];
    
    isiPad = [airCommon isiPadModel];
    iOSVer = [airCommon iosVersion];
    sizeClient = [airCommon clientBounds].size;
    if(isiPad) {
        AdMob_BANNER_UNIT_ID = @"a14c15bb908e91f";
    }
    else {
        AdMob_BANNER_UNIT_ID = @"a14c00b2b7c0c11";
    }
    [self planAds];

    //other things
    self.iLink = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [self.iLink addTarget:self action:@selector(iLinkTap:) forControlEvents:UIControlEventTouchUpInside];
    CGRect tmpFrame = self.iLink.frame;
    tmpFrame.origin.x = sizeClient.width - 8 - tmpFrame.size.width;
    tmpFrame.origin.y = sizeClient.height - 8 - tmpFrame.size.height;
    self.iLink.frame = tmpFrame;
    [self.view addSubview:self.iLink];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    sizeClient = [airCommon clientBounds].size;;
    [self rotateContent];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
