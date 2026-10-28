// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import "GameProfile.h"
#import "RE2ProbeLaunch.h"
static int startProbe(NSString *appPath,NSString *outputPath,BOOL engineCheck,BOOL overlayCheck,NSString *profileID) {
    BOOL nativeCheck=engineCheck || overlayCheck;
    BOOL logOnly=!nativeCheck && ([profileID isEqual:@"re3-mac-1.0.0"] || [profileID isEqual:@"re4-mac-1.0.7"] || [profileID isEqual:@"re7-mac-1.0.4"] || [profileID isEqual:@"re8-mac-1.1.8"]);
    NSError *error=nil;
    NSDictionary *config=MTLoadConfiguration([NSBundle.mainBundle pathForResource:@"TrainerConfig" ofType:@"json"],&error);
    NSDictionary *stored=MTFindProfile(config,profileID);
    if(!stored){fprintf(stderr,"RE2 profile missing.\n");return 2;}
    // Apply identity validation for this diagnostic. The stored gameplay
    // profile policy is unchanged; the engine check selects no cheat effects.
    NSMutableDictionary *probeProfile=[stored mutableCopy];probeProfile[@"enabled"]=@YES;
    NSDictionary *game=MTInspectGame(appPath,probeProfile,&error);
    if(!game){fprintf(stderr,"%s\n",error.localizedDescription.UTF8String);return 2;}
    if([NSRunningApplication runningApplicationsWithBundleIdentifier:stored[@"bundleIdentifier"]].count){fprintf(stderr,"RE2 already running; no restart or attach performed.\n");return 2;}
    NSString *parent=outputPath.stringByDeletingLastPathComponent.stringByResolvingSymlinksInPath;
    BOOL directory=NO;
    if(!nativeCheck && !logOnly && (!outputPath.isAbsolutePath || ![NSFileManager.defaultManager fileExistsAtPath:parent isDirectory:&directory] || !directory || [NSFileManager.defaultManager fileExistsAtPath:outputPath])){fprintf(stderr,"Output needs an existing directory and a new absolute filename.\n");return 2;}
    NSString *probe=[NSBundle.mainBundle pathForResource:nativeCheck ? @"RE2TrainerRuntime" : @"RE2ReadOnlyProbe" ofType:@"dylib"];
    if(!probe){fprintf(stderr,"Read-only probe library missing.\n");return 2;}
    NSWorkspaceOpenConfiguration *options=NSWorkspaceOpenConfiguration.configuration;
    options.createsNewApplicationInstance=YES;options.activates=YES;
    NSString *session=NSUUID.UUID.UUIDString;
    options.environment=nativeCheck ? @{@"DYLD_INSERT_LIBRARIES":probe,@"RE2_NATIVE_TEST":overlayCheck ? @"0" : @"1",@"RE2_OVERLAY_CHECK":overlayCheck ? @"1" : @"0",@"RE2_NATIVE_STARTUP":@"1",@"RE2_BINDING_SCAN":@"1"} : @{@"DYLD_INSERT_LIBRARIES":probe,@"RE2_RE2_PROBE_OUTPUT":outputPath,
                          @"RE2_RE2_PROBE_SESSION":session,@"RE2_RE2_PROBE_TARGET":game[@"executable"]};
    if(logOnly){NSMutableDictionary *env=[options.environment mutableCopy];env[@"RE2_RE2_PROBE_LOG_ONLY"]=@"1";options.environment=env;}
    __block BOOL done=NO;__block int status=3;
    [NSWorkspace.sharedWorkspace openApplicationAtURL:[NSURL fileURLWithPath:game[@"path"]] configuration:options completionHandler:^(NSRunningApplication *app,NSError *failure){
        fprintf(stderr,"%s\n",failure ? failure.localizedDescription.UTF8String : app ? "Read-only diagnostic launch requested." : "No process returned.");
        status=app && !failure ? 0 : 3;done=YES;
    }];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];
    while(!done && deadline.timeIntervalSinceNow>0)[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    if(!done){fprintf(stderr,"Launch completion timed out; process state is unknown.\n");return 3;}
    if(status)return status;
    if(logOnly){puts("Read-only load probe started; read its bounded binding and completion events in Unified Logging. No engine calls or game-value writes.");return 0;}
    if(nativeCheck){puts(overlayCheck ? "Visible overlay inspection started; all cheat controls locked." : "Native engine verification started; no cheat selected. Read subsystem local.mactrainer.re2 in unified logging. Do not attach LLDB during gameplay.");return 0;}
    deadline=[NSDate dateWithTimeIntervalSinceNow:20];
    while(deadline.timeIntervalSinceNow>0){
        NSData *data=[NSData dataWithContentsOfFile:outputPath];
        NSDictionary *result=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
        if([result isKindOfClass:NSDictionary.class] && [result[@"session"] isEqual:session] && [result[@"moduleLoaded"] boolValue]){puts("Read-only module load and TDB identity confirmed. No cheats tested.");return 0;}
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    fprintf(stderr,"No matching probe result. Library loading has not been confirmed; no protection settings changed.\n");return 4;
}
int RE2StartRE2ReadOnlyProbe(NSString *appPath,NSString *outputPath){return startProbe(appPath,outputPath,NO,NO,@"re2-mac-1.0.2");}
int RE2StartRE2EngineCheck(NSString *appPath){return startProbe(appPath,@"",YES,NO,@"re2-mac-1.0.2");}
int RE2StartRE2OverlayCheck(NSString *appPath){return startProbe(appPath,@"",NO,YES,@"re2-mac-1.0.2");}

int RE2StartRE3ReadOnlyProbe(NSString *appPath,NSString *outputPath){return startProbe(appPath,outputPath,NO,NO,@"re3-mac-1.0.0");}

int RE2StartRE3EngineCheck(NSString *appPath){return startProbe(appPath,@"",YES,NO,@"re3-mac-1.0.0");}
int RE2StartRE4ReadOnlyProbe(NSString *appPath){return startProbe(appPath,@"",NO,NO,@"re4-mac-1.0.7");}

int RE2StartRE7ReadOnlyProbe(NSString *appPath){return startProbe(appPath,@"",NO,NO,@"re7-mac-1.0.4");}

int RE2StartRE7OverlayCheck(NSString *appPath){return startProbe(appPath,@"",NO,YES,@"re7-mac-1.0.4");}
int RE2StartRE8ReadOnlyProbe(NSString *appPath){return startProbe(appPath,@"",NO,NO,@"re8-mac-1.1.8");}
int RE2StartRE8OverlayCheck(NSString *appPath){return startProbe(appPath,@"",NO,YES,@"re8-mac-1.1.8");}
