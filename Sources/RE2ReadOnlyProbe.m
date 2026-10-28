// SPDX-License-Identifier: GPL-3.0-only
// Diagnostic only. Does not call engine methods, hook code or write game memory.
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/mach.h>
#import <mach/mach_vm.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#import "RE3DiagnosticBindings.h"
#import <os/log.h>

static BOOL readSelf(uint64_t address,void *destination,size_t length) {
    mach_vm_size_t copied=0;
    return mach_vm_read_overwrite(mach_task_self(),address,length,(mach_vm_address_t)destination,&copied)==KERN_SUCCESS && copied==length;
}
static BOOL snapshot(NSString *output,NSString *session,intptr_t slide) {
    @autoreleasepool {
        BOOL re3=[NSBundle.mainBundle.bundleIdentifier isEqual:@"jp.co.capcom.RE3US"];
        uint64_t address=(uint64_t)((re3 ? 0x1092f8060ULL : 0x108da47c8ULL)+slide);
        uint8_t header[0xf0]={0};
        if(!readSelf(address,header,sizeof(header))){os_log_error(OS_LOG_DEFAULT,"RE trainer probe: TDB header unreadable");return NO;}
        uint32_t magic=0,version=0,types=0,methods=0,fields=0;
        memcpy(&magic,header,4);memcpy(&version,header+4,4);
        memcpy(&types,header+8,4);memcpy(&methods,header+0x14,4);memcpy(&fields,header+0x18,4);
        os_log(OS_LOG_DEFAULT,"RE trainer probe header magic=%{public}x version=%{public}u types=%{public}u methods=%{public}u fields=%{public}u",magic,version,types,methods,fields);
        if(magic!=0x424454 || version!=74 || types!=(re3 ? 112924 : 102046) || methods!=(re3 ? 819986 : 730907) || fields!=(re3 ? 163379 : 146898))return NO;
        uint64_t methodTable=0;memcpy(&methodTable,header+0x78,8);
        // Report the representation as observed; do not assume offsets became pointers.
        NSMutableArray *bindings=[NSMutableArray new];
        if(re3){
            os_log(OS_LOG_DEFAULT,"RE trainer probe method table raw=%{public}llx expected=%{public}llx",(unsigned long long)methodTable,(unsigned long long)(address+0x89db10));
            if(methodTable==0x89db10)methodTable+=address;
            if(!methodTable)return NO;
            for(NSUInteger i=0;i<sizeof(RE3ProbeMethods)/sizeof(RE3ProbeMethods[0]);i++){
                uint32_t index=RE3ProbeMethods[i][0],owner=RE3ProbeMethods[i][1],row[3]={0};
                if(!readSelf(methodTable+index*12,row,sizeof(row)) || (row[0]&0x7ffff)!=owner){os_log_error(OS_LOG_DEFAULT,"RE trainer probe descriptor mismatch index=%{public}u expected=%{public}u observed=%{public}u",index,owner,row[0]&0x7ffff);return NO;}
                [bindings addObject:@{@"index":@(index),@"owner":@(owner),@"encoded":@((int32_t)row[2])}];
            }
        }
        NSMutableArray *callbacks=[NSMutableArray new];uint64_t vm=0,application=0;
        if(re3){
            readSelf(slide+0x1092f33c0ULL,&vm,8);readSelf(slide+0x1092f33c8ULL,&application,8);
            if(application)for(uint64_t offset=0x200;offset<0x14000;offset+=0x1000){
                uint64_t chunk[512]={0};if(!readSelf(application+offset,chunk,sizeof(chunk)))continue;
                for(NSUInteger i=0;i<512;i++){
                    uint64_t nameAddress=chunk[i];
                    if(nameAddress<(uint64_t)slide+0x100000000ULL || nameAddress>=(uint64_t)slide+0x108dfc000ULL)continue;
                    char name[33]={0};if(!readSelf(nameAddress,name,32) || strcmp(name,"LateUpdateBehavior"))continue;
                    uint64_t callback=0,field=offset+i*8-16;if(!readSelf(application+field,&callback,8))continue;
                    [callbacks addObject:@{@"field":[NSString stringWithFormat:@"0x%llx",(unsigned long long)field],@"name":@"LateUpdateBehavior",@"function":[NSString stringWithFormat:@"0x%llx",(unsigned long long)(callback-slide)]}];
                }
            }
        }
        NSDictionary *result=@{@"probe":re3 ? @"RE3 read-only load and metadata probe" : @"RE2 read-only load and metadata probe",@"session":session,
            @"bundleIdentifier":NSBundle.mainBundle.bundleIdentifier ?: @"",@"pid":@(getpid()),
            @"uuid":re3 ? @"4C4C4461-5555-3144-A174-EA43301DB10B" : @"4C4C44ED-5555-3144-A15E-9285028AFD15",@"bindings":bindings,@"callbacks":callbacks,@"vmPresent":@(vm!=0),@"moduleLoaded":@YES,
            @"tdbVersion":@(version),@"typeCount":@(types),@"methodCount":@(methods),@"fieldCount":@(fields),
            @"methodTableRaw":[NSString stringWithFormat:@"0x%llx",(unsigned long long)methodTable],
            @"gameMemoryWrites":@0,@"engineCalls":@0,@"ingameCheatVerified":@NO};
        if(re3 && [NSProcessInfo.processInfo.environment[@"RE2_RE2_PROBE_LOG_ONLY"] isEqual:@"1"]){
            for(NSDictionary *entry in callbacks)os_log(OS_LOG_DEFAULT,"RE3 callback field=%{public}s function=%{public}s",[entry[@"field"] UTF8String],[entry[@"function"] UTF8String]);
            for(NSDictionary *entry in bindings)os_log(OS_LOG_DEFAULT,"RE3Binding index=%{public}u owner=%{public}u encoded=%{public}d",[entry[@"index"] unsignedIntValue],[entry[@"owner"] unsignedIntValue],[entry[@"encoded"] intValue]);
            os_log(OS_LOG_DEFAULT,"RE3 probe completed bindings=%{public}lu vm=%{public}d gameMemoryWrites=0 engineCalls=0",(unsigned long)bindings.count,vm!=0);
            return YES;
        }
        NSData *data=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:NULL];
        int file=open(output.fileSystemRepresentation,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0600);
        if(file<0)return NO;
        const uint8_t *bytes=data.bytes;size_t remaining=data.length;BOOL success=YES;
        while(remaining){ssize_t n=write(file,bytes,remaining);if(n<0 && errno==EINTR)continue;if(n<=0){success=NO;break;}bytes+=n;remaining-=(size_t)n;}
        if(close(file)!=0)success=NO;
        if(!success)unlink(output.fileSystemRepresentation);
        return success;
    }
}
static void probeWhenReady(NSString *output,NSString *session,intptr_t slide,NSUInteger attempt) {
    if(snapshot(output,session,slide) || attempt>=30)return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{probeWhenReady(output,session,slide,attempt+1);});
}
__attribute__((constructor)) static void loadProbe(void) {
    @autoreleasepool {
        NSDictionary *env=NSProcessInfo.processInfo.environment;
        NSString *output=env[@"RE2_RE2_PROBE_OUTPUT"],*session=env[@"RE2_RE2_PROBE_SESSION"],*target=env[@"RE2_RE2_PROBE_TARGET"];
        if(!output.isAbsolutePath || ![[NSUUID alloc]initWithUUIDString:session] || !target.isAbsolutePath)return;
        BOOL re3=[NSBundle.mainBundle.bundleIdentifier isEqual:@"jp.co.capcom.RE3US"];
        os_log(OS_LOG_DEFAULT,"RE trainer probe loaded in bundle=%{public}s",(NSBundle.mainBundle.bundleIdentifier ?: @"nil").UTF8String);
        if(!re3 && ![NSBundle.mainBundle.bundleIdentifier isEqual:@"jp.co.capcom.RE2US"])return;
        const struct mach_header_64 *main=NULL;intptr_t slide=0;
        for(uint32_t i=0;i<_dyld_image_count();i++){
            const struct mach_header_64 *h=(const void *)_dyld_get_image_header(i);
            if(h && h->magic==MH_MAGIC_64 && h->filetype==MH_EXECUTE){
                NSString *path=[NSString stringWithUTF8String:_dyld_get_image_name(i)];
                if(![path.stringByResolvingSymlinksInPath isEqual:target.stringByResolvingSymlinksInPath])return;
                main=h;slide=_dyld_get_image_vmaddr_slide(i);break;
            }
        }
        if(!main || main->cputype!=CPU_TYPE_ARM64 || main->sizeofcmds>1024*1024 || main->ncmds>4096)return;
        const uint8_t *commands=(const void *)(main+1);uint32_t offset=0;NSString *uuid=nil;
        for(uint32_t i=0;i<main->ncmds;i++){
            if(offset>main->sizeofcmds || main->sizeofcmds-offset<sizeof(struct load_command))return;
            const struct load_command *c=(const void *)(commands+offset);
            if(c->cmdsize<8 || c->cmdsize>main->sizeofcmds-offset)return;
            if(c->cmd==LC_UUID){if(uuid || c->cmdsize!=sizeof(struct uuid_command))return;uuid=[[NSUUID alloc]initWithUUIDBytes:((const struct uuid_command *)c)->uuid].UUIDString;}
            offset+=c->cmdsize;
        }
        if(offset!=main->sizeofcmds || ![uuid isEqual:re3 ? @"4C4C4461-5555-3144-A174-EA43301DB10B" : @"4C4C44ED-5555-3144-A15E-9285028AFD15"])return;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{probeWhenReady(output,session,slide,0);});
    }
}
