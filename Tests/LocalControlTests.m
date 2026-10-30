// SPDX-License-Identifier: GPL-3.0-only
#import "LocalControl.h"
#import "TestAdapter.h"
#import <unistd.h>
static void waitFor(BOOL (^done)(void)){
    NSDate *end=[NSDate dateWithTimeIntervalSinceNow:3];while(!done() && end.timeIntervalSinceNow>0)[NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];NSCAssert(done(),@"control callback completed");
}
static NSString *command(RE2GameBridge *b,NSDictionary *r){__block BOOL done=NO;__block NSString *error=nil;[b controlCommand:r completion:^(RE2TrainerState *s,NSString *e){(void)s;error=e;done=YES;}];waitFor(^BOOL{return done;});return error;}
static void rawPost(NSDictionary *r){NSData *d=[NSJSONSerialization dataWithJSONObject:r options:0 error:NULL];[NSDistributedNotificationCenter.defaultCenter postNotificationName:@"local.mactrainer.control-request.v1" object:[[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding] userInfo:nil deliverImmediately:YES];NSDate *end=[NSDate dateWithTimeIntervalSinceNow:0.12];while(end.timeIntervalSinceNow>0)[NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:end];}
void MTControlRunTests(void){
    RE2TestAdapter *a=[RE2TestAdapter new];RE2GameBridge *b=[[RE2GameBridge alloc]initWithAdapter:a];
    NSCAssert(!command(b,@{@"action":@"state"}) && b.state.ready && b.state.updatedAt>0,@"control reads a fresh GameThread state without an overlay");
    NSCAssert(!command(b,@{@"action":@"set",@"feature":@0,@"wanted":@YES}) && b.state.features[0].wanted,@"explicit set-on reaches the native adapter");
    NSCAssert(!command(b,@{@"action":@"set",@"feature":@0,@"wanted":@YES}) && b.state.features[0].wanted,@"repeated set-on is idempotent and cannot toggle off");
    NSCAssert(!command(b,@{@"action":@"set",@"feature":@0,@"wanted":@NO}) && !b.state.features[0].wanted,@"explicit set-off is idempotent");
    NSCAssert(command(b,@{@"action":@"set",@"feature":@(RE2FeatureGameTime),@"wanted":@YES}) && a.oneShots==0,@"one-shot cannot be activated through set");
    NSCAssert(command(b,@{@"action":@"run",@"feature":@0}) && command(b,@{@"action":@"set",@"feature":@999,@"wanted":@YES}),@"wrong action types and out-of-range IDs reject");
    NSCAssert(command(b,@{@"action":@"set",@"feature":@0,@"wanted":@"yes"}) && command(b,@{@"action":@"value",@"feature":@(RE2FeatureSpeed),@"value":@99}),@"invalid booleans and numeric values reject");
    NSCAssert(!command(b,@{@"action":@"value",@"feature":@(RE2FeatureSpeed),@"value":@2.5}) && b.state.features[RE2FeatureSpeed].value==2.5,@"bounded numeric control is explicit");
    NSCAssert(command(b,@{@"action":@"run",@"feature":@(RE2FeatureGameTime),@"deadline":@(NSDate.date.timeIntervalSince1970-1)}) && a.oneShots==0,@"expired command cannot execute later");
    __block BOOL done=NO;__block NSString *stale=nil;[b controlCommand:@{@"action":@"run",@"feature":@(RE2FeatureGameTime)} completion:^(RE2TrainerState *s,NSString *e){(void)s;stale=e;done=YES;}];a.identity=@"world-B/owner-B";waitFor(^BOOL{return done;});NSCAssert(stale && a.oneShots==0,@"context-stale native actions report rejection");
    NSCAssert(!command(b,@{@"action":@"run",@"feature":@(RE2FeatureGameTime)}) && a.oneShots==1,@"one-shot needs an explicit run in the current context");
    a.mode=RE2SessionLoading;[b poll];NSCAssert(!command(b,@{@"action":@"state"}) && !b.state.ready,@"state remains readable during loading");
    NSCAssert(command(b,@{@"action":@"set",@"feature":@0,@"wanted":@YES}) && !b.state.features[0].wanted,@"loading rejects cheat mutation");
    a.mode=RE2SessionSolo;command(b,@{@"action":@"state"});
    __block BOOL cancelled=NO;[b poll];[b controlCommand:@{@"action":@"run",@"feature":@(RE2FeatureGameTime)} completion:^(RE2TrainerState *s,NSString *e){(void)s;cancelled=e!=nil;}];[b performAction:RE2TrainerDisableAll];waitFor(^BOOL{return cancelled;});NSCAssert(a.oneShots==1,@"⇧F9 cancels a queued control one-shot and completes its callback");
    command(b,@{@"action":@"state"});
    NSString *profile=[@"fixture-" stringByAppendingString:NSUUID.UUID.UUIDString],*session=NSUUID.UUID.UUIDString;__block NSUInteger received=0;
    MTLocalControl *server=[[MTLocalControl alloc]initWithMetadata:@{@"profile":profile,@"session":session,@"pid":@(getpid()),@"build":@"test"} handler:^(NSDictionary *r,MTControlReply reply){received++;[b controlCommand:r completion:^(RE2TrainerState *s,NSString *e){reply(e ? @{@"ok":@NO,@"error":e} : @{@"ok":@YES,@"state":MTControlSnapshot(s)});}];}];
    NSDictionary *response=MTControlClient(profile,@{@"action":@"state"});NSCAssert([response[@"ok"] boolValue] && [response[@"state"][@"features"] count]==RE2FeatureCount,@"real local notification transport reads actual bridge state");
    response=MTControlClient(profile,@{@"action":@"set",@"feature":@0,@"wanted":@YES});NSCAssert([response[@"state"][@"features"][0][@"wanted"] boolValue],@"transport control works with no visible UI");
    NSUInteger count=received,shots=a.oneShots;NSMutableDictionary *envelope=[@{@"version":@1,@"request":NSUUID.UUID.UUIDString,@"action":@"run",@"feature":@(RE2FeatureGameTime),@"profile":profile,@"pid":@(getpid()),@"session":@"wrong",@"deadline":@(NSDate.date.timeIntervalSince1970+4)} mutableCopy];rawPost(envelope);NSCAssert(received==count && a.oneShots==shots,@"wrong session cannot control the game");
    envelope[@"session"]=session;rawPost(envelope);rawPost(envelope);NSCAssert(received==count+1 && a.oneShots==shots+1,@"duplicate request ID cannot replay a one-shot");
    [server stop];response=MTControlClient(profile,@{@"action":@"state"});NSCAssert(![response[@"ok"] boolValue],@"closed control session is no longer discoverable");
    a=[RE2TestAdapter new];b=[[RE2GameBridge alloc]initWithAdapter:a readOnly:YES];command(b,@{@"action":@"state"});NSCAssert(command(b,@{@"action":@"set",@"feature":@0,@"wanted":@YES}) && a.applications==0,@"inspection mode never gains mutation through control API");
}
