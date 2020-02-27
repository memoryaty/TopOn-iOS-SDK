//
//  ATPlacementSettingManager.m
//  AnyThinkSDK
//
//  Created by Martin Lau on 09/04/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATPlacementSettingManager.h"
#import "ATNetworkingManager.h"
#import "ATAPI.h"
#import "Utilities.h"
#import "ATPlacementModel.h"
#import "ATThreadSafeAccessor.h"
#import "ATAdManager+Internal.h"
#import "ATLogger.h"
#import "ATAppSettingManager.h"
#import "ATAgentEvent.h"
@interface ATPlacementSettingManager()
@property(nonatomic, readonly) ATThreadSafeAccessor *placementSettingsAccessor;
@property(nonatomic, readonly) NSMutableDictionary<NSString*, ATPlacementModel*>* placementSettings;
//UpStatus
@property(nonatomic, readonly) NSMutableDictionary *placementStatusStorage;
@property(nonatomic, readonly) ATThreadSafeAccessor *placementStatusStorageAccessor;
//Error code records
/*
 {
    md5(app_id + app_key + placement_id): {
        error_code: error_code,
        date:2019.08.21 19:57
    }
 }
 */
@property(nonatomic, readonly) NSMutableDictionary* errorCodeRecords;
@property(nonatomic, readonly) ATThreadSafeAccessor *errorCodeRecordsAccessor;

/*
 {
    placement_id:request_id
 }
 */
@property(nonatomic, readonly) NSMutableDictionary<NSString*, NSString*> *latestRequestIDStorage;
@property(nonatomic, readonly) ATThreadSafeAccessor *latestRequestIDStorageAccessor;

/*
 {
    placement_id:{
        ps_id:ps_id,
        session_id:session_id
     }
 }
 */
@property(nonatomic, readonly) NSMutableDictionary<NSString*, NSDictionary<NSString*, NSString*>*> *sessionIDStorage;
@property(nonatomic, readonly) ATSerialThreadSafeAccessor *sessionIDStorageAccessor;

@property(nonatomic, readonly) NSMutableDictionary<NSString*, NSString*>* cappedMyOfferIDwithDateStorage;
@property(nonatomic, readonly) ATThreadSafeAccessor *cappedMyOfferIDwithDateStorageAccessor;
@end

static NSString *const kPlacementStegatryLoadingErrorDescription = @"AT SDK has failed to load placement stragety.";
static NSString *const kBase64Table1 = @"dMWnhbeyKr0J+IvLNOx3BFkEuml92/5fjSqGT7R8pZVciPHAstC4UXa6QDw1gozY";
static NSString *const kBase64Table2 = @"xZnV5k+DvSoajc7dRzpHLYhJ46lt0U3QrWifGyNgb9P1OIKmCEuq8sw/XMeBAT2F";
@implementation ATPlacementSettingManager
#pragma mark - init
+(instancetype) sharedManager {
    static ATPlacementSettingManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ATPlacementSettingManager alloc] init];
    });
    return sharedManager;
}

-(instancetype) init {
    self = [super init];
    if (self != nil) {
        _placementSettingsAccessor = [ATThreadSafeAccessor new];
        _placementSettings = [NSMutableDictionary<NSString*, ATPlacementModel*> dictionary];
        
        _placementStatusStorage = [NSMutableDictionary dictionary];
        _placementStatusStorageAccessor = [ATThreadSafeAccessor new];
        
        _errorCodeRecords = [NSMutableDictionary new];
        _errorCodeRecordsAccessor = [ATThreadSafeAccessor new];
        
        _latestRequestIDStorage = [NSMutableDictionary<NSString*, NSString*> dictionary];
        _latestRequestIDStorageAccessor = [ATThreadSafeAccessor new];
        
        _sessionIDStorage = [[NSMutableDictionary alloc] initWithContentsOfFile:[ATPlacementSettingManager sessionStoragePath]];
        if (![_sessionIDStorage isKindOfClass:[NSMutableDictionary class]]) { _sessionIDStorage = [NSMutableDictionary<NSString*, NSDictionary<NSString*, NSString*>*> dictionary]; }
        _sessionIDStorageAccessor = [ATSerialThreadSafeAccessor new];
        
        _cappedMyOfferIDwithDateStorage = [[NSMutableDictionary alloc] initWithContentsOfFile:[ATPlacementSettingManager cappedMyOfferIDwithDateArchivePath]];

        if (_cappedMyOfferIDwithDateStorage == nil) { _cappedMyOfferIDwithDateStorage = [NSMutableDictionary<NSString*,NSString*> dictionary]; }
        _cappedMyOfferIDwithDateStorageAccessor = [ATThreadSafeAccessor new];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[ATPlacementSettingManager placementSettingPath]]) { [[NSFileManager defaultManager] createDirectoryAtPath:[ATPlacementSettingManager placementSettingPath] withIntermediateDirectories:NO attributes:nil error:nil]; }
        [self loadPlacementSettingsFromDisk];
    }
    return self;
}

+(NSString*)cappedMyOfferIDwithDateArchivePath {
    return [[Utilities documentsPath] stringByAppendingPathComponent:@"com.anythink.MyOfferCappedID"];
}

+(BOOL) myOfferExhaustedInPlacementModel:(ATPlacementModel*)placementModel {
    NSMutableArray<NSString*>* myOfferIDs = [NSMutableArray arrayWithArray:[placementModel.offers mutableArrayValueForKey:@"offerID"]];
    NSMutableDictionary<NSString *,NSString*> *offersDic = [[ATPlacementSettingManager sharedManager] cappedMyOfferIDs];
    [offersDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [myOfferIDs removeObject:key];
    }];
    return [placementModel.offers count] > 0 && [myOfferIDs count] == 0;
}

-(void) addCappedMyOfferID:(NSString*)offerID {
    if ([offerID isKindOfClass:[NSString class]]) {
        __weak typeof(self) weakSelf = self;
        [_cappedMyOfferIDwithDateStorageAccessor writeWithBlock:^{
            weakSelf.cappedMyOfferIDwithDateStorage[offerID] = [ATPlacementSettingManager currentTimeStringWithFormat];
            [weakSelf.cappedMyOfferIDwithDateStorage writeToFile:[ATPlacementSettingManager cappedMyOfferIDwithDateArchivePath] atomically:YES];
        }];
    }
}

-(void) removeCappedMyOfferID:(NSString*)offerID {
    if ([offerID isKindOfClass:[NSString class]]) {
        __weak typeof(self) weakSelf = self;
        [_cappedMyOfferIDwithDateStorageAccessor writeWithBlock:^{
            [weakSelf.cappedMyOfferIDwithDateStorage removeObjectForKey:offerID];
            [weakSelf.cappedMyOfferIDwithDateStorage writeToFile:[ATPlacementSettingManager cappedMyOfferIDwithDateArchivePath] atomically:YES];
        }];
    }
}

-(NSMutableDictionary<NSString *,NSString*>*) cappedMyOfferIDs {
    __weak typeof(self) weakSelf = self;
    return [_cappedMyOfferIDwithDateStorageAccessor readWithBlock:^id{ return [weakSelf.cappedMyOfferIDwithDateStorage copy]; }];
}

+(NSString*)sessionStoragePath {
    return [[Utilities documentsPath] stringByAppendingPathComponent:@"com.anythink.sessionInfo"];
}

static NSString *const kSessionIDStoragePSIDKey = @"ps_id";
static NSString *const kSessionIDStorageSessionIDKey = @"session_id";
-(NSString*)sessionIDForPlacementID:(NSString*)placementID {
    NSString*(^GenSessionID)(NSString*psID) = ^NSString*(NSString *psID) {
        NSString *sessionID = nil;
        uint32_t random = 0;
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970] * 1000.0f;
        BOOL randomIncluded = NO;
        if ([ATAppSettingManager sharedManager].ATID != nil) {
            sessionID = [NSString stringWithFormat:@"%@%@%@", [ATAppSettingManager sharedManager].ATID, placementID, @(timestamp)].md5;
        } else {
            randomIncluded = YES;
            random = arc4random_uniform(10000000);
            sessionID = [NSString stringWithFormat:@"%@%@%@%@%@", [Utilities advertisingIdentifier], [Utilities idfv], placementID, @(random), @(timestamp)].md5;
        }
        _sessionIDStorage[placementID] = @{kSessionIDStoragePSIDKey:psID != nil ? psID : @"", kSessionIDStorageSessionIDKey:sessionID != nil ? sessionID : @""};
        [_sessionIDStorage writeToFile:[ATPlacementSettingManager sessionStoragePath] atomically:YES];
        NSMutableDictionary *extraInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:@2, kAgentEventExtraInfoGeneratedIDTypeKey, @((NSInteger)timestamp), kAgentEventExtraInfoIDGenerationTimestampKey, sessionID != nil ? sessionID : @"", kAgentEventExtraInfoSessionIDKey, psID != nil ? psID : @"", kAgentEventExtraInfoPSIDKey, placementID != nil ? placementID : @"", kAgentEventExtraInfoPlacementIDKey, nil];
        if (randomIncluded) { extraInfo[kAgentEventExtraInfoIDGenerationRandomNumberKey] = @(random); }
        [[ATAgentEvent sharedAgent] saveEventWithKey:kATAgentEventKeyPSIDSessionIDGeneration placementID:nil unitGroupModel:nil extraInfo:extraInfo];
        return sessionID;
    };
    return [_sessionIDStorageAccessor readWithBlock:^id{
        NSString *psID = [ATAPI sharedInstance].psID;
        NSString *sessionID = _sessionIDStorage[placementID][kSessionIDStorageSessionIDKey];
        if (sessionID == nil) {
            sessionID = GenSessionID(psID);
        } else {
            if (![psID isEqualToString:_sessionIDStorage[placementID][kSessionIDStoragePSIDKey]]) { sessionID = GenSessionID(psID); }
        }
        return sessionID;
    }];
}

-(void) loadPlacementSettingsFromDisk {
    __block NSDictionary *psidSetting = nil;
    __block NSTimeInterval timeoutInterval = CGFLOAT_MIN;
    [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[ATPlacementSettingManager placementSettingPath] error:nil] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = [[ATPlacementSettingManager placementSettingPath] stringByAppendingPathComponent:obj];
        NSDictionary *settings = nil;
        if ([NSDictionary respondsToSelector:@selector(dictionaryWithContentsOfURL:error:)]) {
            settings = [NSMutableDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
        } else {
            settings = [NSDictionary dictionaryWithContentsOfFile:path];;
        }
        NSDictionary<NSFileAttributeKey, id> * attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        if ([settings isKindOfClass:[NSDictionary class]]) {
            _placementSettings[obj] = [[ATPlacementModel alloc] initWithDictionary:settings placementID:obj];
            if (timeoutInterval < [[NSDate date] timeIntervalSinceDate:attr[NSFileModificationDate]]) {
                timeoutInterval = [[NSDate date] timeIntervalSinceDate:attr[NSFileModificationDate]];
                psidSetting = settings;
            }
        }
    }];
    [[ATAdManager sharedManager] setPSID:psidSetting[@"ps_id"] interval:[psidSetting[@"ps_id_timeout"] doubleValue] - timeoutInterval];
}

#pragma mark - placement setting accessing
/**
 The following placement setting accessing methods are thread-safe.
 */
-(void) clearAllPlacementSettings {
    [_placementSettingsAccessor writeWithBlock:^{ [_placementSettings removeAllObjects]; }];
}

/**
 placementModel will be added if one with the same placementID does not exist, otherwise it will be replaced.
 */
-(void) addNewPlacementSetting:(ATPlacementModel*)placementModel {
    [_placementSettingsAccessor writeWithBlock:^{ [_placementSettings setObject:placementModel forKey:placementModel.placementID]; }];
}

-(ATPlacementModel*) placementSettingWithPlacementID:(NSString*)placementID {
    return [_placementSettingsAccessor readWithBlock:^id{ return _placementSettings[placementID]; }];
}

+(void) savePlacementSettings:(NSDictionary*)settings forPlacementID:(NSString*)placementID {
    [settings writeToFile:[self placementSettingPathForPlacementID:placementID] atomically:YES];
}

+(NSString*) placementSettingPathForPlacementID:(NSString*)placementID {
    return [[self placementSettingPath] stringByAppendingPathComponent:placementID];
}

+(NSString*) placementSettingPath {
    return [[Utilities documentsPath] stringByAppendingPathComponent:@"PlacementSettings"];
}

#pragma mark - error code
NSString *ErrorCodeRecordsKey(NSString *appID, NSString *appKey, NSString *placementID) {
    return [NSString stringWithFormat:@"%@%@%@", placementID, appID, appKey].md5;
}

static NSString *errorCodeRecordsErrorCodeKey = @"error_code";
static NSString *errorCodeRecordsDateKey = @"date";
static NSInteger errorCodeSuccess = 0;
static NSInteger errorCodeDuration = 20 * 60;
-(void) setErrorCode:(NSInteger)errorCode forAppID:(NSString*)appID appKey:(NSString*)appKey placementID:(NSString*)placementID {
    [_errorCodeRecordsAccessor writeWithBlock:^{ _errorCodeRecords[ErrorCodeRecordsKey(appID, appKey, placementID)] = @{errorCodeRecordsDateKey:[NSDate date], errorCodeRecordsErrorCodeKey:@(errorCode)}; }];
}

-(NSInteger) errorCodeForAppID:(NSString*)appID appKey:(NSString*)appKey placementID:(NSString*)placementID {
    return [[_errorCodeRecordsAccessor readWithBlock:^id{
        NSInteger errorCode = errorCodeSuccess;
        NSDate *date = _errorCodeRecords[ErrorCodeRecordsKey(appID, appKey, placementID)][errorCodeRecordsDateKey];
        if (date != nil && [[NSDate date] timeIntervalSinceDate:date] < errorCodeDuration) { errorCode = [_errorCodeRecords[ErrorCodeRecordsKey(appID, appKey, placementID)][errorCodeRecordsErrorCodeKey] integerValue]; }
        return @(errorCode);
    }] integerValue];
}

-(NSString*)latestRequestIDForPlacementID:(NSString*)placementID {
    return [_latestRequestIDStorageAccessor readWithBlock:^id{ return _latestRequestIDStorage[placementID]; }];
}

-(void) setLatestRequestID:(NSString*)requestID forPlacementID:(NSString*)placementID {
    if (requestID != nil && placementID != nil) { [_latestRequestIDStorageAccessor writeWithBlock:^{ _latestRequestIDStorage[placementID] = requestID; }]; }
}

#pragma mark - placement setting requests
/**
 PSID will be retrived if it does not expire
 */
-(void) requestPlacementSettingWithPlacementID:(NSString*)placementID customData:(NSDictionary*)customData completion:(void(^)(ATPlacementModel *placementModel, NSError *error))completion {
    NSString *appID = [ATAPI sharedInstance].appID;
    NSString *appKey = [ATAPI sharedInstance].appKey;
    if ([self errorCodeForAppID:appID appKey:appKey placementID:placementID] == errorCodeSuccess) {
        NSString *pStr = [[[ATPlacementSettingManager parametersWithPlacementID:placementID customData:customData] jsonString_anythink] stringByBase64Encoding_anythink];
        NSString *p2Str = [[[ATPlacementSettingManager parameters2] jsonString_anythink] stringByBase64Encoding_anythink];
        NSMutableDictionary *para = [NSMutableDictionary dictionaryWithObjectsAndKeys:pStr, @"p", p2Str, @"p2", @"1.0", @"api_ver", nil];
        para[@"sign"] = [Utilities computeSignWithParameters:para];
        NSNumber *requestTime = [Utilities normalizedTimeStamp];
        __weak typeof(self) weakSelf = self;
        [[ATNetworkingManager sharedManager] sendHTTPRequestToDomain:kAPIDomain path:@"v1/open/placement" HTTPMethod:ATNetworkingHTTPMethodPOST parameters:para completion:^(NSData*  _Nonnull data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            __block NSDictionary *responseObject = nil;
            //AT_SafelyRun is used to guard against exception that's beyond our precaution, which includes the nullability of responseData.
            AT_SafelyRun(^{ responseObject = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithBase64EncodedData:data options:0] options:NSJSONReadingMutableContainers error:nil]; });
            if (completion != nil && [responseObject isKindOfClass:[NSDictionary class]]) {
                if ([responseObject[@"data"] isKindOfClass:[NSDictionary class]] && [responseObject[@"data"] count] > 0) {
                    
                    //Insert cache date into response object
                    NSMutableDictionary *tempData = [NSMutableDictionary dictionaryWithDictionary:responseObject[@"data"]];
                    tempData[kPlacementModelCacheDateKey] = [NSDate date];
                    NSMutableDictionary *tempResponseObject = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                    tempResponseObject[@"data"] = tempData;
                    responseObject = tempResponseObject;
                    
                    [weakSelf configurePSIDWithDictionary:responseObject[@"data"]];
                    ATPlacementModel *placement = [[ATPlacementModel alloc] initWithDictionary:responseObject[@"data"] placementID:placementID];
                    if (placement != nil) {
                        if (placement.cachesPlacementSetting) { [ATPlacementSettingManager savePlacementSettings:responseObject[@"data"] forPlacementID:placementID]; }
                        [ATAgentEvent saveRequestAPIName:@"placement" requestDate:requestTime responseDate:[Utilities normalizedTimeStamp] extra:placementID != nil ?  @{kAgentEventExtraInfoPlacementIDKey:placementID} : nil];
                        completion(placement, nil);
                    } else {
                        error = error != nil ? error : [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodePlacementStrategyInvalidResponse userInfo:@{NSLocalizedDescriptionKey:kPlacementStegatryLoadingErrorDescription, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"Server returns invalid response, code:%ld, msg:%@", [responseObject[@"code"] integerValue], responseObject[@"msg"]]}];
                        [ATPlacementSettingManager saveAPIErrorWithPlacementID:placementID error:error];
                        completion(nil, error);
                    }
                } else {
                    [[ATPlacementSettingManager sharedManager] setErrorCode:[responseObject[@"code"] integerValue] forAppID:appID appKey:appKey placementID:placementID];
                    error = error != nil ? error : [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodePlacementStrategyInvalidResponse userInfo:@{NSLocalizedDescriptionKey:kPlacementStegatryLoadingErrorDescription, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"Server returns invalid response, code:%ld, msg:%@", [responseObject[@"code"] integerValue], responseObject[@"msg"]]}];
                    [ATPlacementSettingManager saveAPIErrorWithPlacementID:placementID error:error];
                    completion(nil, error);
                }
            } else if (completion != nil) {
                if (((NSHTTPURLResponse*)response).statusCode != 200) {
                    error = error != nil ? error : [NSError errorWithDomain:ATADLoadingErrorDomain code:((NSHTTPURLResponse*)response).statusCode userInfo:@{NSLocalizedDescriptionKey:kPlacementStegatryLoadingErrorDescription, NSLocalizedFailureReasonErrorKey:@"Network connection has encountered some error while loading placement strategy."}];
                    [ATPlacementSettingManager saveAPIErrorWithPlacementID:placementID error:error];
                    completion(nil, error);
                } else {
                    error = error != nil ? error : [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodePlacementStrategyInvalidResponse userInfo:@{NSLocalizedDescriptionKey:kPlacementStegatryLoadingErrorDescription, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"Server returns invalid response, code:%ld, msg:%@", [responseObject[@"code"] integerValue], responseObject[@"msg"]]}];
                    [ATPlacementSettingManager saveAPIErrorWithPlacementID:placementID error:error];
                    completion(nil, error);
                }
            }
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, [NSError errorWithDomain:@"com.anythink.PlacementSettingRequest" code:ATADLoadingErrorCodePlacementStrategyInvalidResponse userInfo:@{NSLocalizedDescriptionKey:kPlacementStegatryLoadingErrorDescription, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"AnyThink has failed to fetch placement strategy for appID:%@, appKey:%@, placementID:%@", appID, appKey, placementID]}]);
        });
    }
}

+(void) saveAPIErrorWithPlacementID:(NSString*)placementID error:(NSError*)error {
    [[ATAgentEvent sharedAgent] saveEventWithKey:kATAgentEventKeyNetworkRequestFail placementID:placementID unitGroupModel:nil extraInfo:@{kAgentEventExtraInfoAPINameKey:@"placement",
                                                                                                                                            kAgentEventExtraInfoNetworkErrorCodeKey:@(error.code),
                                                                                                                                            kAgentEventExtraInfoNetworkErrorMsgKey:[NSString stringWithFormat:@"%@", error],
                                                                                                                                            kAgentEventExtraInfoTKHostKey:@"aa.toponad.com"
                                                                                                                                            }];
}

-(void) configurePSIDWithDictionary:(NSDictionary*)dictionary {
    if ([dictionary isKindOfClass:[NSDictionary class]] && [dictionary containsObjectForKey:@"ps_id"]) {
        [[ATAdManager sharedManager] setPSID:dictionary[@"ps_id"] interval:[dictionary[@"ps_id_timeout"] doubleValue]];
    }
}

+(NSDictionary*)parametersWithPlacementID:(NSString*)placementID customData:(NSDictionary*)customData {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSDictionary *protectedFields = nil;
    if ([[ATAppSettingManager sharedManager] shouldUploadProtectedFields]) {
        protectedFields = @{@"os_vn":[Utilities systemName],
                            @"os_vc":[Utilities systemVersion],
                            @"network_type":[ATNetworkingManager currentNetworkType],
                            @"mnc":[Utilities mobileNetworkCode],
                            @"mcc":[Utilities mobileCountryCode],
                            @"language":[Utilities language],
                            @"brand":[Utilities brand],
                            @"model":[Utilities model],
                            @"timezone":[Utilities timezone],
                            @"screen":[Utilities screenResolution],
                            @"ua":[Utilities userAgent],
                            @"upid":[[ATAppSettingManager sharedManager].ATID length] > 0 ? [ATAppSettingManager sharedManager].ATID : @""};
    } else {
        protectedFields = @{@"os_vn":@"",
                            @"os_vc":@"",
                            @"network_type":@"",
                            @"mnc":@"",
                            @"mcc":@"",
                            @"language":@"",
                            @"brand":@"",
                            @"model":@"",
                            @"timezone":@"",
                            @"screen":@"",
                            @"ua":@""};
    }
    NSString *sessionID = [[ATPlacementSettingManager sharedManager] sessionIDForPlacementID:placementID];
    NSDictionary *nonSubjectFields = @{@"app_id":[ATAPI sharedInstance].appID,
                                       @"platform":[Utilities platform],
                                       @"pl_id":placementID,
                                       @"ps_id":[ATAPI sharedInstance].psID != nil ? [ATAPI sharedInstance].psID : @"",
                                       @"session_id":sessionID != nil ? sessionID : @"",
                                       @"custom":([[ATAPI sharedInstance].customData isKindOfClass:[NSDictionary class]] && [[ATAPI sharedInstance].customData count] > 0) ? [ATAPI sharedInstance].customData : @{},
                                       @"package_name":[Utilities appBundleID],
                                       @"app_vn":[Utilities appBundleVersion],
                                       @"app_vc":[Utilities appBundleVersion],
                                       @"sdk_ver":[ATAPI sharedInstance].version,
                                       @"nw_ver":[Utilities networkVersions],
                                       @"orient":[Utilities screenOrientation],
                                       @"system":@(1)
                                       };
    [parameters addEntriesFromDictionary:nonSubjectFields];
    [parameters addEntriesFromDictionary:protectedFields];
    if ([[ATAPI sharedInstance].channel length] > 0) { parameters[@"channel"] = [ATAPI sharedInstance].channel; }
    if ([[ATAPI sharedInstance].subchannel length] > 0) { parameters[@"sub_channel"] = [ATAPI sharedInstance].subchannel; }
    NSArray *cappedMyOfferIDs = [NSArray arrayWithArray:[ATPlacementSettingManager excludeMyOfferID]];
    if (cappedMyOfferIDs.count > 0) { parameters[@"exclude_myofferid"] = cappedMyOfferIDs; }
    return parameters;

}

+(NSMutableArray *)excludeMyOfferID {
    NSDictionary<NSString* ,NSString*>* cappedMyOfferIDwithDate = [[ATPlacementSettingManager sharedManager] cappedMyOfferIDs];
    NSMutableArray *cappedMyofferIDsArr = [NSMutableArray array];
    [cappedMyOfferIDwithDate enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:[ATPlacementSettingManager currentTimeStringWithFormat]]) {
            [cappedMyofferIDsArr addObject:key];
        }
    }];
    return cappedMyofferIDsArr;
}

+(NSString *)currentTimeStringWithFormat {
    NSString *format = @"YYYY-MM-dd";
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:currentDate];
}

+(NSDictionary*)parameters2 {
    NSMutableDictionary *parameters2 = [NSMutableDictionary dictionary];
    if ([[ATAppSettingManager sharedManager] shouldUploadProtectedFields]) {
        parameters2[@"idfa"] = [Utilities advertisingIdentifier];
        parameters2[@"idfv"] = [Utilities idfv];
    } else {
        parameters2[@"idfa"] = @"";
        parameters2[@"idfv"] = @"";
    }
    return parameters2;
}
@end

@implementation ATPlacementSettingManager(UpStatus)
/*
 *The structure of the status storage are as follows:
 *{
     placement_id_1:{
         status:@YES,
         expire_date:2019-01-20 16:24
     }
     //Other placement_id
 *}
 */
static NSString *statusKey = @"staus";
static NSString *expireDate = @"expire_date";
-(BOOL) statusForPlacementID:(NSString*)placementID error:(NSError *__autoreleasing *)error {
    __weak typeof(self) weakSelf = self;
    return [[_placementStatusStorageAccessor readWithBlock:^id{
        NSDictionary *statusInfo = weakSelf.placementStatusStorage[placementID];
        BOOL statusExpired = NO;
        if ([statusInfo[expireDate] timeIntervalSinceDate:[NSDate date]] < 0) {
            statusExpired = YES;
            if (error != nil) { *error = [NSError errorWithDomain:@"com.anythink.UpStatus" code:1000 userInfo:@{}]; }
        }
        return @([statusInfo[statusKey] boolValue] && !statusExpired);
    }] boolValue];
}

-(void) setStatus:(BOOL)status forPlacementID:(NSString*)placementID {
    __weak typeof(self) weakSelf = self;
    ATPlacementModel *placementModel = [[ATPlacementSettingManager sharedManager] placementSettingWithPlacementID:placementID];
    [_placementStatusStorageAccessor writeWithBlock:^{
        weakSelf.placementStatusStorage[placementID] = @{statusKey:@(status), expireDate:[[NSDate date] dateByAddingTimeInterval:placementModel.statusValidDuration / 1000.0f]};
    }];
}

-(void) clearAllStatus {
    __weak typeof(self) weakSelf = self;
    [_placementStatusStorageAccessor writeWithBlock:^{ [weakSelf.placementStatusStorage removeAllObjects]; }];
}
@end
