// SPDX-License-Identifier: GPL-3.0-only
// Self-process metadata reads only. No engine calls and no game-value writes.
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/mach_vm.h>
#import <os/log.h>
#import "RE4DiagnosticBindings.h"
static BOOL r4read(uintptr_t address,void *out,size_t size){mach_vm_size_t copied=0;return mach_vm_read_overwrite(mach_task_self(),address,size,(mach_vm_address_t)out,&copied)==KERN_SUCCESS && copied==size;}
static void r4snapshot(intptr_t slide,NSUInteger attempt){
    uint8_t h[0xf0]={0};uintptr_t tdb=slide+0x10d3aade8,methods=0;uint32_t magic=0,version=0,types=0,count=0;
    if(!r4read(tdb,h,sizeof(h)))return;
    memcpy(&magic,h,4);memcpy(&version,h+4,4);memcpy(&types,h+8,4);memcpy(&count,h+0x10,4);memcpy(&methods,h+0x70,8);
    if(magic!=0x424454 || version!=73 || types!=171431 || count!=1187687)return;
    if(methods!=tdb+0xbc5950){if(attempt<30)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{r4snapshot(slide,attempt+1);});return;}
    uintptr_t application=0;r4read(slide+0x10cbd1d20,&application,8);
    if(application)for(size_t offset=0x200;offset<0x18000;offset+=0x1000){
        uintptr_t chunk[512]={0};if(!r4read(application+offset,chunk,sizeof(chunk)))continue;
        for(NSUInteger j=0;j<512;j++){
            uintptr_t p=chunk[j];if(p<(uintptr_t)slide+0x100000000 || p>=(uintptr_t)slide+0x10c35c000)continue;
            char name[32]={0};if(!r4read(p,name,sizeof(name)) || strcmp(name,"LateUpdateBehavior"))continue;
            uintptr_t callback=0,field=offset+j*8-16;if(r4read(application+field,&callback,8))os_log(OS_LOG_DEFAULT,"RE4 callback field=%{public}llx function=%{public}llx",(unsigned long long)field,(unsigned long long)(callback-slide));
        }
    }
    // Finite scan of this exact image's writable data, reading only type identity.
    uintptr_t typesTable=tdb+0x250;
    for(uintptr_t at=0x10ca58000;at<0x1112a8000;at+=0x1000){
        uintptr_t chunk[512]={0};if(!r4read(slide+at,chunk,sizeof(chunk)))continue;
        for(NSUInteger j=0;j<512;j++){
            uintptr_t object=chunk[j],info=0,type=0;
            if(object<(uintptr_t)slide+0x1112a8000 || object%8 || !r4read(object,&info,8) || !info || info%8 || !r4read(info,&type,8))continue;
            if(type<typesTable || type>=typesTable+171431*72 || (type-typesTable)%72)continue;
            uint32_t n=(uint32_t)((type-typesTable)/72);
            if(n==54264 || n==4772 || n==2001 || n==31665 || n==41319)os_log(OS_LOG_DEFAULT,"RE4 singleton type=%{public}u slot=%{public}llx",n,(unsigned long long)(at+j*8));
        }
    }
    for(NSUInteger i=0;i<sizeof(RE4ProbeMethods)/sizeof(RE4ProbeMethods[0]);i++){
        uint32_t index=RE4ProbeMethods[i][0],owner=RE4ProbeMethods[i][1],row[3]={0};
        if(r4read(methods+index*12,row,sizeof(row)) && (row[0]&0x7ffff)==owner)os_log(OS_LOG_DEFAULT,"RE4Binding index=%{public}u owner=%{public}u encoded=%{public}d",index,owner,(int32_t)row[2]);
    }
    os_log(OS_LOG_DEFAULT,"RE4 read-only probe completed TDB73 types=171431 methods=1187687 gameMemoryWrites=0 engineCalls=0");
}
__attribute__((constructor)) static void r4probe(void){@autoreleasepool{
    NSDictionary *env=NSProcessInfo.processInfo.environment;
    if(![NSBundle.mainBundle.bundleIdentifier isEqual:@"jp.co.capcom.RE4US"] || ![[NSUUID alloc]initWithUUIDString:env[@"RE2_RE2_PROBE_SESSION"]])return;
    for(uint32_t i=0;i<_dyld_image_count();i++){
        const struct mach_header_64 *h=(const void *)_dyld_get_image_header(i);if(!h || h->magic!=MH_MAGIC_64 || h->filetype!=MH_EXECUTE)continue;
        if(h->cputype!=CPU_TYPE_ARM64 || h->sizeofcmds>1024*1024 || h->ncmds>4096)return;
        NSString *target=env[@"RE2_RE2_PROBE_TARGET"],*actual=[NSString stringWithUTF8String:_dyld_get_image_name(i)];
        if(!target.isAbsolutePath || ![target.stringByResolvingSymlinksInPath isEqual:actual.stringByResolvingSymlinksInPath])return;
        const uint8_t *commands=(const void *)(h+1);uint32_t offset=0;NSString *uuid=nil;
        for(uint32_t j=0;j<h->ncmds;j++){
            if(offset>h->sizeofcmds || h->sizeofcmds-offset<8)return;const struct load_command *c=(const void *)(commands+offset);
            if(c->cmdsize<8 || c->cmdsize>h->sizeofcmds-offset)return;
            if(c->cmd==LC_UUID){if(uuid || c->cmdsize!=sizeof(struct uuid_command))return;uuid=[[NSUUID alloc]initWithUUIDBytes:((const struct uuid_command *)c)->uuid].UUIDString;}
            offset+=c->cmdsize;
        }
        if(offset!=h->sizeofcmds || ![uuid isEqual:@"4C4C44CF-5555-3144-A161-D64EFB82E79F"])return;
        intptr_t slide=_dyld_get_image_vmaddr_slide(i);os_log(OS_LOG_DEFAULT,"RE4 read-only module loaded exact UUID confirmed");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,6*NSEC_PER_SEC),dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{r4snapshot(slide,0);});return;
    }
}}
