//
//  ATInmobiInterstitialAdapter.h
//  AnyThinkInmobiInterstitialAdapter
//
//  Created by Martin Lau on 2018/10/8.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ATIMInterstitialAnimationType) {
    kATIMInterstitialAnimationTypeCoverVertical,
    kATIMInterstitialAnimationTypeFlipHorizontal,
    kATIMInterstitialAnimationTypeNone
};
@interface ATInmobiInterstitialAdapter : NSObject
@property (nonatomic,copy) void (^metaDataDidLoadedBlock)(void);
@end

@protocol ATIMSdk<NSObject>
+(NSString *)getVersion;
+(void)initWithAccountID:(NSString *)accountID andCompletionHandler:(void (^)(NSError * ))completionBlock;
+(void) updateGDPRConsent:(NSDictionary *)consentDictionary;
@end

@protocol ATIMInterstitialDelegate;
@protocol ATIMInterstitial<NSObject>
@property (nonatomic, weak) id<ATIMInterstitialDelegate> delegate;
@property (nonatomic, strong) NSString* keywords;
@property (nonatomic, strong) NSDictionary* extras;
@property (nonatomic, strong, readonly) NSString* creativeId;
-(instancetype)initWithPlacementId:(long long)placementId;
-(instancetype)initWithPlacementId:(long long)placementId delegate:(id<ATIMInterstitialDelegate>)delegate;
-(void)load;
-(BOOL)isReady;
-(void)showFromViewController:(UIViewController *)viewController;
-(void)showFromViewController:(UIViewController *)viewController withAnimation:(ATIMInterstitialAnimationType)type;
- (NSDictionary *)getAdMetaInfo;
@end

@protocol ATIMInterstitialDelegate<NSObject>
@end

NS_ASSUME_NONNULL_END
