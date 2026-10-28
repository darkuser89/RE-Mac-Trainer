// SPDX-License-Identifier: GPL-3.0-only
#import "TestAdapter.h"
@implementation RE2TestAdapter
- (instancetype)init{if((self=[super init])){_mode=RE2SessionSolo;_identity=@"world-A/owner-A";_confirmed=YES;}return self;}
- (void)onGameThread:(dispatch_block_t)work{dispatch_async(dispatch_get_main_queue(),work);}
- (RE2GameContext *)captureContext{RE2GameContext *s=[RE2GameContext new];s.kind=_mode;s.identity=_identity;s.note=@"Synthetic test context";return s;}
- (void)releaseEffects{_releases++;}
- (RE2FeatureState *)applyFeature:(RE2Feature)feature wanted:(BOOL)wanted value:(double)value{(void)feature;(void)value;_applications++;RE2FeatureState *s=[RE2FeatureState new];s.available=YES;s.active=wanted && _confirmed;return s;}
- (NSString *)performOneShot:(RE2Feature)feature value:(double)value{(void)feature;(void)value;_oneShots++;return @"test-only one-shot";}
- (BOOL)setOverlayInteraction:(BOOL)wanted{return wanted;}
@end
