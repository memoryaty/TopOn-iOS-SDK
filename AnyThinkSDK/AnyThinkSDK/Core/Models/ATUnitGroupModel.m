//
//  ATUnitGroupModel.h
//  AnyThinkSDK
//
//  Created by Martin Lau on 11/04/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATUnitGroupModel.h"
#import "ATAdAdapter.h"
#import "Utilities.h"
extern NSString *const kUnitGroupBidInfoPriceKey;
extern NSString *const kUnitGroupBidInfoBidTokenKey;
extern NSString *const kUnitGroupBidInfoBidTokenExpireDateKey;
extern NSString *const kUnitGroupBidInfoBidTokenUsedFlagKey;


@interface ATUnitGroupModel()
@end
@implementation ATUnitGroupModel
-(instancetype) initWithDictionary:(NSDictionary *)dictionary {
    self = [super initWithDictionary:dictionary];
    if (self != nil) {
        _adapterClassString = dictionary[@"adapter_class"];//@"ATAdmobSplashAdapter"广告SDK类名
        _adapterClass = NSClassFromString(_adapterClassString);
        _capByDay = [dictionary[@"caps_d"] integerValue] == -1 ? NSIntegerMax : [dictionary[@"caps_d"] integerValue];//广告展示频次控制/天
        _capByHour = [dictionary[@"caps_h"] integerValue] == -1 ? NSIntegerMax : [dictionary[@"caps_h"] integerValue];//广告展示频次控制/小时
        _networkCacheTime = [dictionary[@"nw_cache_time"] doubleValue];//缓存有效时间
        _networkFirmID = [dictionary[@"nw_firm_id"] integerValue];
        _networkRequestNum = [dictionary[@"nw_req_num"] integerValue];
        _networkDataTimeout = [dictionary[@"n_d_t"] doubleValue];//  5.1.0 双回调数据超时(topon备注)
        _networkTimeout = [dictionary[@"nw_timeout"] doubleValue] / 1000.0f;//请求第三方广告超时时间
        _skipIntervalAfterLastLoadingFailure = [dictionary[@"nx_req_time"] doubleValue] / 1000.0f;//下发0
        _skipIntervalAfterLastBiddingFailure = [dictionary[@"bid_fail_interval"] doubleValue] / 1000.0f;
        _showingInterval = [dictionary[@"pacing"] doubleValue];
        _unitGroupID = [NSString stringWithFormat:@"%@", dictionary[@"ug_id"]];
        _unitID = [NSString stringWithFormat:@"%@", dictionary[@"unit_id"]];
        _price = [[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lf",[[NSString stringWithFormat:@"%@",dictionary[@"ecpm"]] doubleValue]]] stringValue];
        _ecpmLevel = [dictionary[@"ecpm_level"] integerValue];
        _content = [NSJSONSerialization JSONObjectWithData:[dictionary[@"content"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];//@{@"unit_id":@"ca-app-pub-3940256099942544/1033173712",@"orientation":@(2)}
        _adSize = [Utilities sizeFromString:[_content[@"size"] length] > 0 ? _content[@"size"] : [ATUnitGroupModel defaultSizeWithNetworkFirmID:_networkFirmID]];
        _headerBiddingRequestTimeout = [dictionary[@"hb_timeout"] doubleValue];//请求头部竞价超时时间
        _bidTokenTime = [dictionary[@"hb_t_c_t"] doubleValue] / 1000.0f;
        _headerBidding = [dictionary[@"header_bidding"] boolValue];//头部竞价,目前TopOn平台支持Mintegral的应用内头部竞价,这部分可以忽略
        _clickTkAddress = dictionary[@"t_c_u"];
        _clickTkDelayMin = [dictionary[@"t_c_u_min_t"] integerValue];
        _clickTkDelayMax = [dictionary[@"t_c_u_max_t"] integerValue];
        _statusTime = [dictionary[@"l_s_t"] doubleValue] / 1000.0f;
        _postsNotificationOnShow = [dictionary[@"s_sw"] boolValue];
        _postsNotificationOnClick = [dictionary[@"c_sw"] boolValue];
        NSString *precision = dictionary[@"precision"];
        _precision = _headerBidding ? @"exact" : ([precision isKindOfClass:[NSString class]] && [precision length] > 0 ? precision : @"publisher_defined");
    }
    return self;
}

+(NSString*)defaultSizeWithNetworkFirmID:(NSInteger)networkFirmID {
    NSString *sizeStr = @"320x50";
    if (networkFirmID == 22) {
        sizeStr = @"375x56";
    } else if (networkFirmID == 15) {
        sizeStr = @"640x100";
    }
    return sizeStr;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@", @{@"unit_group_id":_unitGroupID != nil ? _unitGroupID : @"", @"network_firm_id":@(_networkFirmID), @"adapter_class":_adapterClassString, @"ad_source_id":_unitID, @"price":_price}];
}
@end
