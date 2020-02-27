//
//  ATFacebookBannerCustomEvent.m
//  AnyThinkFacebookBannerAdapter
//
//  Created by Martin Lau on 29/09/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATFacebookBannerCustomEvent.h"
#import "ATBannerManager.h"
#import "Utilities.h"
@implementation ATFacebookBannerCustomEvent
- (void)adViewDidClick:(id<ATFBAdView>)adView {
    [ATLogger logMessage:@"FacebookBanner::adViewDidClick" type:ATLogTypeExternal];
    [self trackClick];
    if ([self.delegate respondsToSelector:@selector(bannerView:didClickWithPlacementID: extra:)]) {
        [self.delegate bannerView:self.bannerView didClickWithPlacementID:self.banner.placementModel.placementID extra:@{kATBannerDelegateExtraNetworkIDKey:@(self.banner.unitGroup.networkFirmID), kATBannerDelegateExtraAdSourceIDKey:self.banner.unitGroup.unitID != nil ? self.banner.unitGroup.unitID : @"",kATBannerDelegateExtraIsHeaderBidding:@(self.banner.unitGroup.headerBidding),kATBannerDelegateExtraPriority:@(self.priorityIndex),kATBannerDelegateExtraPrice:@(self.banner.unitGroup.price)}];
    }
}

- (void)adViewDidFinishHandlingClick:(id<ATFBAdView>)adView {
    [ATLogger logMessage:@"FacebookBanner::adViewDidFinishHandlingClick" type:ATLogTypeExternal];
}

- (void)adViewDidLoad:(id<ATFBAdView>)adView {
    [ATLogger logMessage:@"FacebookBanner::adViewDidLoad" type:ATLogTypeExternal];
    NSMutableDictionary *assets = [NSMutableDictionary dictionaryWithObjectsAndKeys:adView, kBannerAssetsBannerViewKey, self, kBannerAssetsCustomEventKey, nil];
    if ([self.unitID length] > 0) assets[kBannerAssetsUnitIDKey] = self.unitID;
    [self handleAssets:assets];
}

- (void)adView:(id<ATFBAdView>)adView didFailWithError:(NSError *)error {
    [ATLogger logMessage:[NSString stringWithFormat:@"FacebookBanner::adView:didFailWithError:%@", error] type:ATLogTypeExternal];
    [self handleLoadingFailure:error];
}

- (void)adViewWillLogImpression:(id<ATFBAdView>)adView {
    [ATLogger logMessage:@"FacebookBanner::adViewWillLogImpression" type:ATLogTypeExternal];
}
@end
