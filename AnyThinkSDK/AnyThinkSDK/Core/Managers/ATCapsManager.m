//
//  ATCapsManager.m
//  AnyThinkSDK
//
//  Created by Martin Lau on 28/06/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATCapsManager.h"
#import "Utilities.h"
#import "ATThreadSafeAccessor.h"
#import "ATPlacementModel.h"
@interface ATCapsManager()
/**
 Store the caps by which the offers has been shown; must be acceed under the control of the accessor to make it thread-safe.
 */
@property(nonatomic, readonly) ATThreadSafeAccessor *capsAccessor;
@property(nonatomic, readonly) NSMutableDictionary *caps;

@property(nonatomic, readonly) ATThreadSafeAccessor *showTimeStorageAccessor;
@property(nonatomic, readonly) NSMutableDictionary *showTimeStorage;

@property(nonatomic, readonly) ATThreadSafeAccessor *showFlagsStorageAccessor;
@property(nonatomic, readonly) NSMutableDictionary<NSString*, NSNumber*> *showFlagsStorage;
@end

static NSString *const kCapsInfoFileName = @"capsInfo.anythink.com";
static NSString *const kShowTimeInfoName = @"showTime.anythink.com";
@implementation ATCapsManager
#pragma mark - init
+(instancetype) sharedManager {
    static ATCapsManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ATCapsManager alloc] init];
    });
    return sharedManager;
}

-(instancetype) init {
    self = [super init];
    if (self != nil) {
        _capsAccessor = [ATThreadSafeAccessor new];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[ATCapsManager capsInfoPath]]) {
            _caps = [[NSMutableDictionary alloc] initWithContentsOfFile:[ATCapsManager capsInfoPath]];
        } else {
            _caps = [NSMutableDictionary dictionary];
        }
        
        _showTimeStorageAccessor = [ATThreadSafeAccessor new];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[ATCapsManager capsInfoPath]]) {
            _showTimeStorage = [[NSMutableDictionary alloc] initWithContentsOfFile:[ATCapsManager showTimeInfoPath]];
        } else {
            _showTimeStorage = [NSMutableDictionary dictionary];
        }
        
        _showFlagsStorage = [NSMutableDictionary<NSString*, NSNumber*> dictionary];
        _showFlagsStorageAccessor = [ATThreadSafeAccessor new];
    }
    return self;
}

+(NSString*)capsInfoPath {
    return [[Utilities documentsPath] stringByAppendingPathComponent:kCapsInfoFileName];
}

+(NSString*)showTimeInfoPath {
    return [[Utilities documentsPath] stringByAppendingPathComponent:kShowTimeInfoName];
}

#pragma mark - caps management
/**
 For the tightest bound on the cap is as far as to by hour, the time label
 The following caps management methods are thread-safe. requestID has to be provided for verification's sake. The structure of the cpas storage is as follows:
 {
     placement_1: {
     caps: {
         unit_group_1: {
             time_label:2018-04-14/18,
             cap_by_hour: 3,
             cap_by_day: 1
         },
         //Other unit group
     },
     cap_by_day: 3,
     cpa_by_hour:3,
     time_label:2018-04-14/18,
     request_id:request_id
     },
     //Other placements follow.
 }
 */
NSString *CurrentTimeReprezentation() {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH";
    return [formatter stringFromDate:[NSDate date]];
}

static NSString *const kCapsKey = @"caps";
static NSString *const kCapByDayKey = @"cap_by_day";
static NSString *const kCapByHourKey = @"cap_by_hour";
static NSString *const kTimeLabelKey = @"time_label";
static NSString *const kLastRequestIDKey = @"last_request_id";
-(void) increaseCapWithPlacementID:(NSString*)placementID unitGroupID:(NSString*)unitGroupID requestID:(NSString*)requestID {
    if ([placementID isKindOfClass:[NSString class]] && [unitGroupID isKindOfClass:[NSString class]] && [requestID isKindOfClass:[NSString class]]) {
        [_capsAccessor writeWithBlock:^{
            NSString *currentTime = CurrentTimeReprezentation();
            NSMutableDictionary *placementInfo = _caps[placementID];
            if (placementInfo == nil) {
                placementInfo = [NSMutableDictionary dictionaryWithObject:requestID forKey:kLastRequestIDKey];
                _caps[placementID] = placementInfo;
            } else {
                placementInfo[kLastRequestIDKey] = requestID;
            }
            
            //Update placement overall caps
            if ([placementInfo[kTimeLabelKey] isEqualToString:currentTime]) {
                placementInfo[kCapByHourKey] = @([placementInfo[kCapByHourKey] integerValue] + 1);
                placementInfo[kCapByDayKey] = @([placementInfo[kCapByDayKey] integerValue] + 1);
            } else if ([placementInfo[kTimeLabelKey] hasPrefix:[currentTime componentsSeparatedByString:@" "][0]]) {
                placementInfo[kCapByDayKey] = @([placementInfo[kCapByDayKey] integerValue] + 1);
                placementInfo[kCapByHourKey] = @1;
                placementInfo[kTimeLabelKey] = currentTime;
            } else {
                placementInfo[kCapByHourKey] = @1;
                placementInfo[kCapByDayKey] = @1;
                placementInfo[kTimeLabelKey] = currentTime;
            }
            
            //Group unit cap info update
            if ([placementInfo[kCapsKey] containsObjectForKey:unitGroupID]) {
                //Unit group info exists
                NSMutableDictionary *unitGroupCapsInfo = placementInfo[kCapsKey][unitGroupID];
                if ([unitGroupCapsInfo[kTimeLabelKey] isEqualToString:currentTime]) {
                    //Within the same hour
                    unitGroupCapsInfo[kCapByHourKey] = @([unitGroupCapsInfo[kCapByHourKey] integerValue] + 1);
                    unitGroupCapsInfo[kCapByDayKey] = @([unitGroupCapsInfo[kCapByDayKey] integerValue] + 1);
                } else if ([unitGroupCapsInfo[kTimeLabelKey] hasPrefix:[currentTime componentsSeparatedByString:@" "][0]]) {
                    //Within the same day but a different hour, under such circumstances, increase the cap_by_day val and reset the cap_by_hour val.
                    unitGroupCapsInfo[kCapByDayKey] = @([unitGroupCapsInfo[kCapByDayKey] integerValue] + 1);
                    unitGroupCapsInfo[kCapByHourKey] = @1;
                    unitGroupCapsInfo[kTimeLabelKey] = currentTime;
                } else {
                    //Different day & hour
                    unitGroupCapsInfo[kCapByHourKey] = @1;
                    unitGroupCapsInfo[kCapByDayKey] = @1;
                    unitGroupCapsInfo[kTimeLabelKey] = currentTime;
                }
            } else {
                //Unit group info does not exists
                NSMutableDictionary *unitGroupCapsInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:currentTime, kTimeLabelKey, @1, kCapByDayKey, @1, kCapByHourKey, nil];
                NSMutableDictionary *capsInfo = placementInfo[kCapsKey];
                if (capsInfo == nil) {
                    capsInfo = [NSMutableDictionary dictionaryWithObject:unitGroupCapsInfo forKey:unitGroupID];
                    placementInfo[kCapsKey] = capsInfo;
                } else {
                    capsInfo[unitGroupID] = unitGroupCapsInfo;
                }
            }
            
            [_caps writeToFile:[ATCapsManager capsInfoPath] atomically:YES];
        }];
    }
}

-(NSInteger) capByDayWithPlacementID:(NSString*)placementID {
    __weak typeof(self) weakSelf = self;
    return [[_capsAccessor readWithBlock:^id{
        if ([weakSelf.caps containsObjectForKey:placementID]) {
            NSDictionary *placementCapsInfo = weakSelf.caps[placementID];
            if ([placementCapsInfo[kTimeLabelKey] hasPrefix:[CurrentTimeReprezentation() componentsSeparatedByString:@" "][0]]) return placementCapsInfo[kCapByDayKey];
            else return @0;
        } else {
            return @0;
        }
    }] integerValue];
}

-(NSInteger) capByHourWithPlacementID:(NSString*)placementID {
    __weak typeof(self) weakSelf = self;
    return [[_capsAccessor readWithBlock:^id{
        if ([weakSelf.caps containsObjectForKey:placementID]) {
            NSDictionary *placementCapsInfo = weakSelf.caps[placementID];
            if ([placementCapsInfo[kTimeLabelKey] isEqualToString:CurrentTimeReprezentation()]) return placementCapsInfo[kCapByHourKey];
            else return @0;
        } else {
            return @0;
        }
    }] integerValue];
}
/**
 The following two methods return 0 if the tightness has been passed; for example, if you inquire the cap of a unit group at some time on 2018-04-15, and the time label of the stored cap info is 2018-04-14, 0 will be returned for both the day&hour cap.
 
 On occasion where a new placement id is encountered, 0 also will be returned.
 
 requestID's now not used
 */
-(NSInteger) capByDayWithPlacementID:(NSString*)placementID unitGroupID:(NSString*)unitGroupID requestID:(NSString*)requestID {
    __weak typeof(self) weakSelf = self;
    return [[_capsAccessor readWithBlock:^id{
        if ([weakSelf.caps containsObjectForKey:placementID]) {
            NSDictionary *placementInfo = _caps[placementID];
            NSDictionary *capsInfo = placementInfo[kCapsKey];
            if ([capsInfo containsObjectForKey:unitGroupID]) {
                NSDictionary *unitGroupCapsInfo = capsInfo[unitGroupID];
                if ([unitGroupCapsInfo[kTimeLabelKey] hasPrefix:[CurrentTimeReprezentation() componentsSeparatedByString:@" "][0]]) {
                    return unitGroupCapsInfo[kCapByDayKey];
                } else {
                    return @0;
                }
            } else {
                return @0;
            }
        } else {
            return @0;
        }
    }] integerValue];
}

-(NSInteger) capByHourWithPlacementID:(NSString*)placementID unitGroupID:(NSString*)unitGroupID requestID:(NSString*)requestID {
    __weak typeof(self) weakSelf = self;
    return [[_capsAccessor readWithBlock:^id{
        if ([weakSelf.caps containsObjectForKey:placementID]) {
            NSDictionary *placementInfo = _caps[placementID];
            NSDictionary *capsInfo = placementInfo[kCapsKey];
            if ([capsInfo containsObjectForKey:unitGroupID]) {
                NSDictionary *unitGroupCapsInfo = capsInfo[unitGroupID];
                if ([unitGroupCapsInfo[kTimeLabelKey] isEqualToString:CurrentTimeReprezentation()]) {
                    return unitGroupCapsInfo[kCapByHourKey];
                } else {
                    return @0;
                }
            } else {
                return @0;
            }
        } else {
            return @0;
        }
    }] integerValue];
}
#pragma mark - show time storage
/**
 {
     placement_1: {
         placement_last_show_time:2018-04-16 18:00,
         unit_group_last_show_times: {
             unit_group_1:2018-04-16 18:00,
             unit_group_2:2018-04-16 17:35
         }
     }
 }
 */
static NSString *const kPlacementLastShowTimeKey = @"placement_last_show_time";
static NSString *const kUnitGroupLastShowTimesKey = @"unit_group_last_show_times";
-(void) setLastShowTimeWithPlacementID:(NSString*)placementID unitGroupID:(NSString*)unitGroupID {
    if ([placementID isKindOfClass:[NSString class]] && [unitGroupID isKindOfClass:[NSString class]]) {
        [_showTimeStorageAccessor writeWithBlock:^{
            NSDate *date = [NSDate date];
            if ([_showTimeStorage containsObjectForKey:placementID]) {
                NSMutableDictionary *placementInfo = _showTimeStorage[placementID];
                placementInfo[kPlacementLastShowTimeKey] = date;
                NSMutableDictionary *unitGroupInfo = placementInfo[kUnitGroupLastShowTimesKey];
                unitGroupInfo[unitGroupID] = date;
            } else {
                NSMutableDictionary *placementInfo = [NSMutableDictionary dictionaryWithObject:date forKey:kPlacementLastShowTimeKey];
                NSMutableDictionary *unitGroupInfo = [NSMutableDictionary dictionaryWithObject:date forKey:unitGroupID];
                placementInfo[kUnitGroupLastShowTimesKey] = unitGroupInfo;
                _showTimeStorage[placementID] = placementInfo;
            }
            [_showTimeStorage writeToFile:[ATCapsManager showTimeInfoPath] atomically:YES];
        }];
    }
}

-(NSDate*)lastShowTimeOfPlacementID:(NSString *)placementID unitGroupID:(NSString *)unitGroupID {
    return [_showTimeStorageAccessor readWithBlock:^id{
        return _showTimeStorage[placementID][kUnitGroupLastShowTimesKey][unitGroupID];
    }];
}

-(NSDate*) lastShowTimeOfPlacementID:(NSString*)placementID {
    return [_showTimeStorageAccessor readWithBlock:^id{
        return _showTimeStorage[placementID][kPlacementLastShowTimeKey];
    }];
}

+(BOOL)validateCapsForPlacementModel:(ATPlacementModel*)placementModel {
    return placementModel.unitCapsByDay > [[ATCapsManager sharedManager] capByDayWithPlacementID:placementModel.placementID] && placementModel.unitCapsByHour > [[ATCapsManager sharedManager] capByHourWithPlacementID:placementModel.placementID];
}

+(BOOL)validatePacingForPlacementModel:(ATPlacementModel*)placementModel {
    return placementModel.unitPacing < 0 || [[ATCapsManager sharedManager] lastShowTimeOfPlacementID:placementModel.placementID] == nil || [[NSDate date] timeIntervalSinceDate:[[ATCapsManager sharedManager] lastShowTimeOfPlacementID:placementModel.placementID]] >= placementModel.unitPacing / 1000.0f;
}

-(void) setShowFlagForPlacementID:(NSString*)placementID requestID:(NSString*)requestID {
    [_showFlagsStorageAccessor writeWithBlock:^{ _showFlagsStorage[[ATCapsManager showFlagKeyForPlacementID:placementID requestID:requestID]] = @YES; }];
}

-(BOOL) showFlagForPlacementID:(NSString*)placementID requestID:(NSString*)requestID {
    return [[_showFlagsStorageAccessor readWithBlock:^id{ return _showFlagsStorage[[ATCapsManager showFlagKeyForPlacementID:placementID requestID:requestID]]; }] boolValue];
}

+(NSString*)showFlagKeyForPlacementID:(NSString*)placementID requestID:(NSString*)requestID {
    return [NSString stringWithFormat:@"%@_%@", placementID, requestID].md5;
}
@end

@implementation NSObject(ATAdValidation)
-(BOOL) adValid {
    if ([self conformsToProtocol:@protocol(ATAd)]) {
        id<ATAd> ad = (id<ATAd>)self;
        ATPlacementModel *placementModel = ad.placementModel;
        ATUnitGroupModel *unitGroupModel = ad.unitGroup;
        return [placementModel placementValid] && [unitGroupModel unitGroupValid:placementModel.placementID];
    } else {
        return NO;
    }
}
@end

@implementation ATUnitGroupModel(ATAdValidation)
-(BOOL) unitGroupValid:(NSString*)placementID {
    return self.showingInterval < 0 || (self.capByDay > [[ATCapsManager sharedManager] capByDayWithPlacementID:placementID unitGroupID:self.unitGroupID requestID:nil] && self.capByHour > [[ATCapsManager sharedManager] capByHourWithPlacementID:placementID unitGroupID:self.unitGroupID requestID:nil] && ([[ATCapsManager sharedManager] lastShowTimeOfPlacementID:placementID unitGroupID:self.unitGroupID] == nil || [[NSDate date] timeIntervalSinceDate:[[ATCapsManager sharedManager] lastShowTimeOfPlacementID:placementID unitGroupID:self.unitGroupID]] >= self.showingInterval / 1000.0f));
}
@end

@implementation ATPlacementModel(ATAdValidation)
-(BOOL) placementValid {
    return self.unitCapsByDay > [[ATCapsManager sharedManager] capByDayWithPlacementID:self.placementID] && self.unitCapsByHour > [[ATCapsManager sharedManager] capByHourWithPlacementID:self.placementID] &&
    (self.unitPacing < 0 || [[ATCapsManager sharedManager] lastShowTimeOfPlacementID:self.placementID] == nil || [[NSDate date] timeIntervalSinceDate:[[ATCapsManager sharedManager] lastShowTimeOfPlacementID:self.placementID]] >= self.unitPacing / 1000.0f);
}
@end
