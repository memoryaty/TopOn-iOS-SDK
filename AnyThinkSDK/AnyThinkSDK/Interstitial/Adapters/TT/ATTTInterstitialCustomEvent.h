//
//  ATTTInterstitialCustomEvent.h
//  AnyThinkTTInterstitialAdapter
//
//  Created by Martin Lau on 25/09/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATInterstitialCustomEvent.h"
#import "ATTTInterstitialAdapter.h"
@interface ATTTInterstitialCustomEvent : ATInterstitialCustomEvent<BUInterstitialAdDelegate, BUFullscreenVideoAdDelegate, BUNativeExpresInterstitialAdDelegate>
@property (nonatomic)BOOL isFailed;
@end
