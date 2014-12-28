//
//  ViewController.m
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

#import "ViewController.h"

#import "airInlineCommon.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark -
#pragma mark - for Ads
@synthesize iAdView;
@synthesize iAdFull;
@synthesize gAdView;
@synthesize gAdFull;

static int  iAdFailedCount = 0;
static BOOL is_iAdON = NO;
static BOOL is_gAdON = NO;
static BOOL is_gAdFailed = NO;
static BOOL is_iAdWillON = NO;
static BOOL is_gAdWillON = NO;
static BOOL isAdLoaded = NO;

static NSString *MY_BANNER_UNIT_ID=@"a14e4381ad94b7d";

//interstitial ad provider index, marked current provider
//广告供应商索引，标识当前使用哪一家广告商
//0-gad; 1-iad
static int interstitialAdIndex = 0;

//count of interstitial ad requested,
//once request success then hedge for one.
//if failed then switch ad provider.
//全屏广告请求计数，次数越大，说明请求广告次数越多。
//每能展示一次广告，就抵消一次请求。
//如果请求失败，则切换广告供应商。
static int interstitialAdApplyCount = 0;

static int interstitialAdUnPresentCount = 0;
static BOOL isInterstitialAdUIReady = NO;

static CGSize sizeClient;

#pragma mark -
#pragma mark - Private ...
static BOOL isiPad;
static float iOSVer = 6.0;

#pragma mark -
#pragma mark HardWare Detection Methods
-(void)detectHardware {
	iOSVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    isiPad = ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location == 0);
}

#pragma mark -
#pragma mark - Settings Methods
- (void)settingsTap:(id)sender {
    //planing Interstitial Ads, and will show it later
    [self planInterstitialAds];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notification", @"") message:NSLocalizedString(@"InterstitialAdsNote", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

#pragma mark -
#pragma mark - UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) { //cancel
        //show Interstitial Ads
        [self layoutInterstitialAds];
    }
    else if(buttonIndex == 1) { // others
        //...
    }
}

#pragma mark -
#pragma mark - Orientation Events
- (void)updateOrientation:(NSNotification*)notification {
    sizeClient = clientBounds().size;
    _btnSetting.center = CGPointMake(sizeClient.width / 2, sizeClient.height / 2);
    
    [self destroyAds];
    [self planAds];
}

// for iOS6.0+
//-------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

-(BOOL)shouldAutorotate{
    return YES;
}
//-------------------------------------------------------

// for iOS6.0-
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark - LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self detectHardware];
    sizeClient = clientBounds().size;
    
    if(isiPad) {
        MY_BANNER_UNIT_ID = @"ca-app-pub-8892462307136994/5788642030";
    }
    else {
        MY_BANNER_UNIT_ID = @"ca-app-pub-8892462307136994/4311908836";
    }
    sizeClient = clientBounds().size;
    
    [self planAds];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0]];
    
    //UI works
    _btnSetting = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [_btnSetting addTarget:self action:@selector(settingsTap:) forControlEvents:UIControlEventTouchUpInside];
    _btnSetting.center = CGPointMake(sizeClient.width / 2, sizeClient.height / 2);
    [self.view addSubview:_btnSetting];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //check if we still have un-showed interstitial ad
    //检测看看是还有未展示广告
    if(!isInterstitialAdUIReady)
        [self setInterstitialAdUItoReady];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [super dealloc];
}


#pragma mark -
#pragma mark - Fusion Ads: iAd + AdMob ===================================

#pragma mark -
#pragma mark - BannerView Ad Controll (横幅广告调用控制)
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

- (BOOL)isiAdAvailable {
    bool result = NO;
    
    //https://developer.apple.com/news/
    //https://developer.apple.com/news/?id=08262014b
    //http://advertising.apple.com/tools/iad-workbench/
    //
    // August 26, 2014
    // You can now promote your apps in 16 countries or regions on the iAd App Network.
    //
    // Availability
    // iAd Workbench is available to promote products in Australia, Austria, Belgium, Canada, Denmark, Finland, France, Germany, Hong Kong, Ireland, Italy, Japan, Luxembourg, Mexico, Netherlands, New Zealand, Norway, Poland, Russia, Spain, Sweden, Switzerland, Taiwan, United Kingdom, and United States.
    
    // way 1:
    // ==========================================================================
    //NSLog(@"TimeZone:%@",[[NSTimeZone localTimeZone] name]);
    //if([self isiAdSupported]
    //   && ([[[NSTimeZone localTimeZone] name] rangeOfString:@"America/"].location == 0
    //       || [[[NSTimeZone localTimeZone] name] rangeOfString:@"Pacific/"].location == 0
    //       || [[[NSTimeZone localTimeZone] name] rangeOfString:@"Europe/"].location == 0
    //       || [[[NSTimeZone localTimeZone] name] rangeOfString:@"Asia/Tokyo"].location == 0))
    //{
    //    result = YES;
    //}
    
    // way 2:
    // ==========================================================================
    //        地区：NSLocal.localeIdentifier
    //------------------------------------------------------------------------------------
    //        美国：en_US，美国边远小岛：en_UM，美属萨摩亚：en_AS，美属维京群岛：en_VI，夏威夷：haw_US，彻罗基：chr_US，关岛：en_GU，美国西班牙文：es_US
    //2010.12 英国：en_GB，凯尔特：kw_GB，马恩岛：gv_GB，威尔士：cy_GB，
    //        法国：fr_FR，法属圭亚那：fr_GF，布里多尼：br_FR，
    //2011.1  德国：de_DE
    //2011.?  日本：ja_JP
    //2012.12 加拿大：en_CA，加拿大法文：fr_CA
    //        意大利：it_IT
    //        西班牙：es_ES，巴斯克：eu_ES，加利西亚：gl_ES，加泰罗尼亚：ca_ES，
    //2013.2  澳大利亚：en_AU，
    //        新西兰：en_NZ，
    //2013.12 墨西哥：es_MX，
    
    //??????? 奥地利(Austria)：_AT
    //??????? 比利时(Belgium)：_BE
    //??????? 丹麦(Denmark)：_DK
    //??????? 芬兰(Finland)：_FI
    //??????? 香港(Hong Kong)：_HK
    //??????? 台湾(Taiwan)：_TW
    //??????? 爱尔兰(Ireland)：_IE
    //??????? 卢森堡(Luxembourg)：_LU
    //??????? 荷兰(Netherlands)：_NL
    //??????? 挪威(Norway)：_NO
    //??????? 波兰(Poland)：_PL
    //??????? 瑞典(Sweden)：_SE
    
    //2014.8.26 俄罗斯(Russia)：ru_RU
    //          瑞士(Switzerland)：
    
    NSArray *arrCheck = [NSArray arrayWithObjects:
                         @"en_US", @"en_UM", @"en_AS", @"en_VI", @"haw_US", @"chr_US", @"en_GU",@"es_US", @"_US",
                         @"en_GB", @"kw_GB", @"gv_GB", @"cy_GB", @"_GB",
                         @"fr_FR", @"fr_GF", @"br_FR", @"_FR",
                         @"de_DE", @"_DE",
                         @"ja_JP",
                         @"en_CA", @"fr_CA", @"_CA",
                         @"it_IT", @"_IT",
                         @"es_ES", @"eu_ES", @"gl_ES", @"ca_ES", @"_ES",
                         @"en_AU", @"_AU",
                         @"en_NZ", @"_NZ",
                         @"es_MX", @"_MX",
                         @"_AT",
                         @"_BE",
                         @"_DK",
                         @"_FI",
                         @"_HK",
                         @"_TW",
                         @"_IE",
                         @"_LU",
                         @"_NL",
                         @"_NO",
                         @"_PL",
                         @"_SE",
                         @"ru_RU", @"uk_RU", @"_RU",
                         @"de_CH", @"_CH",
                         nil];
    
    NSString *localeFullId= [[NSLocale autoupdatingCurrentLocale] localeIdentifier];
    NSString *localeSuffixId = [localeFullId substringFromIndex:[localeFullId rangeOfString:@"_"].location];
    
    //NSLog(@"fullID=%@, sufffixID=%@", localeFullId, localeSuffixId);
    
    if([arrCheck indexOfObject:localeFullId] != NSNotFound || [arrCheck indexOfObject:localeSuffixId] != NSNotFound)
        result = YES;
    
    //testing
    //result = YES;
    
    return result;
}

// Set the origin of the adView frame per the selected size for the banner.
- (void)layoutGADBannerView {
    CGSize bannerCGSize = CGSizeFromGADAdSize(gAdView.adSize);
    CGRect frame = gAdView.frame;
    frame.origin.x = (sizeClient.width - bannerCGSize.width) / 2.0;
    frame.origin.y = sizeClient.height - bannerCGSize.height; // 0;
    //frame.origin.y = sizeClient.height - bannerCGSize.height;
    gAdView.frame = frame;
    if (gAdView.hidden) {
        gAdView.hidden = NO;
    }
}

- (void)layoutiAdBannerView:(BOOL)animated
{
    if(iOSVer < 6.0) {
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        } else {
            iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
        }
    }
    
    //CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = iAdView.frame;
    if (iAdView.bannerLoaded) {
        //contentFrame.size.height -= iAdView.frame.size.height;
        //bannerFrame.origin.y = contentFrame.size.height;
        bannerFrame.origin.y = sizeClient.height - iAdView.frame.size.height; //0;
    } else {
        //bannerFrame.origin.y = contentFrame.size.height;
        bannerFrame.origin.y += iAdView.frame.size.height;
    }
    
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        //_contentView.frame = contentFrame;
        //[_contentView layoutIfNeeded];
        iAdView.frame = bannerFrame;
    }];
}

- (void)planAds {
    is_iAdWillON = NO;
    is_gAdWillON = NO;
    
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
                
                gAdView = [[GADBannerView alloc] initWithFrame:CGRectZero];
                
                gAdView.layer.shadowOffset = CGSizeMake(5, 3);
                gAdView.layer.shadowOpacity = 0.9;
                gAdView.layer.shadowColor = [UIColor grayColor].CGColor;
                
                [gAdView.layer setMasksToBounds:YES];
                [gAdView.layer setCornerRadius:5.0];
                
                gAdView.adUnitID = MY_BANNER_UNIT_ID;
                gAdView.delegate = self;
                
                [gAdView setRootViewController:self];
                
                //ad size
                gAdView.adSize = [self sizeGADBanner];
                [self layoutGADBannerView];
                
                GADRequest * request = [GADRequest request];
                //request.testing = NO;
                [gAdView loadRequest:request];
            }
        }
        else {
            if(iAdView) {
                [iAdView removeFromSuperview];
                [iAdView release];
                iAdView = nil;
            }
            
            if(!iAdView) {
                // On iOS 6 ADBannerView introduces a new initializer, use it when available.
                if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
                    iAdView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
                } else {
                    iAdView = [[ADBannerView alloc] init];
                }
                iAdView.delegate = self;
                
                [iAdView.layer setMasksToBounds:YES];
                [iAdView.layer setCornerRadius:5.0f];
                
                iAdView.delegate = self;
                [self.view addSubview:iAdView];
                iAdView.hidden = YES; //will show later when iAd content arrived
            }
        }
    }
    else {
        if(gAdView) { // && is_gAdFailed) {  //(gAdView && is_gAdFailed)
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

- (void)tryGAdWheniAdFailed {
    iAdFailedCount = 0;
    is_gAdWillON = YES;
    
    if(is_gAdWillON) {
        if(!gAdView) {
            gAdView = [[GADBannerView alloc] initWithFrame:CGRectZero];
            
            gAdView.layer.shadowOffset = CGSizeMake(5, 3);
            gAdView.layer.shadowOpacity = 0.9;
            gAdView.layer.shadowColor = [UIColor grayColor].CGColor;
            
            [gAdView.layer setMasksToBounds:YES];
            [gAdView.layer setCornerRadius:5.0f];
            
            gAdView.adUnitID = MY_BANNER_UNIT_ID;
            gAdView.delegate = self;
            
            [gAdView setRootViewController:self];
            
            //ad size
            gAdView.adSize = [self sizeGADBanner];
            [self layoutGADBannerView];
            
            GADRequest * request = [GADRequest request];
            //request.testing = NO;
            [gAdView loadRequest:request];
        }
    }
}

- (void)tryiAdWhenGAdFailed {
    is_gAdFailed = YES;
    is_iAdWillON = YES;
    
    if(is_iAdWillON) {
        if(gAdView) {
            [gAdView removeFromSuperview];
            [gAdView release];
            gAdView = nil;
        }
        
        if(!iAdView) {
            // On iOS 6 ADBannerView introduces a new initializer, use it when available.
            if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
                iAdView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
            } else {
                iAdView = [[ADBannerView alloc] init];
            }
            iAdView.delegate = self;
            
            [iAdView.layer setMasksToBounds:YES];
            [iAdView.layer setCornerRadius:5.0f];
            
            iAdView.delegate = self;
            [self.view addSubview:iAdView];
            iAdView.hidden = YES; //will show later when iAd content arrived
        }
    }
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
#pragma mark - Interstitial Ad Controll (全幅广告调用控制)

- (void)destroyInterstitialAds {
    if(self.gAdFull) {
        [self.gAdFull release];
        self.gAdFull = nil;
    }
    
    if(self.iAdFull) {
        [self.iAdFull release];
        self.iAdFull = nil;
    }
    
    interstitialAdUnPresentCount = 0;
}

- (void)initInterstitialAds {
    //if can not get ads after apply 3 time, then switch an ad provider.
    //连接请求超过三次广告，未有反应的，则切换广告供应商
    if(interstitialAdApplyCount > 3) {
        interstitialAdApplyCount = 0;
        
        if(interstitialAdIndex == 0)
            interstitialAdIndex = 1;
        else
            interstitialAdIndex = 0;
    }
    
    if(interstitialAdIndex == 1 && ![self isiAdInterstitialSupported]) {
        interstitialAdIndex = 0;
    }
    
    NSLog(@"Current Apply Count = %d",interstitialAdApplyCount);
    
    interstitialAdApplyCount++;
    
    NSLog(@"Apply Count = %d, index = %d",interstitialAdApplyCount,interstitialAdIndex);
    
    if(interstitialAdIndex == 0) {
        if(self.gAdFull != nil && self.gAdFull.hasBeenUsed) {
            [self.gAdFull release];
            self.gAdFull = nil;
        }
        
        if(self.gAdFull == nil) {
            self.gAdFull = [[GADInterstitial alloc] init];
            self.gAdFull.adUnitID = @"ca-app-pub-8892462307136994/2961966430"; //Google Interstitial Ad unit id
            self.gAdFull.delegate = self;
        }
        [self.gAdFull loadRequest:[GADRequest request]];
    }
    else if(interstitialAdIndex == 1) {
        if(self.iAdFull != nil/* && self.iAdFull.loaded*/) {
            [self.iAdFull release];
            self.iAdFull = nil;
        }
        
        if(self.iAdFull == nil) {
            self.iAdFull = [[ADInterstitialAd alloc] init];
            self.iAdFull.delegate = self;
        }
        //auto load or need to request???
    }
}

//Interstitial Ad Did Request (unsed yet, 全屏广告已经请求，尚未启用)
- (void)interstitialAdDidRequest:(NSNotification*)notification {
    isInterstitialAdUIReady = YES;
    [self layoutInterstitialAds];
}

- (BOOL)isiAdInterstitialSupported {
    bool result = NO;
    if(isiPad)
        result = YES;
    else if(!isiPad && iOSVer >= 7.0f)
        result = YES;
    return result;
}

//just check and show what we got
//看看我们手上有哪家全屏就显示哪一家广告
- (void)layoutInterstitialAds {
    //if(interstitialAdIndex == 0) {
    if(self.gAdFull) {
        if(self.gAdFull.isReady) {
            [self.gAdFull presentFromRootViewController:self];
            [self setInterstitialAdUItoNotReady];
        }
    }
    //else if(interstitialAdIndex == 1) {
    if(self.iAdFull) {
        if(self.iAdFull.loaded) {
            [self.iAdFull presentFromViewController:self];
            [self setInterstitialAdUItoNotReady];
        }
    }
}

- (void)planInterstitialAds {
    //if we have un-showed ad, don't apply a newer one
    //如果我们有未展示全屏广告，则不再请求新广告
    if(interstitialAdUnPresentCount > 0) {
        NSLog(@"We have a un-showed interstitial ad.");
        return;
    }
    
    //otherwise apply a newer one
    //否则，请求一个新广告
    if([self isiAdInterstitialSupported] && [self isiAdAvailable])
        interstitialAdIndex = 1;
    else
        interstitialAdIndex = 0;
    
    [self initInterstitialAds];
}

- (void)replanInterstitialAds {
    [self destroyInterstitialAds];
    
    interstitialAdApplyCount = 0;
    
    interstitialAdIndex = 0;
    
    [self initInterstitialAds];
}

- (void)setInterstitialAdUItoNotReady {
    isInterstitialAdUIReady = NO;
    interstitialAdUnPresentCount--;
}

- (void)setInterstitialAdUItoReady {
    isInterstitialAdUIReady = YES;
    if(interstitialAdUnPresentCount > 0)
        [self layoutInterstitialAds];
}

#pragma mark -
#pragma mark - Google Admob Ads BannerView Degelate (谷歌横幅广告代理)
//============================= new Google AdMob Ads =============================
// Sent when an ad request loaded an ad.  This is a good opportunity to add this
// view to the hierarchy if it has not yet been added.  If the ad was received
// as a part of the server-side auto refreshing, you can examine the
// hasAutoRefreshed property of the view.
- (void)adViewDidReceiveAd:(GADBannerView *)view {
    NSLog(@"[GAD]: adViewDidReceiveAd");
    
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
    NSLog(@"[GAD]: adView: didFailToReceiveAdWithError:");
    //NSLog(@"err.Desc:%@",[error localizedDescription]);
	//if([error localizedRecoverySuggestion] != nil)
	//	NSLog(@"err.Sugg:%@",[error localizedRecoverySuggestion]);
	//if([error localizedFailureReason] != nil)
	//	NSLog(@"err.Reas:%@",[error localizedFailureReason]);
    
    if(is_gAdON) {
        is_gAdON = NO;
        [gAdView removeFromSuperview];
    }
    [gAdView release];
    gAdView = nil;
    
    isAdLoaded = NO;
    
    //做一次失败尝试
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
    NSLog(@"[GAD]: adViewWillPresentScreen");
}

// Sent just before dismissing a full screen view.
- (void)adViewWillDismissScreen:(GADBannerView *)adView {
    NSLog(@"[GAD]: adViewWillDismissScreen");
}

// Sent just after dismissing a full screen view.  Use this opportunity to
// restart anything you may have stopped as part of adViewWillPresentScreen:.
- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    NSLog(@"[GAD]: adViewDidDismissScreen");
}

// Sent just before the application will background or terminate because the
// user clicked on an ad that will launch another application (such as the App
// Store).  The normal UIApplicationDelegate methods, like
// applicationDidEnterBackground:, will be called immediately before this.
- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    NSLog(@"[GAD]: adViewWillLeaveApplication");
}

#pragma mark -
#pragma mark - Google Interstitial Ad(谷歌全屏广告) Request Lifecycle Notifications
/// Called when an interstitial ad request succeeded. Show it at the next transition point in your
/// application such as when transitioning between view controllers.
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad {
    NSLog(@"[GAD]: interstitialDidReceiveAd");
    
    //just got an interstitial ad loaded, hedge the counter
    //抵消同一广告供应商请求一数
    interstitialAdApplyCount--;
    
    interstitialAdUnPresentCount++;
}

/// Called when an interstitial ad request completed without an interstitial to
/// show. This is common since interstitials are shown sparingly to users.
- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"[GAD]: interstitial didFailToReceiveAdWithError: %@",error);
    
    //re-plan interstitial ad when request failed
    //当请求失败时，重新计划全屏广告
    [self replanInterstitialAds];
}

#pragma mark -
#pragma mark - Google Interstitial Ad(谷歌全屏广告) Display-Time Lifecycle Notifications

/// Called just before presenting an interstitial. After this method finishes the interstitial will
/// animate onto the screen. Use this opportunity to stop animations and save the state of your
/// application in case the user leaves while the interstitial is on screen (e.g. to visit the App
/// Store from a link on the interstitial).
- (void)interstitialWillPresentScreen:(GADInterstitial *)ad {
    NSLog(@"[GAD]: interstitialWillPresentScreen");
}

/// Called before the interstitial is to be animated off the screen.
- (void)interstitialWillDismissScreen:(GADInterstitial *)ad {
    NSLog(@"[GAD]: interstitialWillDismissScreen");
}

/// Called just after dismissing an interstitial and it has animated off the screen.
- (void)interstitialDidDismissScreen:(GADInterstitial *)ad {
    NSLog(@"[GAD]: interstitialDidDismissScreen");
    
    if(!isInterstitialAdUIReady)
        [self setInterstitialAdUItoReady];
}

/// Called just before the application will background or terminate because the user clicked on an
/// ad that will launch another application (such as the App Store). The normal
/// UIApplicationDelegate methods, like applicationDidEnterBackground:, will be called immediately
/// before this.
- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad {
    NSLog(@"[GAD]: interstitialWillLeaveApplication");
}

#pragma mark -
#pragma mark - iAd BannerView Delegate (苹果横幅广告代理)
// Cancels the current in-progress banner view action. This should only be used in cases where the
// user's attention is required immediately.
- (void)cancelBannerViewAction {
    NSLog(@"[iAd]: Banner cancel.");
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    NSLog(@"[iAd]: Banner loaded.");
    if (!is_iAdON)
    {
        [self layoutiAdBannerView:YES];
        
        is_iAdON = YES;
        banner.hidden = NO;
    }
    isAdLoaded = YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"[iAd]: Banner fail to receive");
    //NSLog(@"err.Desc:%@",[error localizedDescription]);
    //if([error localizedRecoverySuggestion] != nil)
    //	NSLog(@"err.Sugg:%@",[error localizedRecoverySuggestion]);
    //if([error localizedFailureReason] != nil)
    //	NSLog(@"err.Reas:%@",[error localizedFailureReason]);
    
    if(is_iAdON)
    {
        [self layoutiAdBannerView:YES];
        
        is_iAdON = NO;
        banner.hidden = YES;
    }
    
    iAdFailedCount++;
    
    if(iAdFailedCount == 2) {
        //某次加载失败后，是否会继续试图加载广告？
        //已经确认，某次失败后，仍然会继续加载广告，所以没有必要删除广告层
        //可以考虑iAd广告调用失败3次(指定次数)后开启AdMob广告
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
    NSLog(@"[iAd]: Banner view is beginning an ad action");
    return YES;
    
    //BOOL shouldExecuteAction = [self allowActionToRun]; // your application implements this method
    //if (!willLeave && shouldExecuteAction)
    //{
    //    // insert code here to suspend any services that might conflict with the advertisement
    //}
    //return shouldExecuteAction;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    NSLog(@"[iAd]: bannerViewActionDidFinish");
}

#pragma mark -
#pragma mark - iAd Interstitial Ad Delegate  (苹果全屏广告代理)
/*!
 * @method interstitialAdDidUnload:
 *
 * @discussion
 * When this method is invoked, if the application is using -presentInView:, the
 * content will be unloaded from the container shortly after this method is
 * called and no new content will be loaded. This may occur either as a result
 * of user actions or if the ad content has expired.
 *
 * In the case of an interstitial presented via -presentInView:, the layout of
 * the app should be updated to reflect that an ad is no longer visible. e.g.
 * by removing the view used for presentation and replacing it with another view.
 */
- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    NSLog(@"[iAd]: interstitialAdDidUnload");
    
    
    //it seems that this event does not fired
    //I use viewDidAppear instead of it
    //妙是有时候，并没有执行到这里，不知道为何，居然不知道广告页面离开的事件
    //我暂时在 viewDidAppear 事件中实现“沟通”
    if(!isInterstitialAdUIReady)
        [self setInterstitialAdUItoReady];
}

/*!
 * @method interstitialAd:didFailWithError:
 *
 * @discussion
 * Called when an error has occurred attempting to get ad content.
 *
 * @see ADError for a list of possible error codes.
 */
- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    NSLog(@"[iAd]: interstitialAd didFailWithError: %@",error);
    
    //re-plan interstitial ad when request failed
    //当请求失败时，重新计划全屏广告
    [self replanInterstitialAds];
}

//@optional

/*!
 * @method interstitialAdWillLoad:
 *
 * @discussion
 * Called when the interstitial has confirmation that an ad will be presented,
 * but before the ad has loaded resources necessary for presentation.
 */
- (void)interstitialAdWillLoad:(ADInterstitialAd *)interstitialAd {
    NSLog(@"[iAd]: interstitialAdWillLoad");
}

/*!
 * @method interstitialAdDidLoad:
 *
 * @discussion
 * Called when the interstitial ad has finished loading ad content. The delegate
 * should implement this method so it knows when the interstitial ad is ready to
 * be presented.
 */
- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd {
    NSLog(@"[iAd]: interstitialAdDidLoad");
    
    //just got an interstitial ad loaded, hedge the counter
    //抵消同一广告供应商请求一数
    interstitialAdApplyCount--;
    
    interstitialAdUnPresentCount++;
}

/*!
 * @method interstitialAdActionShouldBegin:willLeaveApplication:
 *
 * @discussion
 * Called when the user chooses to interact with the interstitial ad.
 *
 * The delegate may return NO to block the action from taking place, but this
 * should be avoided if possible because most ads pay significantly more when
 * the action takes place and, over the longer term, repeatedly blocking actions
 * will decrease the ad inventory available to the application.
 *
 * Applications should reduce their own activity while the advertisement's action
 * executes.
 */
- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd willLeaveApplication:(BOOL)willLeave {
    NSLog(@"[iAd]: interstitialAdActionShouldBegin: willLeaveApplication:");
    return YES;
}

/*!
 * @method interstitialAdActionDidFinish:
 * This message is sent when the action has completed and control is returned to
 * the application. Games, media playback, and other activities that were paused
 * in response to the beginning of the action should resume at this point.
 */
- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd {
    NSLog(@"[iAd]: interstitialAdActionDidFinish");
    
    if(!isInterstitialAdUIReady)
        [self setInterstitialAdUItoReady];
}
#pragma mark -
#pragma mark - Fusion Ads: iAd + AdMob ===================================

@end
