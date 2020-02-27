//
//  ATPlacementModel.m
//  AnyThinkSDK
//
//  Created by Martin Lau on 11/04/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATPlacementModel.h"

NSString *const kPlacementModelCacheDateKey = @"placement_cache_date";
@interface ATPlacementModel()
@property (nonatomic, readonly) dispatch_queue_t unit_group_by_request_id_access_queue;
@property(nonatomic, readonly) NSMutableDictionary<NSString*, NSArray<ATUnitGroupModel*>*>* unitGroupsByRequestID;
@end
@implementation ATPlacementModel
-(instancetype) initWithDictionary:(NSDictionary *)dictionary placementID:(NSString*)placementID {
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        _placementID = placementID;
        _format = [dictionary[@"format"] integerValue];
        _adDeliverySwitch = [dictionary[@"ad_delivery_sw"] boolValue];
        _groupID = [dictionary[@"gro_id"] integerValue];
        _refresh = [dictionary[@"refresh"] boolValue];
        _autoRefresh = [dictionary[@"auto_refresh"] boolValue];
        _autoRefreshInterval = [dictionary[@"auto_refresh_time"] doubleValue] / 1000.0f;
        _maxConcurrentRequestCount = [dictionary[@"req_ug_num"] integerValue];
        _psID = dictionary[@"ps_id"];
        _sessionID = dictionary[@"session_id"];
        _showType = [dictionary[@"show_type"] integerValue] < 2 ? [dictionary[@"show_type"] integerValue] : 0;
        _unitCapsByDay = [dictionary[@"unit_caps_d"] integerValue] == -1 ? NSIntegerMax : [dictionary[@"unit_caps_d"] integerValue];
        _unitCapsByHour = [dictionary[@"unit_caps_h"] integerValue] == -1 ? NSIntegerMax : [dictionary[@"unit_caps_h"] integerValue];
        _unitPacing = [dictionary[@"unit_pacing"] doubleValue];
        _wifiAutoSwitch = [dictionary[@"wifi_auto_sw"] boolValue];
        _offerLoadingTimeout = [dictionary[@"s_t"] doubleValue];
        _statusValidDuration = [dictionary[@"l_s_t"] doubleValue];
        _asid = dictionary[@"asid"];
        _trafficGroupID = dictionary[@"t_g_id"];
        _usesDefaultMyOffer = [dictionary[@"u_n_f_sw"] boolValue];
        _autoloadingEnabled = [dictionary[@"ra"] boolValue];
        if ([dictionary[@"tp_ps"] isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *tppsDict = [NSMutableDictionary dictionaryWithDictionary:dictionary[@"tp_ps"]];
            tppsDict[@"pucs"] = dictionary[@"pucs"];
            _extra = [[ATPlacementModelExtra alloc] initWithDictionary:tppsDict];
        }
        _updateTolerateInterval = [dictionary[@"ps_ct_out"] doubleValue] / 1000.0f;
        _cacheValidDuration = [dictionary[@"ps_ct"] doubleValue] / 1000.0f;
        _cacheDate = dictionary[kPlacementModelCacheDateKey];
        _cachesPlacementSetting = [dictionary[@"pucs"] boolValue];
        
        NSMutableArray<ATUnitGroupModel*>* unitGroups = [NSMutableArray<ATUnitGroupModel*> array];
        NSArray<NSDictionary*>* unitGroupDicts = dictionary[@"ug_list"];
        [unitGroupDicts enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [unitGroups addObject:[[ATUnitGroupModel alloc] initWithDictionary:obj]];
        }];
        _unitGroups = unitGroups;
        
        NSMutableArray<ATUnitGroupModel*>* headerBiddingUnitGroups = [NSMutableArray<ATUnitGroupModel*> array];
        NSArray<NSDictionary*>* headerBiddingUnitGroupDicts = dictionary[@"hb_list"];
        [headerBiddingUnitGroupDicts enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableDictionary *unitGroupDict = [NSMutableDictionary dictionaryWithDictionary:obj];
            unitGroupDict[@"header_bidding"] = @YES;
            [headerBiddingUnitGroups addObject:[[ATUnitGroupModel alloc] initWithDictionary:unitGroupDict]];
        }];
        _headerBiddingUnitGroups = headerBiddingUnitGroups;
        
        _headerBiddingRequestTimeout = [[_headerBiddingUnitGroups valueForKeyPath:@"@max.headerBiddingRequestTimeout"] doubleValue];
        
        _unitGroupsByRequestID = [NSMutableDictionary<NSString*, NSArray<ATUnitGroupModel*>*> dictionary];
        _unit_group_by_request_id_access_queue = dispatch_queue_create("com.anythink.unitGroupsByRequestIDAccessingQueue", DISPATCH_QUEUE_SERIAL);
        
        _preloadMyOffer = [dictionary[@"p_m_o"] boolValue];
        _myOfferSetting = [[ATMyOfferSetting alloc] initWithDictionary:dictionary[@"m_o_s"]];
        NSMutableArray<ATMyOfferOfferModel*>* offers = [NSMutableArray<ATMyOfferOfferModel*> array];
        NSArray<NSDictionary*>* offerDicts = dictionary[@"m_o"];
        NSDictionary *placeHolders = dictionary[@"m_o_ks"];
        [offerDicts enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ATMyOfferOfferModel *offerModel = [[ATMyOfferOfferModel alloc] initWithDictionary:obj placeholders:placeHolders];
            if (offerModel != nil) { [offers addObject:offerModel]; }
        }];
        _offers = offers;
    }
    return self;
}

-(NSArray<ATUnitGroupModel*>*)unitGroupsForRequestID:(NSString*)requestID {
    __block NSArray<ATUnitGroupModel*>* unitGroups = nil;
    dispatch_sync(_unit_group_by_request_id_access_queue, ^{ unitGroups = _unitGroupsByRequestID[requestID]; });
    return unitGroups;
}

-(void) updateUnitGroups:(NSArray<ATUnitGroupModel*>*)unitGroups forRequestID:(NSString*)requestID {
    if (requestID != nil && [unitGroups count] > 0) { dispatch_async(_unit_group_by_request_id_access_queue, ^{ _unitGroupsByRequestID[requestID] = unitGroups; }); }
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@", @{@"placement_id":_placementID != nil ? _placementID : @"", @"unit_group_ids":[_unitGroups mutableArrayValueForKey:@"unitGroupID"] != nil ? [_unitGroups mutableArrayValueForKey:@"unitGroupID"] : @[]}];
}

/**
 * Using NSClassFromString to walk around the dependency on Native framework.
 */
-(Class) adManagerClass {
    NSMutableDictionary<NSNumber*, Class> *classes = [NSMutableDictionary<NSNumber*, Class> dictionary];
    if (NSClassFromString(@"ATNativeADOfferManager") != nil) classes[@0] = NSClassFromString(@"ATNativeADOfferManager");
    if (NSClassFromString(@"ATRewardedVideoManager") != nil) classes[@1] = NSClassFromString(@"ATRewardedVideoManager");
    if (NSClassFromString(@"ATBannerManager") != nil) classes[@2] = NSClassFromString(@"ATBannerManager");
    if (NSClassFromString(@"ATInterstitialManager") != nil) classes[@3] = NSClassFromString(@"ATInterstitialManager");
    if (NSClassFromString(@"ATSplashManager") != nil) classes[@4] = NSClassFromString(@"ATSplashManager");
    return classes[@(self.format)];
}
@end

@implementation ATPlacementModelExtra
-(instancetype) initWithDictionary:(NSDictionary *)dictionary {
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        _cachesPlacementSetting = [dictionary[@"pucs"] boolValue];
        _defaultAdSourceLoadingDelay = [dictionary[@"apdt"] doubleValue] / 1000.0f;
        _defaultNetworkFirmID = [dictionary[@"aprn"] integerValue];
        _usesServerSettings = [dictionary[@"puas"] boolValue];
        _countdown = [dictionary[@"cdt"] integerValue] / 1000.0f;
        _allowsSkip = [dictionary[@"ski_swt"] boolValue];
        _closeAfterCountdownElapsed = [dictionary[@"aut_swt"] boolValue];
    }
    return self;
}
@end
