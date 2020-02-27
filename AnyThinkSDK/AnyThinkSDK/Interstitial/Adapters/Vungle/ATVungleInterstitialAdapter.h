//
//  ATVungleInterstitialAdapter.h
//  AnyThinkVungleInterstitialAdapter
//
//  Created by Martin Lau on 2018/10/9.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kVungleInterstitialLoadNotification;
extern NSString *const kVungleInterstitialShowNotification;
extern NSString *const kVungleInterstitialCloseNotification;
extern NSString *const kVungleInterstitialNotificationUserInfoPlacementIDKey;
extern NSString *const kVungleInterstitialNotificationUserInfoClickFlagKey;
@interface ATVungleInterstitialAdapter : NSObject
@end

@protocol ATVungleSDKDelegate;
@protocol ATVungleSDK<NSObject>
@property (strong) NSDictionary *userData;
@property (nullable, strong) id<ATVungleSDKDelegate> delegate;
@property (assign) BOOL muted;
@property (atomic, readonly, getter=isInitialized) BOOL initialized;
+ (instancetype)sharedSDK;
- (void)updateConsentStatus:(NSInteger)status consentMessageVersion:(NSString *)version;
- (BOOL)startWithAppId:(nonnull NSString *)appID error:(NSError **)error;
- (BOOL)playAd:(UIViewController *)controller options:(nullable NSDictionary *)options placementID:(nullable NSString *)placementID error:( NSError *__autoreleasing _Nullable *_Nullable)error;
- (BOOL)isAdCachedForPlacementID:(nonnull NSString *)placementID;
- (BOOL)loadPlacementWithID:(NSString *)placementID error:(NSError **)error;
@end

@protocol ATVungleViewInfo<NSObject>
@property (nonatomic, readonly) NSNumber *completedView;
@property (nonatomic, readonly) NSNumber *playTime;
@property (nonatomic, readonly) NSNumber *didDownload;
@end

@protocol ATVungleSDKDelegate <NSObject>
@optional
- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID error:(nullable NSError *)error;
- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID;
- (void)vungleWillCloseAdWithViewInfo:(nonnull id<ATVungleViewInfo>)info placementID:(nonnull NSString *)placementID;
- (void)vungleDidCloseAdWithViewInfo:(nonnull id<ATVungleViewInfo>)info placementID:(nonnull NSString *)placementID;
- (void)vungleSDKDidInitialize;
- (void)vungleSDKFailedToInitializeWithError:(NSError *)error;
@end
NS_ASSUME_NONNULL_END
