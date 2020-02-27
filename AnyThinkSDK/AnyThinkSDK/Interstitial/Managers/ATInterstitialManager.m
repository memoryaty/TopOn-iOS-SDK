//
//  ATInterstitialManager.m
//  AnyThinkInterstitial
//
//  Created by Martin Lau on 21/09/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATInterstitialManager.h"
#import "ATThreadSafeAccessor.h"
#import "ATInterstitial.h"
#import "ATPlacementModel.h"
#import "ATUnitGroupModel.h"
#import "ATCapsManager.h"
#import "ATInterstitialAdapter.h"
#import "ATAdStorageUtility.h"
NSString *const kInterstitialAssetsUnitIDKey = @"unit_id";
NSString *const kInterstitialAssetsCustomEventKey = @"custom_event";
@interface ATInterstitialManager()
@property(nonatomic, readonly) NSMutableDictionary *statusStorage;
@property(nonatomic, readonly) NSMutableDictionary *interstitialStorage;
@property(nonatomic, readonly) ATSerialThreadSafeAccessor *interstitialStorageAccessor;

@property(nonatomic, readonly) ATThreadSafeAccessor *firstLoadFlagStorageAccessor;
@property(nonatomic, readonly) NSMutableDictionary<NSString*, NSNumber*> *firstLoadFlagStorage;
@end
@implementation ATInterstitialManager
+(instancetype) sharedManager {
    static ATInterstitialManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ATInterstitialManager alloc] init];
    });
    return sharedManager;
}

-(instancetype) init {
    self = [super init];
    if (self != nil) {
        _statusStorage = [NSMutableDictionary new];
        _interstitialStorage = [NSMutableDictionary new];
        _interstitialStorageAccessor = [ATSerialThreadSafeAccessor new];
        
        _firstLoadFlagStorageAccessor = [ATThreadSafeAccessor new];
        _firstLoadFlagStorage = [NSMutableDictionary<NSString*, NSNumber*> dictionary];
    }
    return self;
}

#pragma mark - video management
static NSString *const interstitialsKey = @"interstitials";
static NSString *const requestIDKey = @"request_id";
-(NSInteger) highestPriorityOfShownAdInPlacementID:(NSString *)placementID requestID:(NSString *)requestID {
    __weak typeof(self) weakSelf = self;
    return [[_interstitialStorageAccessor readWithBlock:^id{ return @([ATAdStorageUtility highestPriorityOfShownAdInStorage:weakSelf.interstitialStorage placementID:placementID requestID:requestID]);}] integerValue];
}

-(BOOL) inspectAdSourceStatusWithPlacementModel:(ATPlacementModel*)placementModel activeUnitGroups:(NSArray<ATUnitGroupModel*>*)activeUnitGroups unitGroup:(ATUnitGroupModel*)unitGroup requestID:(NSString*)requestID extraInfo:(NSArray<NSDictionary*>*__autoreleasing*)extraInfo {
    __weak typeof(self) weakSelf = self;
    return [[_interstitialStorageAccessor readWithBlock:^id{
        BOOL status = [ATAdStorageUtility adSourceStatusInStorage:weakSelf.statusStorage placementModel:placementModel unitGroup:unitGroup];
        if (status) { [ATAdStorageUtility renewOffersWithPlacementModel:placementModel activeUnitGroups:activeUnitGroups requestID:requestID inStatusStorage:weakSelf.statusStorage offerStorate:weakSelf.interstitialStorage extraInfo:extraInfo]; }
        return @(status);
    }] boolValue];
}

-(BOOL) adSourceStatusInPlacementModel:(ATPlacementModel*)placementModel unitGroup:(ATUnitGroupModel*)unitGroup {
    __weak typeof(self) weakSelf = self;
    return [[_interstitialStorageAccessor readWithBlock:^id{ return @([ATAdStorageUtility adSourceStatusInStorage:weakSelf.statusStorage placementModel:placementModel unitGroup:unitGroup]); }] boolValue];
}

-(void) invalidateStatusForAd:(id<ATAd>)ad {
    __weak typeof(self) weakSelf = self;
    [_interstitialStorageAccessor writeWithBlock:^{ [ATAdStorageUtility invalidateStatusForAd:ad inStatusStorage:weakSelf.statusStorage]; }];
}

-(void) addAdWithADAssets:(NSDictionary*)assets withPlacementSetting:(ATPlacementModel*)placementModel unitGroup:(ATUnitGroupModel*)unitGroup requestID:(NSString*)requestID {
    ATInterstitial *interstitial = [[ATInterstitial alloc] initWithPriority:[placementModel.unitGroups indexOfObject:unitGroup] placementModel:placementModel requestID:requestID assets:assets unitGroup:unitGroup];
    __weak typeof(self) weakSelf = self;
    [_interstitialStorageAccessor writeWithBlock:^{
        [ATAdStorageUtility saveAd:interstitial toStorage:weakSelf.interstitialStorage requestID:interstitial.requestID];
        [ATAdStorageUtility saveAd:interstitial toStatusStorage:weakSelf.statusStorage];
    }];
}

-(ATInterstitial*) interstitialForPlacementID:(NSString*)placementID extra:(NSDictionary* __autoreleasing*)extra {
    return [self interstitialForPlacementID:placementID invalidateStatus:NO extra:extra];
}

-(ATInterstitial*) interstitialForPlacementID:(NSString*)placementID invalidateStatus:(BOOL)invalidateStatus extra:(NSDictionary* __autoreleasing*)extra {
    __weak typeof(self) weakSelf = self;
    return [_interstitialStorageAccessor readWithBlock:^id{
        ATInterstitial *interstitial = [ATAdStorageUtility adInStorage:weakSelf.interstitialStorage statusStorage:weakSelf.statusStorage forPlacementID:placementID extra:extra];
        if (invalidateStatus) { [ATAdStorageUtility invalidateStatusForAd:interstitial inStatusStorage:weakSelf.statusStorage]; }
        return interstitial;
    }];
}

-(NSArray<id<ATAd>>*) adsWithPlacementID:(NSString*)placementID {
    NSMutableArray<id<ATAd>>* ads = [NSMutableArray<id<ATAd>> array];
    ATInterstitial *interstitial = [[ATInterstitialManager sharedManager] interstitialForPlacementID:placementID extra:nil];
    if (interstitial != nil) { [ads addObject:interstitial]; }
    return ads;
}

-(void) clearCache {
    [_interstitialStorageAccessor writeWithBlock:^{ [_interstitialStorage removeAllObjects]; }];
}

-(void) clearCahceForPlacementID:(NSString*)placementID {
    [_interstitialStorageAccessor writeWithBlock:^{ [_interstitialStorage removeObjectForKey:placementID]; }];
}

-(void) removeAdForPlacementID:(NSString*)placementID unitGroupID:(NSString*)unitGroupID {
    [_interstitialStorageAccessor writeWithBlock:^{ [ATAdStorageUtility removeAdForPlacementID:placementID unitGroupID:unitGroupID inStorage:_interstitialStorage]; }];
}

-(void) setFirstLoadFlagForNetwork:(NSString*)network {
    if ([network isKindOfClass:[NSString class]] && [network length] > 0) [_firstLoadFlagStorageAccessor writeWithBlock:^{ _firstLoadFlagStorage[network] = @YES; }];
}

-(BOOL) firstLoadFlagForNetwork:(NSString*)network {
    if ([network isKindOfClass:[NSString class]] && [network length] > 0) return [[_firstLoadFlagStorageAccessor readWithBlock:^id{ return _firstLoadFlagStorage[network]; }] boolValue];
    else return NO;
}

-(ATInterstitial*) interstitialWithPlacementID:(NSString*)placementID unitGroupID:(NSString*)unitGroupID {
    __weak typeof(self) weakSelf = self;
    NSArray<ATInterstitial*>* interstitials = (NSArray<ATInterstitial*>*)[_interstitialStorageAccessor readWithBlock:^id{
        return weakSelf.interstitialStorage[placementID][interstitialsKey];
    }];
    __block ATInterstitial *interstitial = nil;
    [interstitials enumerateObjectsUsingBlock:^(ATInterstitial * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.unitGroup.unitGroupID isEqualToString:unitGroupID]) {
            interstitial = obj;
            *stop = YES;
        }
    }];
    return interstitial;
}
@end
