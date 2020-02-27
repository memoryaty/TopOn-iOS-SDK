//
//  ATYeahmobiInterstitialAdapter.m
//  AnyThinkYeahmobiInterstitialAdapter
//
//  Created by Martin Lau on 2018/10/16.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATYeahmobiInterstitialAdapter.h"
#import "ATYeahmobiInterstitialCustomEvent.h"
#import "ATAPI+Internal.h"
#import "Utilities.h"
#import "ATAppSettingManager.h"

@interface ATYeahmobiInterstitialAdapter()
@property(nonatomic, readonly) ATYeahmobiInterstitialCustomEvent *customEvent;
@end
@implementation ATYeahmobiInterstitialAdapter
+(BOOL) adReadyWithCustomObject:(NSString*)customObject info:(NSDictionary*)info {
    return customObject != nil && [[NSClassFromString(@"CTService") shareManager] mraidInterstitialIsReady];
}

+(void) showInterstitial:(ATInterstitial*)interstitial inViewController:(UIViewController*)viewController delegate:(id<ATInterstitialDelegate>)delegate {
    interstitial.customEvent.delegate = delegate;
    [[NSClassFromString(@"CTService") shareManager] mraidInterstitialShow];
    //No show delegate's availabel for Yeahmobi interstitial, so show will be tracked here.
    [(ATYeahmobiInterstitialCustomEvent*)interstitial.customEvent handleShow];
}

-(instancetype) initWithNetworkCustomInfo:(NSDictionary *)info {
    self = [super init];
    if (self != nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (![[ATAPI sharedInstance] initFlagForNetwork:kNetworkNameYeahmobi]) {
                [[ATAPI sharedInstance] setInitFlagForNetwork:kNetworkNameYeahmobi];
                [[ATAPI sharedInstance] setVersion:[[NSClassFromString(@"CTService") shareManager] getSDKVersion] forNetwork:kNetworkNameYeahmobi];
                [[NSClassFromString(@"CTService") shareManager] loadRequestGetCTSDKConfigBySlot_id:info[@"slot_id"]];
                
                if ([[ATAPI sharedInstance].networkConsentInfo containsObjectForKey:kNetworkNameYeahmobi]) {
                    if ([[ATAPI sharedInstance].networkConsentInfo isKindOfClass:[NSDictionary class]] && [[ATAPI sharedInstance].networkConsentInfo[kYeahmobiGDPRConsentTypeKey] isKindOfClass:[NSString class]] && [[ATAPI sharedInstance].networkConsentInfo[kYeahmobiGDPRConsentValueKey] isKindOfClass:[NSString class]]) {
                        [[NSClassFromString(@"CTService") shareManager] uploadConsentValue:[ATAPI sharedInstance].networkConsentInfo[kYeahmobiGDPRConsentValueKey] consentType:[ATAPI sharedInstance].networkConsentInfo[kYeahmobiGDPRConsentTypeKey] complete:^(BOOL status){}];
                    }
                } else {
                    BOOL set = NO;
                    BOOL limit = [[ATAppSettingManager sharedManager] limitThirdPartySDKDataCollection:&set];
                    if (set) {
                        /**
                         consentValue: @"no" Nonpersonalized, @"yes" Personalized
                         */
                        [[NSClassFromString(@"CTService") shareManager] uploadConsentValue:limit ? @"no" : @"yes" consentType:@"GDPR" complete:^(BOOL status){}];
                    }
                }
            }
        });
    }
    return self;
}

-(void) loadADWithInfo:(id)info completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    if (NSClassFromString(@"CTService") != nil) {
        _customEvent = [[ATYeahmobiInterstitialCustomEvent alloc] initWithUnitID:info[@"slot_id"] customInfo:info];
        _customEvent.requestCompletionBlock = completion;
        [[NSClassFromString(@"CTService") shareManager] preloadMRAIDInterstitialAdWithSlotId:info[@"slot_id"] delegate:_customEvent isTest:NO];
    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:@"AT has failed to load interstitial ad.", NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"Yeahmobi"]}]);
    }
}
@end
