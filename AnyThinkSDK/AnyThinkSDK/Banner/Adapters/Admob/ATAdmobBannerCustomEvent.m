//
//  ATAdmobBannerCustomEvent.m
//  AnyThinkAdmobBannerAdapter
//
//  Created by Martin Lau on 19/09/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATAdmobBannerCustomEvent.h"
#import "Utilities.h"
#import "ATBannerManager.h"
#import "ATAd.h"
#import "ATPlacementModel.h"
#import "AnyThinkBanner.h"
#import "ATAgentEvent.h"

@implementation ATAdmobBannerCustomEvent
- (void)adViewDidReceiveAd:(id<ATGADBannerView>)bannerView {
    [ATLogger logMessage:@"ADMobBanner::adViewDidReceiveAd:" type:ATLogTypeExternal];
    NSMutableDictionary *assets = [NSMutableDictionary dictionaryWithObjectsAndKeys:bannerView, kBannerAssetsBannerViewKey, self, kBannerAssetsCustomEventKey, nil];
    if ([self.unitID length] > 0) assets[kBannerAssetsUnitIDKey] = self.unitID;
    [self handleAssets:assets];
}

- (void)adView:(id<ATGADBannerView>)bannerView didFailToReceiveAdWithError:(NSError*)error {
    [ATLogger logMessage:[NSString stringWithFormat:@"ADMobBanner::adView:didFailToReceiveAdWithError:%@", error] type:ATLogTypeExternal];
    [self handleLoadingFailure:error];
}

- (void)adViewWillPresentScreen:(id<ATGADBannerView>)bannerView {
    [ATLogger logMessage:@"ADMobBanner::adViewWillPresentScreen:" type:ATLogTypeExternal];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (self.banner.requestID != nil) { userInfo[kBannerNotificationUserInfoRequestIDKey] = self.banner.requestID; }
    [[NSNotificationCenter defaultCenter] postNotificationName:kBannerPresentModalViewControllerNotification object:nil userInfo:userInfo];
    if ([self.delegate respondsToSelector:@selector(bannerView:didClickWithPlacementID: extra:)]) {
        [self.delegate bannerView:self.bannerView didClickWithPlacementID:self.banner.placementModel.placementID extra:@{kATBannerDelegateExtraNetworkIDKey:@(self.banner.unitGroup.networkFirmID), kATBannerDelegateExtraAdSourceIDKey:self.banner.unitGroup.unitID != nil ? self.banner.unitGroup.unitID : @"",kATBannerDelegateExtraIsHeaderBidding:@(self.banner.unitGroup.headerBidding),kATBannerDelegateExtraPriority:@(self.priorityIndex),kATBannerDelegateExtraPrice:@(self.banner.unitGroup.price)}];
    }
    [self trackClick];
}

- (void)adViewWillDismissScreen:(id<ATGADBannerView>)bannerView {
    [ATLogger logMessage:@"ADMobBanner::adViewWillDismissScreen:" type:ATLogTypeExternal];
}

- (void)adViewDidDismissScreen:(id<ATGADBannerView>)bannerView {
    [ATLogger logMessage:@"ADMobBanner::adViewDidDismissScreen:" type:ATLogTypeExternal];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (self.banner.requestID != nil) { userInfo[kBannerNotificationUserInfoRequestIDKey] = self.banner.requestID; }
    [[NSNotificationCenter defaultCenter] postNotificationName:kBannerDismissModalViewControllerNotification object:nil userInfo:userInfo];
}

- (void)adViewWillLeaveApplication:(id<ATGADBannerView>)bannerView {
    [ATLogger logMessage:@"ADMobBanner::adViewWillLeaveApplication:" type:ATLogTypeExternal];
    [self trackClick];
    if ([self.delegate respondsToSelector:@selector(bannerView:didClickWithPlacementID: extra:)]) {
        [self.delegate bannerView:self.bannerView didClickWithPlacementID:self.banner.placementModel.placementID extra:@{kATBannerDelegateExtraNetworkIDKey:@(self.banner.unitGroup.networkFirmID), kATBannerDelegateExtraAdSourceIDKey:self.banner.unitGroup.unitID != nil ? self.banner.unitGroup.unitID : @"",kATBannerDelegateExtraIsHeaderBidding:@(self.banner.unitGroup.headerBidding),kATBannerDelegateExtraPriority:@(self.priorityIndex),kATBannerDelegateExtraPrice:@(self.banner.unitGroup.price)}];
    }
}
@end