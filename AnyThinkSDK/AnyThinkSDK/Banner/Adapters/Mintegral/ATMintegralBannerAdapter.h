//
//  ATMintegralBannerAdapter.h
//  AnyThinkSDK
//
//  Created by Topon on 2019/11/15.
//  Copyright © 2019 AnyThink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface ATMintegralBannerAdapter : NSObject
@end

typedef NS_ENUM(NSInteger, ATMTGUserPrivateType) {
    ATMTGUserPrivateType_ALL         = 0,
    ATMTGUserPrivateType_GeneralData = 1,
    ATMTGUserPrivateType_DeviceId    = 2,
    ATMTGUserPrivateType_Gps         = 3,
};

typedef NS_ENUM(NSInteger, ATMTGBool) {
    /**
     No
     */
    MTGBoolNo = -1,
    
    /**
     Unknown
     */
    MTGBoolUnknown = 0,
    
    /**
     Yes
     */
    MTGBoolYes = 1,
};
typedef NS_ENUM(NSInteger,ATMTGBannerSizeType) {
    /*Represents the fixed banner ad size - 320pt by 50pt.*/
    ATMTGStandardBannerType320x50,
    
    /*Represents the fixed banner ad size - 320pt by 90pt.*/
    ATMTGLargeBannerType320x90,
    
    /*Represents the fixed banner ad size - 300pt by 250pt.*/
    ATMTGMediumRectangularBanner300x250,
    
    /*if device height <=720,Represents the fixed banner ad size - 320pt by 50pt;
      if device height > 720,Represents the fixed banner ad size - 728pt by 90pt*/
    ATMTGSmartBannerType
};

@protocol ATMTGAdSize <NSObject>

+(CGSize)getSizeBySizeType:(ATMTGBannerSizeType)sizeType;
@end

@protocol ATMTGBiddingSDK<NSObject>
+ (NSString *)buyerUID;
@end

@protocol ATMTGSDK<NSObject>
+(instancetype) sharedInstance;
+(NSString *)sdkVersion;
- (void)setUserPrivateInfoType:(ATMTGUserPrivateType)type agree:(BOOL)agree;
- (void)setAppID:(nonnull NSString *)appID ApiKey:(nonnull NSString *)apiKey;
@property (nonatomic, assign) BOOL consentStatus;
@end

@protocol ATMTGBannerAdViewDelegate;
@protocol ATMTGBannerAdView <NSObject>
@property (nonatomic,assign) NSInteger autoRefreshTime;
@property (nonatomic) CGRect frame;
@property (nonatomic,assign) ATMTGBool showCloseButton;
@property (nonatomic,copy,readonly) NSString * _Nonnull unitId;
@property (nonatomic,weak,nullable) id <ATMTGBannerAdViewDelegate> delegate;
@property (nonatomic, weak) UIViewController * _Nullable  viewController;

- (nonnull instancetype)initBannerAdViewWithBannerSizeType:(ATMTGBannerSizeType)bannerSizeType
       placementId:(nullable NSString *)placementId
            unitId:(nonnull NSString *) unitId
rootViewController:(nullable UIViewController *)rootViewController;
- (void)loadBannerAd;
- (void)loadBannerAdWithBidToken:(nonnull NSString *)bidToken;
- (void)destroyBannerAdView;
@end

@protocol ATMTGBannerAdViewDelegate <NSObject>

- (void)adViewLoadSuccess:(id<ATMTGBannerAdView>)adView;
- (void)adViewLoadFailedWithError:(NSError *)error adView:(id<ATMTGBannerAdView>)adView;
- (void)adViewWillLogImpression:(id<ATMTGBannerAdView>)adView;
- (void)adViewDidClicked:(id<ATMTGBannerAdView>)adView;
- (void)adViewWillLeaveApplication:(id<ATMTGBannerAdView>)adView;
- (void)adViewWillOpenFullScreen:(id<ATMTGBannerAdView>)adView;
- (void)adViewCloseFullScreen:(id<ATMTGBannerAdView>)adView;
- (void)adViewClosed:(id<ATMTGBannerAdView>)adView;
@end

@protocol ATBannerMTGAdCustomConfig<NSObject>
+(instancetype)sharedInstance;
-(void)setCustomInfo:(NSString*)customInfo type:(NSInteger)type unitId:(NSString*)unitID;
@end

@protocol ATMTGBiddingResponse<NSObject>
@property (nonatomic,strong,readonly) NSError *error;
@property (nonatomic,assign,readonly) BOOL success;
@property (nonatomic,assign,readonly) NSString *price;
@property (nonatomic,copy,readonly) NSString *currency;
@property (nonatomic,copy,readonly) NSString *bidToken;
-(void)notifyWin;
-(void)notifyLoss:(NSInteger)reasonCode;
@end

@protocol ATMTGBiddingBannerRequestParameter <NSObject>
@property(nonatomic,copy,readonly)NSString *unitId;
@property(nonatomic,readonly)NSNumber *basePrice;
- (instancetype)initWithPlacementId:(nullable NSString *)placementId
        unitId:(nonnull NSString *) unitId
     basePrice:(nullable NSNumber *)basePrice
bannerSizeType:(ATMTGBannerSizeType)bannerSizeType;
@end

@protocol ATMTGBiddingRequest<NSObject>
+(void)getBidWithRequestParameter:(__kindof id<ATMTGBiddingBannerRequestParameter>)requestParameter completionHandler:(void(^)(id<ATMTGBiddingResponse> bidResponse))completionHandler;
@end
