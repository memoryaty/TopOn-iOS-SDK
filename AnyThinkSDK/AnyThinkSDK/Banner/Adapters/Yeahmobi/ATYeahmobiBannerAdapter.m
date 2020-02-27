//
//  ATYeahmobiBannerAdapter.m
//  AnyThinkYeahmobiBannerAdapter
//
//  Created by Martin Lau on 2018/10/16.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATYeahmobiBannerAdapter.h"
#import "ATYeahmobiBannerCustomEvent.h"
#import "ATAPI+Internal.h"
#import "Utilities.h"
#import "ATAppSettingManager.h"

@interface ATYeahmobiBannerAdapter()
@property(nonatomic, readonly) ATYeahmobiBannerCustomEvent *customEvent;
@end
@implementation ATYeahmobiBannerAdapter
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
                    if (set) { [[NSClassFromString(@"CTService") shareManager] uploadConsentValue:limit ? @"no" : @"yes" consentType:@"GDPR" complete:^(BOOL status){}]; }
                    
                }
            }
        });
    }
    return self;
}

-(void) loadADWithInfo:(id)info completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    if (NSClassFromString(@"CTService") != nil) {
        _customEvent = [[ATYeahmobiBannerCustomEvent alloc] initWithUnitID:info[@"slot_id"] customInfo:info];
        _customEvent.requestCompletionBlock = completion;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSClassFromString(@"CTService") shareManager] getMRAIDBannerAdWithSlot:info[@"slot_id"] delegate:self->_customEvent adSize:0 isTest:NO];
        });
    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:@"AT has failed to load banner ad.", NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"Yeahmobi"]}]);
    }
}
@end
