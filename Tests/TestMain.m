// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import <mach-o/loader.h>
#import <mach/machine.h>
#import "GameBridge.h"
#import "CheatPreferences.h"
#import "TestAdapter.h"
#import "GameProfile.h"
#import "MemoryAccess.h"
#import "Overlay.h"
#import "TrainerMaterial.h"
#import "RE2Adapter.h"
#import "RE2Bindings.h"
#import "RE2Ownership.h"
#import "RE2EffectLedger.h"
#import "RE4Features.h"
#import "RE7Features.h"
#import "RE8Features.h"
#import "RE4Adapter.h"
#import "RE3Adapter.h"
#import "RE7Adapter.h"
#import "RE8Adapter.h"
#import "RE2Engine.h"
#include <math.h>
#import <objc/runtime.h>
@interface RE2NativeAdapter (LedgerChecks)
- (void *)registeredEnemyController:(void *)registration;
- (BOOL)resetCurrentSaveCount:(void *)record;
- (BOOL)solvePortableSafe:(void *)safe owner:(RE2Owner *)owner;
- (BOOL)applyLocalSpeedFactor:(float)factor controller:(void *)controller owner:(RE2Owner *)owner;
- (void)restorePendingLocalSpeed;
- (void)continuousFrame;
- (BOOL)continuousContextValid;
- (BOOL)applyBytes:(NSData *)bytes object:(void *)object offset:(size_t)offset owner:(RE2Owner *)owner global:(BOOL)global feature:(RE2Feature)feature;
- (void)releaseFeature:(RE2Feature)feature;
- (BOOL)applyValueBytes:(NSData *)bytes object:(void *)object offset:(size_t)offset owner:(RE2Owner *)owner global:(BOOL)global feature:(RE2Feature)feature guard:(BOOL (^)(void))guard read:(NSData *(^)(void))read write:(void (^)(NSData *))write;
@end
static NSUInteger registrationGetterCalls;
static void *fixtureEnemyController(void *context,void *registration){
    (void)context;registrationGetterCalls++;void *controller=NULL;memcpy(&controller,(uint8_t *)registration+0x10,sizeof(controller));return controller;
}
@interface RE2EnemyFixtureEngine : MTRE2Engine
@property(nonatomic,assign) void *registration,*controller;
@end
@implementation RE2EnemyFixtureEngine
- (BOOL)isGameThread {return YES;}
- (void *)threadContext {return (__bridge void *)self;}
- (uint32_t)typeOf:(const void *)object {return object==self.registration ? RE2Type_EnemyRegistration : object==self.controller ? 12402 : UINT32_MAX;}
- (BOOL)isObject:(void *)object kindOf:(uint32_t)type {return object && [self typeOf:object]==type;}
- (void *)method:(uint32_t)index owner:(uint32_t)owner {return index==RE2Method_EnemyRegistration_get_Controller && owner==RE2Type_EnemyRegistration ? (void *)fixtureEnemyController : NULL;}
@end
static void re2EnemyRegistrationTests(void){
    uint8_t registration[0x30]={0},controller[0x30]={0},foreign[0x30]={0};void *live=controller;
    memcpy(registration+0x10,&live,sizeof(live));
    RE2EnemyFixtureEngine *engine=[RE2EnemyFixtureEngine new];engine.registration=registration;engine.controller=controller;
    RE2NativeAdapter *adapter=[RE2NativeAdapter new];[adapter setValue:engine forKey:@"engine"];registrationGetterCalls=0;
    NSCAssert([adapter registeredEnemyController:registration]==controller && registrationGetterCalls==1,@"RE2 registration entries resolve through their native getter instead of being skipped as non-controllers");
    NSCAssert(![adapter registeredEnemyController:controller] && ![adapter registeredEnemyController:foreign] && registrationGetterCalls==1,@"non-registration payloads never invoke a registration getter");
    live=NULL;memcpy(registration+0x10,&live,sizeof(live));
    NSCAssert(![adapter registeredEnemyController:registration],@"inactive registration with no controller is ignored");
    live=foreign;memcpy(registration+0x10,&live,sizeof(live));
    NSCAssert(![adapter registeredEnemyController:registration],@"a registration returning a foreign type cannot become an enemy target");
}
static NSUInteger saveSetterCalls;
static BOOL saveSetterIgnored;
static int32_t fixtureSaveGetter(void *context,void *record){(void)context;int32_t n;memcpy(&n,(uint8_t *)record+0x90,4);return n;}
static void fixtureSaveSetter(void *context,void *record,int32_t value){(void)context;saveSetterCalls++;if(!saveSetterIgnored)memcpy((uint8_t *)record+0x90,&value,4);}
@interface RE2SaveFixtureEngine : MTRE2Engine
@property(nonatomic,assign) void *record,*flow;
@property(nonatomic) BOOL wrongThread,wrongType,wrongSingleton,noGetter,noSetter,noFlowGetter,noFlowSetter;
@end
static void *fixtureFlowInstance(void *context){return ((__bridge RE2SaveFixtureEngine *)context).flow;}
@implementation RE2SaveFixtureEngine
- (BOOL)isGameThread {return !self.wrongThread;}
- (void *)threadContext {return (__bridge void *)self;}
- (void *)singletonAt:(uintptr_t)slot {return slot==0x10b18a2b0 && !self.wrongSingleton ? self.record : NULL;}
- (uint32_t)typeOf:(const void *)object {return object && object==self.record && !self.wrongType ? RE2Type_Record : object && object==self.flow ? RE2Type_MainFlow : UINT32_MAX;}
- (void *)method:(uint32_t)index owner:(uint32_t)owner {
    if(owner==RE2Type_MainFlowSingleton && index==RE2Method_MainFlow_get_Instance)return (void *)fixtureFlowInstance;
    if(owner==RE2Type_MainFlow && index==RE2Method_MainFlow_get_SaveTimes && !self.noFlowGetter)return (void *)fixtureSaveGetter;
    if(owner==RE2Type_MainFlow && index==RE2Method_MainFlow_set_SaveTimes && !self.noFlowSetter)return (void *)fixtureSaveSetter;
    if(owner!=RE2Type_Record)return NULL;
    if(index==RE2Method_Record_get_CurrentSaveCount && !self.noGetter)return (void *)fixtureSaveGetter;
    if(index==RE2Method_Record_set_CurrentSaveCount && !self.noSetter)return (void *)fixtureSaveSetter;
    return NULL;
}
@end
static void re2SaveCountTests(void){
    uint8_t record[0x100]={0},flow[0x100]={0};int32_t before=7,sentinel=123;memcpy(flow+0x90,&before,4);
    memcpy(record+0x90,&before,4);memcpy(record+0xdc,&sentinel,4);
    RE2SaveFixtureEngine *engine=[RE2SaveFixtureEngine new];engine.record=record;engine.flow=flow;
    RE2NativeAdapter *adapter=[RE2NativeAdapter new];[adapter setValue:engine forKey:@"engine"];
    saveSetterCalls=0;saveSetterIgnored=NO;
    NSCAssert([adapter resetCurrentSaveCount:record] && fixtureSaveGetter(NULL,record)==0 && fixtureSaveGetter(NULL,flow)==0 && saveSetterCalls==2,@"save reset uses the actual native property getter/setter");
    int32_t oldField;memcpy(&oldField,record+0xdc,4);NSCAssert(oldField==sentinel,@"save reset never writes the former assumed field offset");
    for(NSString *flag in @[@"wrongThread",@"wrongType",@"wrongSingleton",@"noGetter",@"noSetter",@"noFlowGetter",@"noFlowSetter"]){
        [engine setValue:@YES forKey:flag];NSCAssert(![adapter resetCurrentSaveCount:record] && saveSetterCalls==2,@"invalid native save context is rejected without mutation");[engine setValue:@NO forKey:flag];
    }
    for(NSNumber *invalid in @[@(-1),@(10000001)]){int32_t n=invalid.intValue;memcpy(record+0x90,&n,4);NSCAssert(![adapter resetCurrentSaveCount:record] && saveSetterCalls==2,@"invalid counter values cannot be reported as a successful reset");}
    memcpy(record+0x90,&before,4);memcpy(flow+0x90,&before,4);saveSetterIgnored=YES;
    NSCAssert(![adapter resetCurrentSaveCount:record] && fixtureSaveGetter(NULL,record)==7 && saveSetterCalls==6,@"native setter failure must fail readback");saveSetterIgnored=NO;
}
@interface RE2PortableFixtureEngine : MTRE2Engine
@property(nonatomic,assign) void *safe,*answers,*input;
@property(nonatomic) BOOL wrongThread,wrongType,missingSetter,missingResize,rejectResize,rejectInput,incorrectPrefix;
@property(nonatomic) int listCount,inputListCount;
@property(nonatomic) NSUInteger clears,inputs,resizes;
@end
static void *portableFixtureAnswers(void *ctx,void *safe){(void)safe;return ((__bridge RE2PortableFixtureEngine *)ctx).answers;}
static void *portableFixtureInput(void *ctx,void *safe){(void)safe;return ((__bridge RE2PortableFixtureEngine *)ctx).input;}
static int32_t portableFixtureCount(void *ctx,void *list){RE2PortableFixtureEngine *e=(__bridge id)ctx;return list==e.input ? e.inputListCount : e.listCount;}
static void portableFixtureResize(void *ctx,void *safe){(void)safe;RE2PortableFixtureEngine *e=(__bridge id)ctx;e.resizes++;if(!e.rejectResize)e.inputListCount=8;}
static int32_t portableFixtureAt(void *ctx,void *list,int32_t i){(void)ctx;return ((int32_t *)list)[i];}
static void portableFixtureClear(void *ctx,void *safe){RE2PortableFixtureEngine *e=(__bridge id)ctx;e.clears++;memset((uint8_t *)safe+0xb8,0,4);for(int i=0;i<8;i++)((int32_t *)e.input)[i]=-1;}
static void portableFixtureSet(void *ctx,void *safe,int32_t n){RE2PortableFixtureEngine *e=(__bridge id)ctx;e.inputs++;int32_t count;memcpy(&count,(uint8_t *)safe+0xb8,4);if(!e.rejectInput && count>=1 && count<=8)((int32_t *)e.input)[count-1]=n;}
static BOOL portableFixtureIncorrect(void *ctx,void *safe){RE2PortableFixtureEngine *e=(__bridge id)ctx;int32_t count;memcpy(&count,(uint8_t *)safe+0xb8,4);if(e.incorrectPrefix)return YES;for(int i=0;i<count && i<8;i++)if(((int32_t *)e.input)[i]!=((int32_t *)e.answers)[i])return YES;return NO;}
static BOOL portableFixtureFinished(void *ctx,void *safe){(void)ctx;return *((uint8_t *)safe+0xbf)==1;}
@implementation RE2PortableFixtureEngine
- (BOOL)isGameThread {return !self.wrongThread;}
- (void *)threadContext {return (__bridge void *)self;}
- (uint32_t)typeOf:(const void *)o {return o && o==self.safe && !self.wrongType ? 9088 : o && (o==self.answers || o==self.input) ? 12274 : UINT32_MAX;}
- (void *)method:(uint32_t)i owner:(uint32_t)owner {
    if(owner==12274){if(i==6331)return (void *)portableFixtureCount;if(i==6337)return (void *)portableFixtureAt;return NULL;}
    if(owner!=9088)return NULL;
    switch(i){case 454672:return (void *)portableFixtureAnswers;case 454674:return (void *)portableFixtureInput;case 454693:return (void *)portableFixtureClear;case 454694:return self.missingResize ? NULL : (void *)portableFixtureResize;case 454695:return self.missingSetter ? NULL : (void *)portableFixtureSet;case 454696:return (void *)portableFixtureIncorrect;case 454686:return (void *)portableFixtureFinished;default:return NULL;}
}
@end
@interface RE2PortableFixtureOwner : RE2Owner
@property(nonatomic) BOOL alive;
@property(nonatomic,assign) void *owned;
@end
@implementation RE2PortableFixtureOwner
- (BOOL)valid {return self.alive;}
- (void *)component {return self.owned;}
@end
@interface RE2PortableFixtureAdapter : RE2NativeAdapter
@property(nonatomic,assign) void *opened;
@end
@implementation RE2PortableFixtureAdapter
- (void *)openedPortableSafe {return self.opened;}
@end
static void portableSafeTests(void){
    uint8_t safe[0x100]={0};int32_t answers[8]={3,1,7,0,6,2,5,4},input[8]={0};safe[0x52]=1;
    RE2PortableFixtureEngine *e=[RE2PortableFixtureEngine new];e.safe=safe;e.answers=answers;e.input=input;e.listCount=8;e.inputListCount=8;
    RE2PortableFixtureOwner *owner=[RE2PortableFixtureOwner new];owner.alive=YES;owner.owned=safe;
    RE2PortableFixtureAdapter *a=[RE2PortableFixtureAdapter new];a.opened=safe;[a setValue:e forKey:@"engine"];
    NSCAssert([a solvePortableSafe:safe owner:owner] && portableFixtureFinished(NULL,safe) && e.inputs==8 && !memcmp(answers,input,sizeof(input)),@"portable action submits the actual native sequence, confirms input, and requests normal puzzle completion");
    NSUInteger inputs=e.inputs;NSCAssert(![a solvePortableSafe:safe owner:owner] && e.inputs==inputs,@"a completed puzzle cannot issue another solve/reward");safe[0xbf]=0;
    for(NSString *flag in @[@"wrongThread",@"wrongType",@"missingSetter"]){[e setValue:@YES forKey:flag];NSCAssert(![a solvePortableSafe:safe owner:owner] && e.inputs==inputs,@"invalid native context and missing methods reject before mutation");[e setValue:@NO forKey:flag];}
    a.opened=NULL;NSCAssert(![a solvePortableSafe:safe owner:owner] && e.inputs==inputs,@"closed/changed inventory context never mutates a retained old puzzle");a.opened=safe;
    owner.alive=NO;NSCAssert(![a solvePortableSafe:safe owner:owner] && e.inputs==inputs,@"invalid weak owner rejects solve");owner.alive=YES;
    safe[0xc0]=1;NSCAssert(![a solvePortableSafe:safe owner:owner] && e.inputs==inputs,@"demo animation is not an active puzzle");safe[0xc0]=0;
    answers[7]=answers[0];NSCAssert(![a solvePortableSafe:safe owner:owner] && e.inputs==inputs,@"malformed duplicate answer values reject without clearing user input");answers[7]=4;
    e.listCount=7;NSCAssert(![a solvePortableSafe:safe owner:owner] && e.inputs==inputs,@"unexpected list size rejects before any indexed native call");e.listCount=8;
    for(NSNumber *badCount in @[@(-1),@1,@7,@9]){e.inputListCount=badCount.intValue;NSUInteger clears=e.clears;NSCAssert(![a solvePortableSafe:safe owner:owner] && e.clears==clears && e.inputs==inputs,@"unexpected input sizes reject before mutation");}
    e.inputListCount=0;e.missingResize=YES;NSUInteger clears=e.clears;
    NSCAssert(![a solvePortableSafe:safe owner:owner] && e.clears==clears && e.inputs==inputs,@"empty input without native initializer rejects before mutation");e.missingResize=NO;
    e.rejectResize=YES;NSCAssert(![a solvePortableSafe:safe owner:owner] && !portableFixtureFinished(NULL,safe) && e.inputs==inputs && e.resizes==1,@"failed native resize cannot index an empty list or complete");e.rejectResize=NO;
    NSCAssert([a solvePortableSafe:safe owner:owner] && e.inputListCount==8 && e.resizes==2 && e.inputs==inputs+8 && !memcmp(answers,input,sizeof(input)),@"fresh empty Claire puzzle initializes via native API before solving");safe[0xbf]=0;
    e.rejectInput=YES;NSCAssert(![a solvePortableSafe:safe owner:owner] && !portableFixtureFinished(NULL,safe),@"failed input readback never marks the puzzle solved");e.rejectInput=NO;
    e.incorrectPrefix=YES;NSCAssert(![a solvePortableSafe:safe owner:owner] && !portableFixtureFinished(NULL,safe),@"native incorrect-prefix result prevents completion");e.incorrectPrefix=NO;
    const RE2FeatureInfo *info=RE2FeatureInfoAt(RE2FeaturePortableSafe);NSCAssert(info->oneShot && info->key==109 && info->modifiers==2,@"portable action is exclusively Alt-F10 and never a persistent toggle");
}
typedef struct {float play,effective;} SpeedFixtureData;
@interface RE2SpeedFixtureEngine : MTRE2Engine
@property(nonatomic,assign) void *controller;
@property(nonatomic) BOOL rejectMotionWrites;
@end
static float fixtureGetPlay(void *ctx,void *p){(void)ctx;return ((SpeedFixtureData *)p)->play;}
static float fixtureGetMotion(void *ctx,void *p){(void)ctx;return ((SpeedFixtureData *)p)->effective;}
static void fixtureSetPlay(void *ctx,void *p,float v){(void)ctx;((SpeedFixtureData *)p)->play=v;}
static void fixtureSetMotion(void *ctx,void *p,float v){if(!((__bridge RE2SpeedFixtureEngine *)ctx).rejectMotionWrites)((SpeedFixtureData *)p)->effective=v;}
@implementation RE2SpeedFixtureEngine
- (BOOL)isGameThread {return YES;}
- (void *)threadContext {return (__bridge void *)self;}
- (uint32_t)typeOf:(const void *)p {return p && p==self.controller ? 31594 : UINT32_MAX;}
- (void *)method:(uint32_t)i owner:(uint32_t)owner {if(owner!=23201)return NULL;switch(i){case 191873:return (void *)fixtureGetPlay;case 191874:return (void *)fixtureSetPlay;case 191875:return (void *)fixtureGetMotion;case 191876:return (void *)fixtureSetMotion;default:return NULL;}}
@end
@interface RE2SpeedFixtureAdapter : RE2NativeAdapter
@property(nonatomic,assign) void *local;
@end
@implementation RE2SpeedFixtureAdapter
- (void *)localMotionController {return self.local;}
@end
static void re2SpeedTests(void){
    SpeedFixtureData first={1,1},next={2,2};
    RE2SpeedFixtureEngine *e=[RE2SpeedFixtureEngine new];e.controller=&first;
    RE2PortableFixtureOwner *owner=[RE2PortableFixtureOwner new];owner.owned=&first;owner.alive=YES;
    RE2SpeedFixtureAdapter *a=[RE2SpeedFixtureAdapter new];a.local=&first;[a setValue:e forKey:@"engine"];[a setValue:owner forKey:@"speedOwner"];
    for(int i=0;i<500;i++)NSCAssert([a applyLocalSpeedFactor:2 controller:&first owner:owner] && first.play==2 && first.effective==2,@"repeated native speed application stays exactly 2x");
    first.play=1;NSCAssert([a applyLocalSpeedFactor:2 controller:&first owner:owner] && first.play==2 && first.effective==2,@"reset input with inherited scaled output must not double motion to 4x");
    NSCAssert([a applyLocalSpeedFactor:3 controller:&first owner:owner] && first.play==3 && first.effective==3,@"factor changes use the clean baseline, never the previous multiplier");
    [a releaseFeature:RE2FeatureSpeed];NSCAssert(first.play==1 && first.effective==1,@"disable restores both the input and actual motion immediately");
    [a applyLocalSpeedFactor:2 controller:&first owner:owner];owner.alive=NO;[a releaseFeature:RE2FeatureSpeed];
    NSCAssert(first.play==2,@"invalidated owners are not written during release");
    RE2PortableFixtureOwner *replacement=[RE2PortableFixtureOwner new];replacement.owned=&next;replacement.alive=YES;e.controller=&next;a.local=&next;[a setValue:replacement forKey:@"speedOwner"];
    for(int i=0;i<10;i++)NSCAssert([a applyLocalSpeedFactor:2 controller:&next owner:replacement] && next.play==2 && next.effective==2,@"a new controller inheriting our 2x write must never multiply it into 4x/8x/16x");
    [a releaseFeature:RE2FeatureSpeed];NSCAssert(next.play==1 && next.effective==1,@"carried controller write restores to the clean original, not inherited 2x");
    // Also cover a successful old-owner restoration followed by a cloned 2x input.
    next.play=2;next.effective=2;NSCAssert([a applyLocalSpeedFactor:2 controller:&next owner:replacement] && next.play==2,@"recent clean history survives a controller rebind even after successful old restore");
    next.effective=1;[a applyLocalSpeedFactor:2 controller:&next owner:replacement];[a releaseFeature:RE2FeatureSpeed];
    NSCAssert(next.play==1 && next.effective==0.5f,@"speed release preserves a new environmental slow factor");
    next.effective=1;[a applyLocalSpeedFactor:2 controller:&next owner:replacement];next.play=1;[a releaseFeature:RE2FeatureSpeed];[a restorePendingLocalSpeed];
    NSCAssert(next.play==1 && next.effective==1,@"off also clears our carried output when the game already reset the input");
    next.effective=1;[a applyLocalSpeedFactor:2 controller:&next owner:replacement];replacement.alive=NO;[a releaseFeature:RE2FeatureSpeed];replacement.alive=YES;[a restorePendingLocalSpeed];
    NSCAssert(next.play==1 && next.effective==1,@"off request made during invalid ownership is restored when a valid local controller returns");
    [a applyLocalSpeedFactor:2 controller:&next owner:replacement];next.play=0.8f;next.effective=0.8f;[a releaseFeature:RE2FeatureSpeed];[a restorePendingLocalSpeed];
    NSCAssert(next.play==0.8f && next.effective==0.8f,@"subsequent foreign changes survive tempo cleanup");
    next.play=1;next.effective=1;e.rejectMotionWrites=YES;
    NSCAssert(![a applyLocalSpeedFactor:2 controller:&next owner:replacement] && next.play==1 && next.effective==1,@"failed effective-motion write rolls back input and is never reported active");
}
@interface RE2ContinuousFixtureEngine : RE2SpeedFixtureEngine
@property(nonatomic,assign) void *condition,*equipment,*weapon;
@property(nonatomic) BOOL loading;
@end
static BOOL continuousFixtureLoading(void *ctx){return ((__bridge RE2ContinuousFixtureEngine *)ctx).loading;}
static void *continuousFixtureCondition(void *ctx,void *manager){(void)manager;return ((__bridge RE2ContinuousFixtureEngine *)ctx).condition;}
static void *continuousFixtureEquipment(void *ctx,void *condition){(void)condition;return ((__bridge RE2ContinuousFixtureEngine *)ctx).equipment;}
static void *continuousFixtureWeapon(void *ctx,void *equipment){(void)equipment;return ((__bridge RE2ContinuousFixtureEngine *)ctx).weapon;}
@implementation RE2ContinuousFixtureEngine
- (void *)singletonAt:(uintptr_t)slot {return slot==0x10b190e18 ? (__bridge void *)self : NULL;}
- (void *)method:(uint32_t)i owner:(uint32_t)owner {
    if(i==351452 && owner==18897)return (void *)continuousFixtureLoading;
    if(i==RE2Method_Player_get_CurrentPlayerCondition && owner==RE2Type_Player)return (void *)continuousFixtureCondition;
    if(i==RE2Method_Condition_get_Equipment && owner==RE2Type_Condition)return (void *)continuousFixtureEquipment;
    if(i==RE2Method_Equipment_get_MainWeapon && owner==RE2Type_Equipment)return (void *)continuousFixtureWeapon;
    return [super method:i owner:owner];
}
@end
@interface RE2ContinuousFixtureAdapter : RE2SpeedFixtureAdapter
@property(nonatomic) NSUInteger releases;
@end
@implementation RE2ContinuousFixtureAdapter
- (void)releaseEffects {self.releases++;[super releaseEffects];}
@end
static void fixtureAdapterPointer(RE2NativeAdapter *a,const char *name,void *pointer){
    // Only our allocated test adapter's native-pointer ivars; never a game process.
    Ivar ivar=class_getInstanceVariable(RE2NativeAdapter.class,name);NSCAssert(ivar,@"expected test adapter ivar");
    memcpy((uint8_t *)(__bridge void *)a+ivar_getOffset(ivar),&pointer,sizeof(pointer));
}
static void re2ContinuousTempoTests(void){
    uint8_t condition[0x20]={0},equipment[0x180]={0},gun[0x180]={0},otherGun[0x180]={0},foreign[0x20]={0};
    void *conditionPointer=condition,*equipmentPointer=equipment,*cachedSlot=otherGun;
    memcpy(equipment+0xd8,&conditionPointer,8);memcpy(gun+0xd0,&equipmentPointer,8);memcpy(otherGun+0xd0,&equipmentPointer,8);
    SpeedFixtureData speed={1,1};RE2ContinuousFixtureEngine *e=[RE2ContinuousFixtureEngine new];e.controller=&speed;e.condition=condition;e.equipment=equipment;e.weapon=gun;
    RE2PortableFixtureOwner *player=[RE2PortableFixtureOwner new];player.alive=YES;player.owned=condition;
    RE2PortableFixtureOwner *motion=[RE2PortableFixtureOwner new];motion.alive=YES;motion.owned=&speed;
    RE2ContinuousFixtureAdapter *a=[RE2ContinuousFixtureAdapter new];a.local=&speed;[a setValue:e forKey:@"engine"];[a setValue:player forKey:@"playerOwner"];[a setValue:motion forKey:@"speedOwner"];
    fixtureAdapterPointer(a,"_condition",condition);fixtureAdapterPointer(a,"_equipment",equipment);fixtureAdapterPointer(a,"_gun",gun);
    NSMutableDictionary *desired=[a valueForKey:@"desired"];desired[@(RE2FeatureSpeed)]=@2;
    NSCAssert([a continuousContextValid],@"native equipped weapon is valid even when the raw cached slot at e8 differs");
    for(int i=0;i<500;i++){[a continuousFrame];NSCAssert(a.releases==0 && speed.play==2 && speed.effective==2,@"full production frame pump must never alternate 2x and 1x for a stable native weapon binding");}
    e.weapon=NULL;fixtureAdapterPointer(a,"_gun",NULL);memcpy(equipment+0xe8,&cachedSlot,8);
    for(int i=0;i<100;i++){[a continuousFrame];NSCAssert(a.releases==0 && speed.play==2 && speed.effective==2,@"no current main weapon with stale cached slot also retains continuous local movement tempo");}
    e.weapon=otherGun;[a continuousFrame];NSCAssert(a.releases==1 && speed.play==1 && speed.effective==1 && desired.count==0,@"a real native weapon change still releases old effects safely");
    fixtureAdapterPointer(a,"_gun",otherGun);desired[@(RE2FeatureSpeed)]=@2;
    for(int i=0;i<100;i++){[a continuousFrame];NSCAssert(a.releases==1 && speed.play==2 && speed.effective==2,@"fresh native weapon binding resumes smoothly without repeated releases");}
    e.loading=YES;[a continuousFrame];NSCAssert(a.releases==2 && speed.play==1 && speed.effective==1,@"real loading still returns both local speed values");e.loading=NO;
    e.condition=foreign;NSCAssert(![a continuousContextValid],@"real player context change rejects the old binding");e.condition=condition;
    e.equipment=foreign;NSCAssert(![a continuousContextValid],@"real equipment change rejects the old binding");e.equipment=equipment;
    memset(otherGun+0xd0,0,8);NSCAssert(![a continuousContextValid],@"foreign or invalid native weapon owner never validates as the cached local weapon");
}
static BOOL fixtureRE2Menu(void *context,void *gui){(void)context;(void)gui;return YES;}
@interface RE2MouseFixtureEngine : MTRE2Engine
@property(nonatomic,assign) void *mouseDevice;
@property(nonatomic) BOOL menuActive;
@property(nonatomic) uintptr_t mouseSlot;
@end
@implementation RE2MouseFixtureEngine
- (BOOL)isGameThread {return YES;}
- (void *)singletonAt:(uintptr_t)slot {return slot==(self.mouseSlot ?: 0x108a48770) ? self.mouseDevice : slot==0x10b15bc38 && self.menuActive ? (__bridge void *)self : NULL;}
- (uint32_t)typeOf:(const void *)object {return object==(__bridge const void *)self ? 7343 : UINT32_MAX;}
- (void *)method:(uint32_t)index owner:(uint32_t)owner {return owner==7343 && (index==115375 || index==115377 || index==115379 || index==115381) ? (void *)fixtureRE2Menu : NULL;}
@end
static void re2MouseTests(void){
    uint8_t device[0x200]={0};device[0x169]=1;
    RE2MouseFixtureEngine *engine=[RE2MouseFixtureEngine new];engine.mouseDevice=device;
    RE2NativeAdapter *adapter=[RE2NativeAdapter new];[adapter setValue:engine forKey:@"engine"];
    NSCAssert([adapter setOverlayInteraction:YES] && device[0x168]==1 && device[0x169]==0 && device[0x16b]==1,@"RE2 title UI grants mouse without a loaded player");
    engine.menuActive=YES;device[0x168]=0;
    NSCAssert([adapter setOverlayInteraction:YES] && device[0x168]==1,@"RE2 menu/controller cursor hiding is overridden while UI is visible");
    NSCAssert(![adapter setOverlayInteraction:NO] && device[0x168]==0 && device[0x169]==1 && device[0x16b]==0,@"RE2 menu release restores the latest native requests");
    NSCAssert([adapter setOverlayInteraction:YES],@"RE2 paused UI can reacquire mouse without losing its lease");
    device[0x16b]=0;[adapter setOverlayInteraction:NO];
    NSCAssert(device[0x168]==0 && device[0x169]==1 && device[0x16b]==0,@"later foreign requests survive RE2 mouse release");
    uint8_t replacement[0x200]={0};replacement[0x169]=1;
    [adapter setOverlayInteraction:YES];engine.mouseDevice=replacement;[adapter setOverlayInteraction:NO];
    NSCAssert(replacement[0x168]==0 && replacement[0x169]==1 && replacement[0x16b]==0 && device[0x168]==1,@"device replacement never writes through an obsolete pointer or restores into a new device");
    replacement[0x16b]=2;
    NSCAssert(![adapter setOverlayInteraction:YES] && replacement[0x168]==0 && replacement[0x169]==1 && replacement[0x16b]==2,@"invalid cursor data rejects acquisition before any write");
}
@interface RE3MenuMouseFixture : RE3NativeAdapter
@end
@implementation RE3MenuMouseFixture
- (BOOL)menu {return YES;}
- (BOOL)localValid {return NO;}
@end
static void otherGameMouseTests(void){
    NSArray *cases=@[@[RE3MenuMouseFixture.class,@"e",@(0x1092f3a30),@(0x168)],
                     @[RE4NativeAdapter.class,@"e4",@(0x10cd8d9e8),@(0x160)],
                     @[RE7NativeAdapter.class,@"e7",@(0x108d45870),@(0x160)],
                     @[RE8NativeAdapter.class,@"e8",@(0x10cfb8d38),@(0x160)]];
    for(NSArray *testCase in cases){
        uint8_t device[0x200]={0};NSUInteger show=[testCase[3] unsignedIntegerValue];device[show+1]=1;
        RE2MouseFixtureEngine *engine=[RE2MouseFixtureEngine new];engine.mouseDevice=device;engine.mouseSlot=[testCase[2] unsignedLongLongValue];
        Class adapterClass=testCase[0];id<RE2GameAdapter> adapter=[[adapterClass alloc]init];[(NSObject *)adapter setValue:engine forKey:testCase[1]];
        NSCAssert([adapter setOverlayInteraction:YES] && device[show]==1 && device[show+1]==0 && device[show+3]==1,@"each real game adapter grants UI mouse without gameplay owners");
        device[show]=0;
        NSCAssert([adapter setOverlayInteraction:YES] && device[show]==1,@"each game renews UI visibility against a later menu/controller request");
        NSCAssert(![adapter setOverlayInteraction:NO] && device[show]==0 && device[show+1]==1 && device[show+3]==0,@"each game restores the latest request on release");
        NSCAssert([adapter setOverlayInteraction:YES],@"each game's UI can reopen after release");
        device[show+3]=0;[adapter setOverlayInteraction:NO];
        NSCAssert(device[show+3]==0 && device[show+1]==1,@"each game preserves a later foreign request on hide");
    }
}
// The real RE4 cursor method must support a paused menu. The fixture owns
// only these writable local bytes; it cannot access a game or native VM.
@interface RE4MouseFixtureEngine : MTRE2Engine
@property(nonatomic,assign) void *mouseDevice;
@end
@implementation RE4MouseFixtureEngine
- (BOOL)isGameThread {return YES;}
- (void *)singletonAt:(uintptr_t)slot {return slot==0x10cd8d9e8 ? self.mouseDevice : NULL;}
@end
@interface RE4PausedMouseFixture : RE4NativeAdapter
@end
@implementation RE4PausedMouseFixture
- (BOOL)local4 {return YES;}
- (BOOL)paused4 {return YES;}
@end
static void re4MouseTests(void){
    uint8_t device[0x200]={0};device[0x160]=1;device[0x161]=1;
    RE4MouseFixtureEngine *engine=[RE4MouseFixtureEngine new];engine.mouseDevice=device;
    RE4PausedMouseFixture *adapter=[RE4PausedMouseFixture new];[adapter setValue:engine forKey:@"e4"];
    NSCAssert([adapter setOverlayInteraction:YES] && device[0x160]==1 && device[0x161]==0 && device[0x163]==1,@"RE4 paused menus still grant the explicit overlay mouse request");
    // A menu/controller hides the cursor after acquisition. Renewing the lease
    // keeps the UI visible, but releasing must respect the new native request.
    device[0x160]=0;
    NSCAssert([adapter setOverlayInteraction:YES] && device[0x160]==1,@"a foreign cursor request cannot hide the active overlay cursor");
    NSCAssert(![adapter setOverlayInteraction:NO] && device[0x160]==0 && device[0x161]==1 && device[0x163]==0,@"release restores the latest native menu request, not a stale gameplay snapshot");
    NSCAssert([adapter setOverlayInteraction:YES],@"mouse lease can be reacquired after hiding the overlay");
    device[0x163]=0;
    [adapter setOverlayInteraction:NO];
    NSCAssert(device[0x163]==0 && device[0x161]==1,@"foreign input changes survive mouse release");
}
static void ledgerTests(void){
    RE2NativeAdapter *adapter=[RE2NativeAdapter new];uint32_t hp=5000,one=1;
    NSData *bytes=[NSData dataWithBytes:&one length:4];
    for(NSUInteger order=0;order<2;order++){
        NSCAssert([adapter applyBytes:bytes object:&hp offset:0 owner:nil global:YES feature:RE2FeatureOneHit],@"first effect writes local fixture");
        NSCAssert([adapter applyBytes:bytes object:&hp offset:0 owner:nil global:YES feature:RE2FeatureTyrant],@"second effect shares the original");
        [adapter releaseFeature:order ? RE2FeatureTyrant : RE2FeatureOneHit];NSCAssert(hp==1,@"remaining effect keeps its write");
        [adapter releaseFeature:order ? RE2FeatureOneHit : RE2FeatureTyrant];NSCAssert(hp==5000,@"last effect restores the true original in both orders");
    }
    [adapter applyBytes:bytes object:&hp offset:0 owner:nil global:YES feature:RE2FeatureTyrant];hp=2500;
    [adapter releaseFeature:RE2FeatureTyrant];NSCAssert(hp==2500,@"a subsequent foreign change is preserved");
    __block BOOL binding=YES;hp=5000;
    NSCAssert([adapter applyBytes:bytes object:&hp offset:0 owner:nil global:YES feature:RE2FeatureAmmo guard:^BOOL{return binding;}],@"guarded fixture write confirmed");
    binding=NO;[adapter releaseFeature:RE2FeatureAmmo];NSCAssert(hp==1,@"stale inventory binding cannot restore into a reassigned payload");
    hp=2500;NSCAssert(![adapter applyBytes:bytes object:&hp offset:0 owner:nil global:YES feature:RE2FeatureAmmo guard:^BOOL{return binding;}] && hp==2500,@"rejected binding never writes");
    uint64_t clock=UINT64_C(0x100000000)+123,frozen=UINT64_C(0x100000000)+99;
    NSData *wide=[NSData dataWithBytes:&frozen length:8];
    NSCAssert([adapter applyBytes:wide object:&clock offset:0 owner:nil global:YES feature:(RE2Feature)RE4FreezeTime] && clock==frozen,@"64-bit timer write and readback preserve upper bits");
    [adapter releaseFeature:(RE2Feature)RE4FreezeTime];NSCAssert(clock==UINT64_C(0x100000000)+123,@"64-bit original restored");
    [adapter applyBytes:wide object:&clock offset:0 owner:nil global:YES feature:(RE2Feature)RE4FreezeTime];clock+=100;
    [adapter releaseFeature:(RE2Feature)RE4FreezeTime];NSCAssert(clock==frozen+100,@"later foreign 64-bit timer change preserved");
    float angles[3]={1,2,3},zero=0,vectorZero[3]={0,0,0};
    NSCAssert(![adapter applyBytes:[NSData dataWithBytes:vectorZero length:sizeof(vectorZero)] object:angles offset:0 owner:nil global:YES feature:(RE2Feature)RE8Recoil] && angles[0]==1 && angles[1]==2 && angles[2]==3,@"unsupported vector width is rejected without modifying any axis");
    for(NSUInteger axis=0;axis<3;axis++)NSCAssert([adapter applyBytes:[NSData dataWithBytes:&zero length:4] object:angles offset:axis*4 owner:nil global:YES feature:(RE2Feature)RE8Recoil] && angles[axis]==0,@"individual recoil axes receive checked scalar writes");
    angles[0]=15;[adapter releaseFeature:(RE2Feature)RE8Recoil];
    NSCAssert(angles[0]==15 && angles[1]==2 && angles[2]==3,@"axis restoration preserves a foreign update while restoring the other originals");
    __block uint32_t nativeValue=7;uint32_t requested=12;__block NSUInteger reads=0,writes=0;binding=YES;
    NSData *(^readNative)(void)=^NSData *{reads++;return [NSData dataWithBytes:&nativeValue length:4];};
    void (^writeNative)(NSData *)=^(NSData *b){writes++;[b getBytes:&nativeValue length:4];};
    NSData *nativeBytes=[NSData dataWithBytes:&requested length:4];
    NSCAssert([adapter applyValueBytes:nativeBytes object:&hp offset:UINT64_MAX-1 owner:nil global:YES feature:RE2FeatureAmmo guard:^BOOL{return binding;} read:readNative write:writeNative] && nativeValue==12,@"native accessor writes use the setter and getter, never a field address");
    [adapter releaseFeature:RE2FeatureAmmo];NSCAssert(nativeValue==7 && writes==2,@"native accessor restores its captured original through the setter");
    [adapter applyValueBytes:nativeBytes object:&hp offset:UINT64_MAX-1 owner:nil global:YES feature:RE2FeatureAmmo guard:^BOOL{return binding;} read:readNative write:writeNative];
    binding=NO;NSUInteger readCount=reads,writeCount=writes;[adapter releaseFeature:RE2FeatureAmmo];
    NSCAssert(reads==readCount && writes==writeCount,@"an invalid native binding cannot even read its former payload");
    binding=YES;nativeValue=7;
    NSCAssert(![adapter applyValueBytes:nativeBytes object:&hp offset:UINT64_MAX-1 owner:nil global:YES feature:RE2FeatureAmmo guard:^BOOL{return binding;} read:readNative write:^(NSData *b){(void)b;}],@"a setter without matching readback cannot claim success");
    [adapter releaseFeature:RE2FeatureAmmo];
    NSCAssert(RE8FeatureCount==23 && RE8FeatureCount<=RE2FeatureCapacity && RE8FeatureInfoAt(-1)==NULL && RE8FeatureInfoAt(23)==NULL,@"Village catalog is bounded independently");
    for(NSInteger i=0;i<RE8FeatureCount;i++)for(NSInteger j=i+1;j<RE8FeatureCount;j++){
        const RE2FeatureInfo *a=RE8FeatureInfoAt(i),*b=RE8FeatureInfoAt(j);
        NSCAssert(a->key!=b->key || a->modifiers!=b->modifiers,@"Village hotkeys cannot overlap");
        NSCAssert(a->key!=111 && b->key!=111,@"F12 remains disable all");
    }
    for(NSNumber *f in @[@(RE8Time),@(RE8Money),@(RE8CP),@(RE8Unlock),@(RE8MercGoal)])NSCAssert(RE8FeatureInfoAt(f.integerValue)->oneShot,@"Village durable writes cannot repeat during polling");
    NSCAssert(RE7FeatureCount==15 && RE7FeatureCount<=RE2FeatureCapacity && RE7FeatureInfoAt(-1)==NULL && RE7FeatureInfoAt(15)==NULL,@"RE7 catalog is bounded independently of RE2/3/4");
    for(NSInteger i=0;i<RE7FeatureCount;i++)for(NSInteger j=i+1;j<RE7FeatureCount;j++){
        const RE2FeatureInfo *a=RE7FeatureInfoAt(i),*b=RE7FeatureInfoAt(j);
        NSCAssert(a->key!=b->key || a->modifiers!=b->modifiers,@"RE7 cheat shortcuts are distinct");
        NSCAssert(a->key!=111 && b->key!=111,@"F12 remains reserved for disable all");
    }
    NSCAssert(RE7FeatureInfoAt(RE7ResetTime)->oneShot && RE7FeatureInfoAt(RE7Scraps)->oneShot,@"RE7 durable writes must never repeat during polling");
    NSCAssert(RE4FeatureCount==36 && RE4FeatureCount<=RE2FeatureCapacity && RE2ActiveFeatureCount()==21,@"RE2 gains one portable-safe action while RE4 capacity remains valid");
    for(NSInteger i=0;i<RE4FeatureCount;i++)for(NSInteger j=i+1;j<RE4FeatureCount;j++){
        const RE2FeatureInfo *a=RE4FeatureInfoAt(i),*b=RE4FeatureInfoAt(j);
        NSCAssert(a->key!=b->key || a->modifiers!=b->modifiers,@"all 36 RE4 shortcuts are distinct");
    }
    for(NSNumber *f in @[@(RE4Unlock),@(RE4Pesetas),@(RE4Spinels),@(RE4CP),@(RE4SaveCount),@(RE4AdjustTime),@(RE4Tickets),@(RE4GoldTokens),@(RE4SilverTokens)])NSCAssert(RE4FeatureInfoAt(f.integerValue)->implemented && RE4FeatureInfoAt(f.integerValue)->oneShot,@"durable RE4 actions must never repeat during polling");
    NSCAssert([RE2FeatureInfoForGame(RE2FeatureRibbons,NO)->title isEqual:@"Unbegrenzte Farbbänder"] && [RE2FeatureInfoForGame(RE2FeatureRibbons,YES)->title isEqual:@"Unverwundbarkeit: Treffer ignorieren"],@"game-specific catalogs preserve RE2 functions");
    NSCAssert(RE2FeatureInfoForGame(RE2FeatureBoards,YES)->oneShot && RE2FeatureInfoForGame(RE2FeatureBoards,YES)->integer && !RE2FeatureInfoForGame(RE2FeatureBoards,NO)->oneShot,@"shop action cannot become a continuously repeated write");
    for(NSInteger i=0;i<RE3FeatureCount;i++)for(NSInteger j=i+1;j<RE3FeatureCount;j++){
        const RE2FeatureInfo *a=RE2FeatureInfoForGame(i,YES),*b=RE2FeatureInfoForGame(j,YES);
        NSCAssert(a->key!=b->key || a->modifiers!=b->modifiers,@"RE3 cheat shortcuts are distinct");
    }

}
static void highlightStopTests(void){
    // This feature owns native drawing requests, not entries in the value ledger.
    // F12/context release must also drop its weak owner/payload bindings.
    RE2NativeAdapter *adapter=[RE2NativeAdapter new];
    NSMutableDictionary *bindings=[NSMutableDictionary dictionaryWithObject:[NSObject new] forKey:[NSValue valueWithPointer:(void *)1]];
    [adapter setValue:bindings forKey:@"highlightOwners"];
    [adapter setValue:@3 forKey:@"highlightConfirmed"];
    [adapter releaseEffects];
    NSCAssert(!bindings.count && [[adapter valueForKey:@"highlightConfirmed"] unsignedIntegerValue]==0,@"F12/context release clears drawing owners without a value-ledger entry");
}
static void drain(void){for(int i=0;i<16;i++)[NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];}
static NSDictionary *savedSelection(void){
    RE2TrainerState *state=[RE2TrainerState new];state.features[RE2FeatureHealth].wanted=YES;
    state.features[RE2FeatureSlowMotion].wanted=YES;state.features[RE2FeatureSlowMotion].value=0.4;
    state.features[RE2FeatureSaveCount].wanted=YES;
    return RE2SelectionFromState(state,@"re2-mac-1.0.2");
}
static void selectionTests(void){
    NSString *profile=@"re2-mac-1.0.2";NSDictionary *saved=savedSelection();
    NSCAssert([saved[@"features"][RE2FeatureHealth][@"wanted"] boolValue] && ![saved[@"features"][RE2FeatureSaveCount][@"wanted"] boolValue],@"selection persists toggles but excludes every one-shot activation");
    NSCAssert([RE2DecodeSelection(RE2EncodeSelection(saved),profile) isEqual:saved],@"selection survives the actual JSON launch encoding");
    NSCAssert(!RE2NormalizeSelection(saved,@"re3-mac-1.0.0") && !RE2DecodeSelection(@"broken",profile),@"foreign games and malformed launch data cannot restore cheats");
    NSString *message=RE2SelectionMessage(saved,@"session-A",123);
    NSCAssert([RE2SelectionMessageOptions(message,profile,@"session-A",123) isEqual:saved],@"current game session notification can persist its choices");
    NSCAssert(!RE2SelectionMessageOptions(message,profile,@"session-B",123) && !RE2SelectionMessageOptions(message,profile,@"session-A",124),@"stale or foreign notifications cannot overwrite saved choices");
    NSMutableDictionary *legacy=[saved mutableCopy];legacy[@"features"]=[saved[@"features"] subarrayWithRange:NSMakeRange(0,RE2FeaturePortableSafe)];
    NSDictionary *migrated=RE2NormalizeSelection(legacy,profile);
    NSCAssert([migrated[@"features"] count]==RE2FeatureCount && [migrated[@"features"][0][@"wanted"] boolValue] && ![migrated[@"features"][RE2FeaturePortableSafe][@"wanted"] boolValue],@"old RE2 selections preserve their toggles while the new one-shot stays off");
    NSCAssert(RE2SelectionCount(@"re3-mac-1.0.0")==20 && !RE2FeatureInfoForGame(RE2FeaturePortableSafe,YES),@"RE3 never inherits the RE2 portable-safe action");
    NSMutableDictionary *bad=[saved mutableCopy];NSMutableArray *rows=[saved[@"features"] mutableCopy];NSMutableDictionary *row=[rows[RE2FeatureSlowMotion] mutableCopy];row[@"value"]=@999;rows[RE2FeatureSlowMotion]=row;bad[@"features"]=rows;
    NSCAssert([RE2NormalizeSelection(bad,profile)[@"features"][RE2FeatureSlowMotion][@"value"] doubleValue]==0.5,@"out-of-range saved numeric values fall back to the valid catalog default");
    row=[rows[0] mutableCopy];row[@"binding"]=@"obsolete";rows[0]=row;
    NSCAssert(!RE2NormalizeSelection(bad,profile),@"a changed feature binding rejects the saved catalog");
    NSMutableSet *keys=[NSMutableSet new];
    for(NSString *p in @[@"re2-mac-1.0.2",@"re3-mac-1.0.0",@"re4-mac-1.0.7",@"re7-mac-1.0.4",@"re8-mac-1.1.8"]){
        RE2TrainerState *state=[RE2TrainerState new];NSMutableArray *features=[NSMutableArray new];
        for(NSInteger i=0;i<RE2SelectionCount(p);i++){RE2FeatureState *f=[RE2FeatureState new];f.wanted=YES;f.value=NAN;[features addObject:f];}state.features=features;
        NSDictionary *snapshot=RE2SelectionFromState(state,p);NSCAssert(snapshot && [RE2DecodeSelection(RE2EncodeSelection(snapshot),p) isEqual:snapshot],@"each of the five real game catalogs round-trips independently");[keys addObject:RE2SelectionKey(p)];
    }NSCAssert(keys.count==5,@"five separate persistent game keys");
    RE2TestAdapter *a=[RE2TestAdapter new];a.mode=RE2SessionLoading;
    RE2GameBridge *b=[[RE2GameBridge alloc]initWithAdapter:a readOnly:NO restoreSelection:saved];[b poll];drain();
    NSCAssert(b.state.selectionPending && !b.state.features[0].active && a.oneShots==0,@"startup selection waits without applying cheats or one-shots during loading");
    a.mode=RE2SessionSolo;[b poll];drain();NSCAssert(!b.state.selectionPending && b.state.features[0].active && b.state.features[RE2FeatureSlowMotion].value==0.4 && a.oneShots==0,@"first valid owner restores selected toggles and values without replaying one-shots");
    a.mode=RE2SessionLoading;[b poll];drain();a.mode=RE2SessionSolo;[b poll];drain();NSCAssert(b.state.features[0].active,@"later loading retains current choices instead of reimporting old startup data");
    a=[RE2TestAdapter new];a.mode=RE2SessionLoading;b=[[RE2GameBridge alloc]initWithAdapter:a readOnly:NO restoreSelection:saved];[b performAction:RE2TrainerDisableAll];drain();a.mode=RE2SessionSolo;[b poll];drain();
    NSCAssert(!b.state.features[0].wanted && !b.state.selectionPending,@"F12 cancels even a pending startup restore");
    a=[RE2TestAdapter new];a.mode=RE2SessionNetwork;b=[[RE2GameBridge alloc]initWithAdapter:a readOnly:NO restoreSelection:saved];[b poll];drain();a.mode=RE2SessionSolo;[b poll];drain();
    NSCAssert(!b.state.features[0].wanted,@"network entry permanently cancels startup restoration");
    b=[[RE2GameBridge alloc]initWithAdapter:a readOnly:YES restoreSelection:saved];[b poll];drain();NSCAssert(!b.state.selectionPending && !b.state.features[0].wanted,@"inspection cannot import cheat selections");
    NSString *suite=[@"local.mactrainer.selection-test." stringByAppendingString:NSUUID.UUID.UUIDString];NSUserDefaults *prefs=[[NSUserDefaults alloc]initWithSuiteName:suite];
    [prefs setObject:saved forKey:RE2SelectionKey(profile)];[prefs setBool:YES forKey:RE2RestoreCheatsKey];[prefs synchronize];
    NSUserDefaults *reopened=[[NSUserDefaults alloc]initWithSuiteName:suite];NSCAssert([reopened boolForKey:RE2RestoreCheatsKey] && [RE2NormalizeSelection([reopened objectForKey:RE2SelectionKey(profile)],profile) isEqual:saved],@"persisted option and per-game choices survive reopening the preferences store");[prefs removePersistentDomainForName:suite];
}
static void bridgeTests(void){
 RE2TestAdapter *a=[RE2TestAdapter new];RE2GameBridge *b=[[RE2GameBridge alloc]initWithAdapter:a];
 [b poll];drain();NSCAssert(b.state.ready,@"confirmed local context ready");
 [b performFeature:RE2FeatureHealth];[b performFeature:RE2FeatureSlowMotion];drain();
 NSCAssert(b.state.features[RE2FeatureHealth].active && b.state.features[RE2FeatureSlowMotion].active,@"only confirmed readback activates effects");
 a.confirmed=NO;[b poll];drain();NSCAssert(!b.state.features[RE2FeatureHealth].active,@"failed readback cannot appear active");a.confirmed=YES;
 [b setValue:0.4 forFeature:RE2FeatureSlowMotion];drain();NSCAssert(b.state.features[RE2FeatureSlowMotion].value==0.4,@"valid factor accepted");
 [b setValue:NAN forFeature:RE2FeatureSlowMotion];[b setValue:50 forFeature:RE2FeatureSlowMotion];drain();NSCAssert(b.state.features[RE2FeatureSlowMotion].value==0.4,@"invalid factors rejected");
 a.mode=RE2SessionLoading;[b poll];drain();NSCAssert(!b.state.ready && b.state.features[0].wanted && !b.state.features[0].active,@"loading preserves choices and releases effects");
 a.identity=@"world-B/owner-B";a.mode=RE2SessionSolo;[b poll];drain();NSCAssert(b.state.features[0].active,@"new owner revalidated");
 NSUInteger before=a.oneShots;[b poll];[b performFeature:RE2FeatureSaveCount];a.identity=@"world-C/owner-C";drain();NSCAssert(a.oneShots==before,@"stale one-shot rejected after owner change");
 a.mode=RE2SessionNetwork;[b poll];[b setOverlayInteraction:YES];drain();NSCAssert(!b.state.features[0].wanted && b.state.overlayMouseActive,@"network clears cheats and preserves stop/UI access");
 [b performFeature:RE2FeatureSaveCount];drain();NSCAssert(a.oneShots==before,@"network rejects one-shots");
 a.mode=RE2SessionSolo;[b poll];drain();[b performFeature:RE2FeatureHealth];drain();
 [b poll];for(int i=0;i<24;i++)[b performFeature:RE2FeatureSaveCount];[b performAction:RE2TrainerDisableAll];a.mode=RE2SessionLoading;drain();NSCAssert(!b.state.features[0].wanted,@"F12 wins over full queue during loading");
 RE2GameBridge *u=[[RE2GameBridge alloc]initWithAdapter:[RE2UnsupportedAdapter new]];[u poll];[u performFeature:RE2FeatureHealth];drain();NSCAssert(!u.state.ready && !u.state.features[0].active,@"unsupported adapter never applies effects");
 RE2TestAdapter *probe=[RE2TestAdapter new];RE2GameBridge *inspection=[[RE2GameBridge alloc]initWithAdapter:probe readOnly:YES];
 [inspection poll];drain();[inspection performFeature:RE2FeatureHealth];[inspection performFeature:RE2FeatureSaveCount];[inspection setValue:0.2 forFeature:RE2FeatureSlowMotion];[inspection setOverlayInteraction:YES];drain();
 NSCAssert(!inspection.state.ready && !inspection.state.features[0].wanted && !inspection.state.features[0].active && probe.applications==0 && probe.oneShots==0,@"inspection reads real context but cannot call effect or one-shot paths");
 NSCAssert(inspection.state.overlayMouseActive && inspection.state.features[RE2FeatureSlowMotion].value==0.5,@"inspection allows overlay interaction while rejecting effect values");
 [inspection performAction:RE2TrainerDisableAll];drain();NSCAssert(probe.applications==0 && probe.oneShots==0,@"F12 keeps inspection free of effect applications");
}
static NSEvent *mouse(NSWindow *window,NSView *view,NSPoint p,NSEventType type){return [NSEvent mouseEventWithType:type location:[view convertPoint:p toView:nil] modifierFlags:0 timestamp:0 windowNumber:window.windowNumber context:nil eventNumber:1 clickCount:1 pressure:1];}
static void uiTests(void){
    [NSApplication sharedApplication];
    NSWindow *w=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,1000,620) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];w.releasedWhenClosed=NO;
    RE2OverlayRoot *r=[[RE2OverlayRoot alloc]initWithFrame:NSMakeRect(20,30,950,550) version:@"RE2 UI TEST"];
    NSCAssert(!r.panelVisible && r.panel.hidden && r.badge.hidden && !r.wantsMouseInteraction,@"fresh overlay starts completely hidden without requesting mouse input");
    [w.contentView addSubview:r];RE2TrainerState *s=[RE2TrainerState new];s.ready=YES;[r updateState:s];
    __block NSInteger clicks=0;
    for(NSNumber *scale in @[@0.7,@0.9,@1.3])for(NSString *pos in @[@"top-left",@"bottom-right",@"center"]){
        [r applyOverlayOptions:@{@"visible":@YES,@"scale":scale,@"position":pos}];
        NSCAssert(NSContainsRect(r.bounds,r.panel.frame),@"panel fits window");
        for(NSInteger i=0;i<RE2FeatureCount;i++){
            if(!RE2FeatureInfoAt(i)->implemented)continue;
            r.featureHandler=^(RE2Feature f){NSCAssert(f==i,@"correct click target");clicks++;};
            NSView *row=((MTTrainerMaterial *)r.panel).contentView.subviews[i];NSInteger before=clicks;
            NSCAssert([r handleMouseEvent:mouse(w,row,NSMakePoint(244,10),NSEventTypeLeftMouseDown)],@"click consumed");
            NSCAssert([r handleMouseEvent:mouse(w,row,NSMakePoint(244,10),NSEventTypeLeftMouseUp)],@"release consumed");NSCAssert(clicks==before+1,@"one dispatch per click");
        }
    }
    [r applyOverlayOptions:@{@"visible":@YES,@"mouse":@NO}];NSCAssert(r.wantsMouseInteraction,@"legacy mouse-off preferences cannot leave visible UI unclickable");
    r.featureHandler=^(RE2Feature f){NSCAssert(f==RE2FeatureHealth,@"automatic mouse reaches the intended cheat");clicks++;};NSInteger before=clicks;
    NSView *firstRow=((MTTrainerMaterial *)r.panel).contentView.subviews[0];
    NSCAssert([r handleMouseEvent:mouse(w,firstRow,NSMakePoint(244,10),NSEventTypeLeftMouseDown)] && clicks==before+1,@"visible UI accepts a click without a separate mouse shortcut");
    [r togglePanel:nil];NSCAssert(r.panel.hidden && !r.wantsMouseInteraction,@"hide gives game input back");
    NSCAssert([r handleMouseEvent:mouse(w,firstRow,NSMakePoint(244,10),NSEventTypeLeftMouseUp)],@"a click begun in UI never leaks its release to the game after hiding");
    NSCAssert(![r handleMouseEvent:mouse(w,firstRow,NSMakePoint(244,10),NSEventTypeLeftMouseDown)],@"hidden UI passes new gameplay clicks through");
    s.ready=NO;[r updateState:s];__block NSInteger stops=0;r.actionHandler=^(RE2TrainerAction action){NSCAssert(action==RE2TrainerDisableAll,@"F12 stop");stops++;};
    NSEvent *f12=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:111];[r handleEvent:f12];NSCAssert(stops==1,@"F12 works during loading");
    RE2OverlayShortcuts *keys=[RE2OverlayShortcuts new];keys.enabled=YES;[keys setRegistered:YES shortcut:RE2ShortcutPanel];__block int toggles=0;keys.handler=^(RE2OverlayShortcut action){(void)action;toggles++;};
    [keys nativeShortcut:RE2ShortcutPanel pressed:YES];[keys nativeShortcut:RE2ShortcutPanel pressed:YES];NSCAssert(toggles==1,@"native repeats cannot toggle twice");[keys nativeShortcut:RE2ShortcutPanel pressed:NO];[keys nativeShortcut:RE2ShortcutPanel pressed:YES];NSCAssert(toggles==2,@"fresh press toggles");
    keys.enabled=NO;NSCAssert(![keys nativeShortcut:RE2ShortcutPanel pressed:YES],@"inactive app owns no hotkeys");
    NSEvent *toggle=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:0 windowNumber:w.windowNumber context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:10];
    BOOL visible=r.panelVisible;[r handleEvent:toggle];NSCAssert(r.panelVisible && r.wantsMouseInteraction,@"Command caret opens and automatically requests mouse input");
    [r handleEvent:toggle];NSCAssert(r.panelVisible==visible && !r.wantsMouseInteraction,@"Command caret hides and releases mouse input together");
    NSEvent *commandF10=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:0 windowNumber:w.windowNumber context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:109];
    NSCAssert(RE2ShortcutForEvent(commandF10)<0 && ![r handleEvent:commandF10],@"Command F10 is not an overlay shortcut");
    s.ready=YES;[r updateState:s];__block NSInteger timeActions=0;r.featureHandler=^(RE2Feature f){NSCAssert(f==RE2FeatureGameTime,@"F10 belongs to game time");timeActions++;};
    NSEvent *plainF10=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:w.windowNumber context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:109];
    [r handleEvent:plainF10];NSCAssert(timeActions==1 && r.panelVisible==visible,@"F10 runs its cheat without toggling the overlay");
    NSCAssert(!RE2OverlayMessageOptions(RE2OverlayMessage(@{},@"A",12),@"B",12),@"foreign settings sessions ignored");
    NSDictionary *launch=RE2OverlayOptionsForLaunch(@{@"visible":@YES,@"badge":@YES,@"mouse":@NO,@"scale":@1.1,@"position":@"center"});
    NSCAssert(![launch[@"visible"] boolValue] && ![launch[@"badge"] boolValue] && [launch[@"mouse"] boolValue],@"every fresh launch overrides saved visible/badge and obsolete mouse-off preferences");
    NSCAssert([launch[@"scale"] isEqual:@1.1] && [launch[@"position"] isEqual:@"center"],@"launch keeps panel geometry");
    [r applyOverlayOptions:launch];[r toggleMouseInteraction];[r toggleMouseInteraction];NSCAssert(r.panelVisible && r.wantsMouseInteraction,@"former mouse shortcut only reveals interactive UI and cannot disable automatic mouse input");
    NSEvent *escape=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:w.windowNumber context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:53];
    NSCAssert([r handleEvent:escape] && !r.panelVisible && !r.wantsMouseInteraction,@"Escape closes UI and releases mouse without another shortcut");
    [w close];
}
static void profileTests(NSString *configPath){
    NSError *error=nil;NSDictionary *config=MTLoadConfiguration(configPath,&error);NSCAssert(config && !error,@"valid template config");NSCAssert(!MTLoadConfiguration(nil,NULL),@"missing config fails safely");
    NSCAssert(!MTInspectGame(@"relative.app",config[@"profiles"][0],NULL),@"disabled/missing identity never launches");
    NSCAssert(!MTCurrentProcessMatches(config[@"profiles"][0],@"/unknown"),@"disabled profile never installs runtime");
    NSString *folder=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];[NSFileManager.defaultManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL];
    @try{
        NSString *file=[folder stringByAppendingPathComponent:@"fake-executable"];
        struct mach_header_64 h={.magic=MH_MAGIC_64,.cputype=CPU_TYPE_ARM64,.filetype=MH_EXECUTE,.ncmds=1,.sizeofcmds=sizeof(struct uuid_command)};
        struct uuid_command u={.cmd=LC_UUID,.cmdsize=sizeof(u)};NSUUID *uuid=[NSUUID UUID];[uuid getUUIDBytes:u.uuid];NSMutableData *data=[NSMutableData dataWithBytes:&h length:sizeof(h)];[data appendBytes:&u length:sizeof(u)];[data writeToFile:file atomically:YES];
        NSCAssert([MTReadExecutableIdentity(file)[@"uuid"] isEqual:uuid.UUIDString],@"exact arm64 identity read");
        h.ncmds=2;memcpy(data.mutableBytes,&h,sizeof(h));[data writeToFile:file atomically:YES];NSCAssert(!MTReadExecutableIdentity(file),@"truncated Mach-O rejected");
        NSMutableDictionary *bad=[config mutableCopy];bad[@"profiles"]=@[@{@"id":@"bad",@"name":@"Bad",@"enabled":@YES,@"bundleIdentifier":@"example.game",@"executable":@"Game",@"uuids":@[]}];
        NSString *json=[folder stringByAppendingPathComponent:@"bad.json"];[[NSJSONSerialization dataWithJSONObject:bad options:0 error:NULL]writeToFile:json atomically:YES];NSCAssert(!MTLoadConfiguration(json,NULL),@"active profile without UUID denied");
    }@finally{[NSFileManager.defaultManager removeItemAtPath:folder error:NULL];}
    uint8_t byte;NSCAssert(!MTReadMemory((void *)1,&byte,1) && !MTWriteByte((void *)1,0,1),@"unmapped memory denied");
    float local=1;NSCAssert(MTWriteFloat(&local,0,2) && local==2 && !MTWriteFloat(&local,0,NAN),@"writable finite data only");
}
#import "RE4Math.h"
static void re4MathTests(void){
    uint64_t after=0;
    NSCAssert(MTRE4AdjustClock(90000000,-1,&after) && after==30000000,@"RE4 minute conversion");
    NSCAssert(MTRE4AdjustClock(10,-1,&after) && after==0,@"RE4 clock subtraction saturates");
    NSCAssert(MTRE4AdjustClock(UINT64_MAX-1,1,&after) && after==UINT64_MAX,@"RE4 clock addition saturates");
    NSCAssert(!MTRE4AdjustClock(0,NAN,&after) && !MTRE4AdjustClock(0,601,&after),@"invalid clock requests rejected");
    int32_t reward=0;
    NSCAssert(MTRE4RewardTotal(100,125,2,1000,&reward) && reward==150,@"only new reward multiplied");
    NSCAssert(!MTRE4RewardTotal(150,150,2,1000,&reward),@"own bonus never compounds");
    NSCAssert(!MTRE4RewardTotal(150,125,2,1000,&reward),@"spending never multiplied");
    NSCAssert(MTRE4RewardTotal(1,100,100,1000,&reward) && reward==1000,@"reward cap enforced");
    NSCAssert(!MTRE4RewardTotal(-1,100,2,1000,&reward) && !MTRE4RewardTotal(1,100,INFINITY,1000,&reward),@"invalid reward inputs rejected");
}
void RE7RunOwnershipTests(void);
void MTControlRunTests(void);
void MTPresentationRunTests(void);
int main(int argc,const char *argv[]){@autoreleasepool{
    if(argc==2 && !strcmp(argv[1],"--presentation")){MTPresentationRunTests();return 0;}
    RE7RunOwnershipTests();NSCAssert(argc==2,@"config argument");re4MathTests();re2MouseTests();re2EnemyRegistrationTests();re2SaveCountTests();portableSafeTests();re2SpeedTests();re2ContinuousTempoTests();otherGameMouseTests();re4MouseTests();bridgeTests();MTControlRunTests();selectionTests();ledgerTests();highlightStopTests();profileTests([NSString stringWithUTF8String:argv[1]]);uiTests();puts("RE2/3/4/7 checks passed: shared originals, owner/context transitions, readback failures, stale actions, loading/F12, network gate, UI, shortcuts, profiles, bounded memory and reward/time arithmetic.");}return 0;}
