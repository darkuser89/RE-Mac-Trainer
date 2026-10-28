// SPDX-License-Identifier: GPL-3.0-only
// Exact RE7 self-process metadata probe. No engine calls or game-value writes.
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/mach_vm.h>
#import <os/log.h>
#import "RE7DiagnosticBindings.h"
static BOOL r7read(uintptr_t a,void *out,size_t n){mach_vm_size_t copied=0;return mach_vm_read_overwrite(mach_task_self(),a,n,(mach_vm_address_t)out,&copied)==KERN_SUCCESS && copied==n;}
static void r7snapshot(intptr_t slide,NSUInteger attempt){
    uint8_t h[0xf0]={0};uintptr_t db=slide+0x1090e0180,methods=0,types=0;uint32_t magic=0,version=0,nt=0,nm=0;
    if(!r7read(db,h,sizeof(h)))return;
    memcpy(&magic,h,4);memcpy(&version,h+4,4);memcpy(&nt,h+8,4);memcpy(&nm,h+0x10,4);memcpy(&methods,h+0x70,8);memcpy(&types,h+0x60,8);
    if(magic!=0x424454 || version!=73 || nt!=91400 || nm!=597628)return;
    if(methods!=db+6581392 || types!=db+592){if(attempt<30)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{r7snapshot(slide,attempt+1);});return;}
    NSMutableSet<NSNumber *> *seen=[NSMutableSet new];NSUInteger examined=0;
    // Finite exact-image global scan; native candidates require a vtable in this
    // executable and at most 1024 distinct bounded object inspections.
    for(uintptr_t at=4441178112;at<4485054464;at+=4096){
        uintptr_t chunk[512]={0};if(!r7read(slide+at,chunk,sizeof(chunk)))continue;
        for(NSUInteger j=0;j<512;j++){
            uintptr_t object=chunk[j],info=0,type=0;
            if(object<0x100000000 || object%8 || !r7read(object,&info,8) || !info || info%8)continue;
            if(r7read(info,&type,8) && type>=types && type<types+nt*72 && (type-types)%72==0){
                uint32_t n=(uint32_t)((type-types)/72);
                if(n==11603 || n==34866 || n==43274 || n==15000 || n==22503 || n==22894 || n==16193 || n==13888 || n==36534 || n==41231)os_log(OS_LOG_DEFAULT,"RE7 singleton type=%{public}u slot=%{public}llx",n,(unsigned long long)(at+j*8));
                continue;
            }
            if(info<(uintptr_t)slide+0x100000000 || info>=(uintptr_t)slide+4441178112 || examined>=1024 || [seen containsObject:@(object)])continue;
            [seen addObject:@(object)];examined++;
            for(size_t offset=0x200;offset<0x18000;offset+=4096){
                uintptr_t fields[512]={0};if(!r7read(object+offset,fields,sizeof(fields)))continue;
                for(NSUInteger k=0;k<512;k++)if(fields[k]==(uintptr_t)slide+0x100000000+137674335){
                    uintptr_t fn=0;size_t field=offset+k*8-16;
                    if(r7read(object+field,&fn,8))os_log(OS_LOG_DEFAULT,"RE7 callback global=%{public}llx field=%{public}llx function=%{public}llx",(unsigned long long)(at+j*8),(unsigned long long)field,(unsigned long long)(fn-slide));
                }
            }
        }
    }
    for(NSUInteger i=0;i<sizeof(RE7ProbeMethods)/sizeof(RE7ProbeMethods[0]);i++){
        uint32_t index=RE7ProbeMethods[i][0],owner=RE7ProbeMethods[i][1],row[3]={0};
        if(r7read(methods+index*12,row,sizeof(row)) && (row[0]&0x7ffff)==owner)os_log(OS_LOG_DEFAULT,"RE7Binding index=%{public}u owner=%{public}u encoded=%{public}d",index,owner,(int32_t)row[2]);
    }
    os_log(OS_LOG_DEFAULT,"RE7 read-only probe completed nativeCandidates=%{public}lu gameMemoryWrites=0 engineCalls=0",(unsigned long)examined);
}
__attribute__((constructor)) static void r7probe(void){@autoreleasepool{
    NSDictionary *env=NSProcessInfo.processInfo.environment;
    if(![NSBundle.mainBundle.bundleIdentifier isEqual:@"jp.co.capcom.RE7US"] || ![[NSUUID alloc]initWithUUIDString:env[@"RE2_RE2_PROBE_SESSION"]])return;
    for(uint32_t i=0;i<_dyld_image_count();i++){
        const struct mach_header_64 *h=(const void *)_dyld_get_image_header(i);if(!h || h->magic!=MH_MAGIC_64 || h->filetype!=MH_EXECUTE)continue;
        if(h->cputype!=CPU_TYPE_ARM64 || h->sizeofcmds>1024*1024 || h->ncmds>4096)return;
        NSString *target=env[@"RE2_RE2_PROBE_TARGET"],*actual=[NSString stringWithUTF8String:_dyld_get_image_name(i)];
        if(!target.isAbsolutePath || ![target.stringByResolvingSymlinksInPath isEqual:actual.stringByResolvingSymlinksInPath])return;
        const uint8_t *cmd=(const void *)(h+1);uint32_t o=0;NSString *uuid=nil;
        for(uint32_t j=0;j<h->ncmds;j++){
            if(o>h->sizeofcmds || h->sizeofcmds-o<8)return;const struct load_command *c=(const void *)(cmd+o);
            if(c->cmdsize<8 || c->cmdsize>h->sizeofcmds-o)return;
            if(c->cmd==LC_UUID){if(uuid || c->cmdsize!=sizeof(struct uuid_command))return;uuid=[[NSUUID alloc]initWithUUIDBytes:((const struct uuid_command *)c)->uuid].UUIDString;}
            o+=c->cmdsize;
        }
        if(o!=h->sizeofcmds || ![uuid isEqual:@"4C4C4466-5555-3144-A1F6-0D461A1E2960"])return;
        intptr_t slide=_dyld_get_image_vmaddr_slide(i);os_log(OS_LOG_DEFAULT,"RE7 read-only module loaded exact UUID confirmed");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,8*NSEC_PER_SEC),dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{r7snapshot(slide,0);});return;
    }
}}
