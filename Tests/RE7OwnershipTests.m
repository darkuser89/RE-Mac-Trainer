// SPDX-License-Identifier: GPL-3.0-only
// Synthetic native Guid registry and component graph; never opens a game.
#import "RE7Ownership.h"
#import "RE8Ownership.h"
#import "RE7ScoreMath.h"
#import "RE7TwentyOne.h"
#import "RE8MagazinePolicy.h"
#import "RE8TimeMath.h"
#import "RE8MercenaryPolicy.h"
#include <string.h>
static uint64_t go7test[8],component7test[8],foreign7test[8];
static BOOL alive7test;static NSUInteger referenceCalls7test,componentCalls7test;
static void construct7test(void *ctx,void *out,void *go){(void)ctx;uint64_t guid[2]={(uint64_t)(uintptr_t)go,0x7};memcpy(out,guid,16);}
static void *resolve7test(void *ctx,void *payload){(void)ctx;uint64_t guid[2];memcpy(guid,payload,16);return alive7test && guid[0]==(uintptr_t)go7test && guid[1]==7 ? go7test : NULL;}
static BOOL valid7test(void *ctx,void *component){(void)ctx;componentCalls7test++;return component==component7test && component7test[2]==(uintptr_t)go7test;}
static void *object7test(void *ctx,void *component){(void)ctx;componentCalls7test++;return component==component7test ? (void *)(uintptr_t)component7test[2] : NULL;}
static void reference7test(void *object){(void)object;referenceCalls7test++;}
@interface RE7FixtureEngine : MTRE2Engine
@end
@implementation RE7FixtureEngine
- (BOOL)isGameThread{return YES;}
- (void *)threadContext{return (__bridge void *)self;}
- (uint32_t)typeOf:(const void *)object{return object==go7test || object==foreign7test ? self.gameObjectType : object==component7test ? self.componentType : UINT32_MAX;}
- (BOOL)isObject:(void *)object kindOf:(uint32_t)type{return [self typeOf:object]==type;}
- (uint32_t)componentType{return 32277;}
- (uint32_t)gameObjectType{return 34333;}
- (uint32_t)componentValidMethod{return 1;}
- (uint32_t)componentGameObjectMethod{return 2;}
- (uint32_t)weakGameObjectType{return 2572;}
- (uint32_t)weakConstructor{return 3;}
- (uint32_t)weakResolver{return 4;}
- (NSUInteger)weakPayloadOffset{return 0;}
- (uintptr_t)retainAddress{return (uintptr_t)reference7test;}
- (uintptr_t)releaseAddress{return (uintptr_t)reference7test;}
- (void *)method:(uint32_t)index owner:(uint32_t)owner {
    if(owner==self.componentType)return index==1 ? (void *)valid7test : index==2 ? (void *)object7test : NULL;
    if(owner==self.weakGameObjectType)return index==3 ? (void *)construct7test : index==4 ? (void *)resolve7test : NULL;return NULL;
}
@end
@interface RE8FixtureEngine : RE7FixtureEngine
@end
@implementation RE8FixtureEngine
- (NSUInteger)gameObjectComponentsOffset{return 0x20;}
- (uint32_t)componentType{return 95136;}
- (uint32_t)gameObjectType{return 101222;}
- (uint32_t)weakGameObjectType{return 7758;}
@end
void RE7RunOwnershipTests(void){@autoreleasepool{
    NSCAssert(MTRE8MercenaryBonus(0,500,500,2)==500,@"an actual 500-point gain earns exactly 500 bonus points at x2");
    NSCAssert(MTRE8MercenaryBonus(1000,1000,1000,2)==0 && MTRE8MercenaryBonus(1000,1500,1500,2)==500,@"post-bonus rebasing prevents recursive multiplication while allowing the next award");
    NSCAssert(MTRE8MercenaryBonus(2000,0,0,2)==0 && MTRE8MercenaryBonus(0,100,101,2)==0,@"round resets and inconsistent area totals are not gains");
    NSCAssert(MTRE8MercenaryBonus(99999990,99999998,99999998,10)==1,@"saturation cannot overflow the native score");
    NSCAssert(MTRE8MercenaryBonus(0,500,500,1)==0 && MTRE8MercenaryBonus(0,500,500,NAN)==0 && MTRE8MercenaryBonus(0,500,500,11)==0,@"invalid factors cannot write a score bonus");
    NSCAssert(MTRE8TimeReadback(1200,1202,2) && MTRE8TimeReadback(0,6,2),@"the corrected timer may keep ticking at supported game speeds");
    NSCAssert(!MTRE8TimeReadback(1200,4800,2) && !MTRE8TimeReadback(0,9,2) && !MTRE8TimeReadback(0,NAN,2) && !MTRE8TimeReadback(0,0,-1),@"an overwritten counter, invalid value or elapsed time cannot confirm the time cheat");
    NSCAssert(MTRE8LoadedBulletTarget(5,8,10,10,true)==13 && MTRE8LoadedBulletTarget(0,3,10,10,true)==13,@"preserve the observed Rose offset through native paired refills, including empty display recovery");
    NSCAssert(MTRE8LoadedBulletTarget(9,12,10,10,true)==13 && MTRE8LoadedBulletTarget(7,7,10,10,false)==10,@"both counters gain exactly the same delta without changing main-game behavior");
    NSCAssert(MTRE8LoadedBulletTarget(5,8,10,10,false)==-1 && MTRE8LoadedBulletTarget(5,4,10,10,true)==-1 && MTRE8LoadedBulletTarget(5,16,10,10,true)==-1 && MTRE8LoadedBulletTarget(5,8,10,4,true)==-1,@"unverified modes, inverted counts, excessive offsets and rollback remain prohibited");
    // Village regression: writing/rolling back a magazine during an unfinished
    // shot must be prohibited. Exercise every combination of native gates.
    for(unsigned mask=0;mask<64;mask++){
        int target=MTRE8MagazineTarget(4,10,mask&1,mask&2,mask&4,mask&8,mask&16,mask&32);
        NSCAssert(target==(mask==7 ? 10 : -1),@"only a finished, ready weapon outside menus may be refilled");
    }
    NSCAssert(MTRE8MagazineTarget(-1,10,1,1,1,0,0,0)==-2 && MTRE8MagazineTarget(11,10,1,1,1,0,0,0)==-2 && MTRE8MagazineTarget(0,0,1,1,1,0,0,0)==-2 && MTRE8MagazineTarget(0,10000,1,1,1,0,0,0)==-2,@"invalid counts/capacities must never produce a write target");
    // Regression from the actual first-wave observation: factor 10 gives 4000;
    // factor 1000 gives 400000. A raw million-point bonus is weighted by 0.4.
    float weighted=MTRE7ScoreFactor(10,1000,4000,400000);
    NSCAssert(fabsf(weighted-2500.25f)<0.01f && (int32_t)(weighted*400)>=1000000,@"actual weighted native totals must determine the bonus factor");
    float withOtherBonus=MTRE7ScoreFactor(10,1000,1050,100050);
    NSCAssert(fabsf(withOtherBonus-10000.5f)<0.01f,@"unrelated additive points must not be mistaken for the bonus slope");
    NSCAssert(isnan(MTRE7ScoreFactor(10,1000,4000,4000)) && isnan(MTRE7ScoreFactor(10,10,4000,400000)) && isnan(MTRE7ScoreFactor(10,1000,4000,1)),@"zero, absent or negative response cannot confirm a score cheat");

    // Exhaust every possible hand of the real 1..11 deck. A successful plan
    // must keep the complete deck unique and in range, with exactly 21 points.
    int32_t deck21[11],plan21[11];for(int i=0;i<11;i++)deck21[i]=i+1;
    for(unsigned mask=0;mask<0x800;mask++){
        int n=__builtin_popcount(mask);BOOL valid=MTRE7PlanTwentyOne(deck21,mask,plan21);
        NSCAssert(valid==(n>=2 && n<=6),@"only mathematically feasible hand sizes may be changed");
        if(valid){unsigned seen=0;int total=0;
            for(int i=0;i<11;i++){NSCAssert(plan21[i]>=1 && plan21[i]<=11 && !(seen&(1u<<(plan21[i]-1))),@"no duplicated or invented cards");seen|=1u<<(plan21[i]-1);if(mask&(1u<<i))total+=plan21[i];}
            NSCAssert(seen==0x7ff && total==21,@"the original deck and exact hand total are preserved");
            int32_t repeated[11];NSCAssert(MTRE7PlanTwentyOne(plan21,mask,repeated) && !memcmp(plan21,repeated,sizeof(plan21)),@"an already perfect hand must remain stable");
        }
    }
    deck21[1]=1;NSCAssert(!MTRE7PlanTwentyOne(deck21,3,plan21),@"an inconsistent native deck must never be changed");
        memset(go7test,0,sizeof(go7test));memset(component7test,0,sizeof(component7test));
    go7test[3]=(uintptr_t)component7test;component7test[2]=(uintptr_t)go7test;
    alive7test=YES;referenceCalls7test=0;componentCalls7test=0;RE7FixtureEngine *engine=[RE7FixtureEngine new];
    NSCAssert([RE7Owner ownerForGameObject:NULL engine:engine]==nil && [RE7Owner ownerForComponent:NULL engine:engine]==nil,@"missing RE7 objects must return nil safely");
    RE7Owner *go=[RE7Owner ownerForGameObject:go7test engine:engine],*component=[RE7Owner ownerForComponent:component7test engine:engine];
    NSCAssert(go.valid && component.valid,@"RE7 uses the supplied engine and the real Guid resolution path");
    [go retainPayload:component7test];[component retainPayload:go7test];
    NSCAssert(referenceCalls7test==0,@"RE7 weak ownership cannot alter managed reference counts");
    go7test[3]=0;NSUInteger calls=componentCalls7test;
    NSCAssert(!component.valid && componentCalls7test==calls,@"a removed component must be rejected before a native component call");
    go7test[3]=(uintptr_t)component7test;component7test[2]=(uintptr_t)foreign7test;
    NSCAssert(!component.valid && componentCalls7test==calls,@"a reparented component cannot remain the old owner's payload");
    component7test[2]=(uintptr_t)go7test;alive7test=NO;
    NSCAssert(!go.valid && !component.valid,@"a stale native Guid invalidates both owner forms");
    go=nil;component=nil;NSCAssert(referenceCalls7test==0,@"releasing RE7 owners cannot decrement the game's counts");
    go7test[4]=(uintptr_t)component7test;alive7test=YES;RE8FixtureEngine *village=[RE8FixtureEngine new];
    RE8Owner *villageGO=[RE8Owner ownerForGameObject:go7test engine:village];
    RE8Owner *villageComponent=[RE8Owner ownerForComponent:component7test engine:village];
    NSCAssert(villageGO.valid && villageComponent.valid,@"Village validates its own type IDs and native Guid registry");
    go7test[4]=0;calls=componentCalls7test;
    NSCAssert(!villageComponent.valid && componentCalls7test==calls,@"Village rejects detached components before native calls");
    go7test[4]=(uintptr_t)component7test;component7test[2]=(uintptr_t)foreign7test;
    NSCAssert(!villageComponent.valid && componentCalls7test==calls,@"Village cannot reuse a foreign component's owner");
    component7test[2]=(uintptr_t)go7test;alive7test=NO;
    NSCAssert(!villageGO.valid && !villageComponent.valid,@"Village stale Guids block all payload access");
    [villageGO retainPayload:component7test];villageGO=nil;villageComponent=nil;
    NSCAssert(referenceCalls7test==0,@"Village ownership must not change managed reference counts");
}}
