// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import "GameProfile.h"
#import "LocalControl.h"
#import "GameAdapter.h"
#import "OverlaySettings.h"
#import "CheatPreferences.h"
#import "RE2ProbeLaunch.h"
#import "TrainerMaterial.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static NSTextField *RE2LauncherLabel(NSString *text,CGFloat size,NSFontWeight weight,NSColor *color){
    NSTextField *label=[NSTextField wrappingLabelWithString:text];
    label.font=[NSFont systemFontOfSize:size weight:weight];label.textColor=color;
    label.translatesAutoresizingMaskIntoConstraints=NO;return label;
}
@interface RE2Launcher : NSObject <NSApplicationDelegate>
@property(nonatomic) NSWindow *window;
@property(nonatomic) NSDictionary *configuration;
@property(nonatomic) NSTextField *status,*gameStatus,*gameName;
@property(nonatomic) NSSegmentedControl *games;
@property(nonatomic) NSMutableDictionary<NSString *,NSRunningApplication *> *gameProcesses;
@property(nonatomic) NSMutableDictionary<NSString *,NSString *> *gameSessions;
@property(nonatomic) NSImageView *gameIcon;
@property(nonatomic) NSButton *start,*choose,*restoreCheats;

@property(nonatomic) id settingsObserver,selectionObserver;
@property(nonatomic) BOOL bindingDiagnostics,validGame,launching;
@end
@implementation RE2Launcher
- (NSDictionary *)profile {NSArray *profiles=self.configuration[@"profiles"];NSInteger index=self.games.selectedSegment;return index>=0 && index<(NSInteger)profiles.count ? profiles[index] : profiles.firstObject;}
- (NSRunningApplication *)game {return self.gameProcesses[self.profile[@"id"]];}
- (NSString *)session {return self.gameSessions[self.profile[@"id"]];}
- (void)selectGame:(id)sender {(void)sender;[NSUserDefaults.standardUserDefaults setObject:self.profile[@"id"] forKey:@"SelectedGameProfile"];[self refresh:nil];}
- (NSString *)pathKey {return [@"GamePath." stringByAppendingString:self.profile[@"id"]];}
- (void)changeRestoreCheats:(id)sender {(void)sender;[NSUserDefaults.standardUserDefaults setBool:self.restoreCheats.state==NSControlStateValueOn forKey:RE2RestoreCheatsKey];[self updateRunningState];}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    NSError *error=nil;self.configuration=MTLoadConfiguration([NSBundle.mainBundle pathForResource:@"TrainerConfig" ofType:@"json"],&error);
    if(!self.configuration){NSAlert *a=[NSAlert new];a.messageText=error.localizedDescription;[a runModal];[NSApp terminate:nil];return;}
    self.gameProcesses=[NSMutableDictionary new];self.gameSessions=[NSMutableDictionary new];
    NSColor *accent=[NSColor colorWithSRGBRed:1 green:0.43 blue:0.18 alpha:1];
    self.window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,480,420) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO];
    self.window.releasedWhenClosed=NO;self.window.title=self.configuration[@"app"][@"name"];
    self.window.titlebarAppearsTransparent=NO;self.window.titleVisibility=NSWindowTitleVisible;
    self.window.appearance=[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    self.window.opaque=YES;self.window.backgroundColor=NSColor.windowBackgroundColor;
    NSVisualEffectView *content=[[NSVisualEffectView alloc]initWithFrame:self.window.contentView.bounds];
    content.material=NSVisualEffectMaterialWindowBackground;content.blendingMode=NSVisualEffectBlendingModeBehindWindow;
    content.state=NSVisualEffectStateFollowsWindowActiveState;self.window.contentView=content;
    NSTextField *eyebrow=RE2LauncherLabel(@"TRAINER",11,NSFontWeightBold,accent);
    NSTextField *title=RE2LauncherLabel(@"Resident Evil",29,NSFontWeightSemibold,NSColor.labelColor);
    NSStackView *heading=[NSStackView stackViewWithViews:@[eyebrow,title]];
    heading.orientation=NSUserInterfaceLayoutOrientationVertical;heading.alignment=NSLayoutAttributeLeading;heading.spacing=3;

    self.games=[NSSegmentedControl segmentedControlWithLabels:@[@"RE2",@"RE3",@"RE4",@"RE7",@"RE8"] trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(selectGame:)];
    self.games.segmentStyle=NSSegmentStyleRounded;self.games.segmentDistribution=NSSegmentDistributionFillEqually;
    self.games.selectedSegment=0;
    NSString *saved=[NSUserDefaults.standardUserDefaults stringForKey:@"SelectedGameProfile"];
    NSArray *profiles=self.configuration[@"profiles"];for(NSUInteger i=0;i<profiles.count;i++)if([profiles[i][@"id"] isEqual:saved])self.games.selectedSegment=i;
    self.games.accessibilityLabel=@"Spiel auswählen";
    NSView *gameCard=[NSView new];
    MTTrainerMaterial *gameSurface=[[MTTrainerMaterial alloc]initWithContentView:gameCard cornerRadius:16];
    self.gameIcon=[NSImageView new];self.gameIcon.imageScaling=NSImageScaleProportionallyUpOrDown;
    self.gameIcon.translatesAutoresizingMaskIntoConstraints=NO;
    self.gameName=RE2LauncherLabel(@"",15,NSFontWeightMedium,NSColor.labelColor);
    self.gameStatus=RE2LauncherLabel(@"Spiel suchen …",12,NSFontWeightRegular,NSColor.secondaryLabelColor);
    NSStackView *gameText=[NSStackView stackViewWithViews:@[self.gameName,self.gameStatus]];
    gameText.orientation=NSUserInterfaceLayoutOrientationVertical;gameText.alignment=NSLayoutAttributeLeading;gameText.spacing=4;gameText.translatesAutoresizingMaskIntoConstraints=NO;
    self.choose=[NSButton buttonWithTitle:@"Ändern …" target:self action:@selector(choose:)];
    self.choose.bordered=NO;self.choose.font=[NSFont systemFontOfSize:12];self.choose.contentTintColor=NSColor.secondaryLabelColor;
    self.choose.translatesAutoresizingMaskIntoConstraints=NO;self.choose.toolTip=@"Original-Spiel-App auswählen";
    [gameCard addSubview:self.gameIcon];[gameCard addSubview:gameText];[gameCard addSubview:self.choose];
    [NSLayoutConstraint activateConstraints:@[
        [gameSurface.heightAnchor constraintEqualToConstant:76],
        [self.gameIcon.leadingAnchor constraintEqualToAnchor:gameCard.leadingAnchor constant:14],
        [self.gameIcon.centerYAnchor constraintEqualToAnchor:gameCard.centerYAnchor],
        [self.gameIcon.widthAnchor constraintEqualToConstant:46],[self.gameIcon.heightAnchor constraintEqualToConstant:46],
        [gameText.leadingAnchor constraintEqualToAnchor:self.gameIcon.trailingAnchor constant:12],
        [gameText.centerYAnchor constraintEqualToAnchor:gameCard.centerYAnchor],
        [gameText.trailingAnchor constraintLessThanOrEqualToAnchor:self.choose.leadingAnchor constant:-8],
        [self.choose.trailingAnchor constraintEqualToAnchor:gameCard.trailingAnchor constant:-12],
        [self.choose.centerYAnchor constraintEqualToAnchor:gameCard.centerYAnchor]
    ]];
    self.start=[NSButton buttonWithTitle:@"Spiel mit Trainer starten" target:self action:@selector(startGame:)];
    self.start.bordered=YES;self.start.bezelStyle=NSBezelStyleAutomatic;
    if(@available(macOS 26.0,*)){self.start.bezelStyle=NSBezelStyleGlass;self.start.tintProminence=NSTintProminencePrimary;}
    self.start.bezelColor=accent;
    self.start.font=[NSFont systemFontOfSize:15 weight:NSFontWeightSemibold];
    self.start.image=[NSImage imageWithSystemSymbolName:@"play.fill" accessibilityDescription:nil];self.start.imagePosition=NSImageLeft;self.start.imageHugsTitle=YES;
    self.start.keyEquivalent=@"\r";self.start.toolTip=@"Gewähltes Spiel mit Trainer starten. Cheats im Spiel einschalten.";
    [self.start.heightAnchor constraintEqualToConstant:46].active=YES;
    self.restoreCheats=[NSButton checkboxWithTitle:@"Cheat-Auswahl beim nächsten Start laden" target:self action:@selector(changeRestoreCheats:)];
    self.restoreCheats.font=[NSFont systemFontOfSize:12];
    self.restoreCheats.state=[NSUserDefaults.standardUserDefaults boolForKey:RE2RestoreCheatsKey] ? NSControlStateValueOn : NSControlStateValueOff;
    self.restoreCheats.toolTip=@"Für alle Spiele, mit getrennter Auswahl pro Spiel. Schalter und Zahlenwerte werden gemerkt. Einmalaktionen werden nicht automatisch ausgeführt. Das Overlay bleibt beim Start verborgen.";
    self.status=RE2LauncherLabel(@"",12,NSFontWeightRegular,NSColor.secondaryLabelColor);
    self.status.alignment=NSTextAlignmentCenter;[self.status.heightAnchor constraintEqualToConstant:30].active=YES;
    NSMutableArray<NSView *> *hints=[NSMutableArray new];
    for(NSString *hint in @[@"⌘^  Overlay + Maus",@"⇧F9  Cheats aus"]){
        NSTextField *label=RE2LauncherLabel(hint,11,NSFontWeightMedium,NSColor.secondaryLabelColor);label.alignment=NSTextAlignmentCenter;[hints addObject:label];
    }
    NSStackView *shortcuts=[NSStackView stackViewWithViews:hints];shortcuts.distribution=NSStackViewDistributionFillEqually;shortcuts.spacing=12;
    NSStackView *stack=[NSStackView stackViewWithViews:@[heading,self.games,gameSurface,self.start,self.restoreCheats,self.status,shortcuts]];
    stack.orientation=NSUserInterfaceLayoutOrientationVertical;stack.alignment=NSLayoutAttributeLeading;stack.spacing=16;stack.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:stack];
    NSMutableArray *constraints=[NSMutableArray arrayWithArray:@[
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor constant:26],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:content.bottomAnchor constant:-20]
    ]];
    for(NSView *view in @[self.games,gameSurface,self.start,self.restoreCheats,self.status,shortcuts])[constraints addObject:[view.widthAnchor constraintEqualToAnchor:stack.widthAnchor]];
    [NSLayoutConstraint activateConstraints:constraints];
    __weak RE2Launcher *weakSelf=self;
    self.settingsObserver=[NSDistributedNotificationCenter.defaultCenter addObserverForName:RE2OverlayChangedNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *event){
        RE2Launcher *owner=weakSelf;
        for(NSString *profileID in owner.gameProcesses){NSRunningApplication *game=owner.gameProcesses[profileID];if(game.terminated)continue;
            NSDictionary *options=RE2OverlayMessageOptions(event.object,owner.gameSessions[profileID],game.processIdentifier);
            if(options){[NSUserDefaults.standardUserDefaults setObject:options forKey:RE2OverlayPreferencesKey];break;}
        }
    }];
    self.selectionObserver=[NSDistributedNotificationCenter.defaultCenter addObserverForName:RE2SelectionChangedNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *event){
        RE2Launcher *owner=weakSelf;
        for(NSString *profileID in owner.gameProcesses){
            NSRunningApplication *game=owner.gameProcesses[profileID];
            NSDictionary *selection=RE2SelectionMessageOptions(event.object,profileID,owner.gameSessions[profileID],game.processIdentifier);
            if(selection){[NSUserDefaults.standardUserDefaults setObject:selection forKey:RE2SelectionKey(profileID)];break;}
        }
    }];
    [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(gameProcessChanged:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(gameProcessChanged:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    [self refresh:nil];[self.window center];[self.window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
}
- (void)updateRunningState {
    if(!self.start)return;
    NSArray<NSRunningApplication *> *apps=[NSRunningApplication runningApplicationsWithBundleIdentifier:self.profile[@"bundleIdentifier"]];
    BOOL running=apps.count>0;
    self.games.enabled=!self.launching;self.choose.enabled=!self.launching;
    self.start.enabled=!self.launching && (running || self.validGame);
    self.start.alphaValue=self.start.enabled ? 1 : 0.45;
    self.start.title=self.launching ? @"Spiel wird gestartet …" : running ? @"Zurück zum Spiel" : @"Spiel mit Trainer starten";
    self.start.image=[NSImage imageWithSystemSymbolName:running ? @"arrow.up.forward" : @"play.fill" accessibilityDescription:nil];
    if(running){
        self.gameStatus.stringValue=@"Spiel läuft";self.gameStatus.textColor=[NSColor colorWithSRGBRed:0.43 green:0.80 blue:0.58 alpha:1];
        self.status.textColor=NSColor.secondaryLabelColor;
        self.status.stringValue=self.game && !self.game.terminated ? @"Cheats im Spiel über das Overlay steuern." : @"Für einen Trainerstart das Spiel regulär beenden.";
    }else if(self.validGame){
        self.gameStatus.stringValue=@"Spiel gefunden";self.gameStatus.textColor=[NSColor colorWithSRGBRed:0.43 green:0.80 blue:0.58 alpha:1];
        self.status.textColor=NSColor.secondaryLabelColor;self.status.stringValue=self.restoreCheats.state==NSControlStateValueOn ? @"Gespeicherte Auswahl wird nach dem Laden aktiviert." : @"Alle Cheats sind beim Start ausgeschaltet.";
    }
}
- (void)refresh:(id)sender {
    (void)sender;self.validGame=NO;self.gameName.stringValue=self.profile[@"executable"];
    NSString *path=[NSUserDefaults.standardUserDefaults stringForKey:self.pathKey];NSError *error=nil;
    if(!path.length){
        NSURL *installed=[NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:self.profile[@"bundleIdentifier"]];
        if(installed && MTInspectGame(installed.path,self.profile,NULL)){path=installed.path;[NSUserDefaults.standardUserDefaults setObject:path forKey:self.pathKey];}
    }
    if([self.profile[@"enabled"] boolValue] && path.length)self.validGame=MTInspectGame(path,self.profile,&error)!=nil;
    self.gameIcon.image=path.length ? [NSWorkspace.sharedWorkspace iconForFile:path] : [NSImage imageWithSystemSymbolName:@"app.dashed" accessibilityDescription:@"Spiel auswählen"];
    self.choose.title=path.length ? @"Ändern …" : @"Auswählen …";
    self.gameIcon.toolTip=path;self.gameStatus.toolTip=path;
    if(!self.validGame){
        self.gameStatus.stringValue=path.length ? @"Spiel prüfen" : @"Kein Spiel ausgewählt";
        self.gameStatus.textColor=NSColor.secondaryLabelColor;
        self.status.textColor=path.length ? NSColor.systemOrangeColor : NSColor.secondaryLabelColor;
        self.status.stringValue=![self.profile[@"enabled"] boolValue] ? @"Dieses Spielprofil ist nicht freigegeben." : error.localizedDescription ?: @"Wähle die Original-Spiel-App aus.";
    }
    [self updateRunningState];
}
- (void)gameProcessChanged:(NSNotification *)notification {
    NSRunningApplication *app=notification.userInfo[NSWorkspaceApplicationKey];
    if([app.bundleIdentifier isEqual:self.profile[@"bundleIdentifier"]])[self updateRunningState];
}
- (void)applicationDidBecomeActive:(NSNotification *)notification {(void)notification;[self updateRunningState];}
- (void)showGame:(id)sender {
    (void)sender;NSArray<NSRunningApplication *> *apps=[NSRunningApplication runningApplicationsWithBundleIdentifier:self.profile[@"bundleIdentifier"]];
    if(apps.count==1){
        BOOL activated=[apps[0] activateWithOptions:NSApplicationActivateAllWindows];
        if(!activated)self.status.stringValue=@"Das Spielfenster bitte im Dock aktivieren.";
    }else self.status.stringValue=apps.count ? @"Bitte nur eine Spielinstanz geöffnet lassen." : @"Das Spiel läuft noch nicht.";
}
- (void)choose:(id)sender {
    (void)sender;NSOpenPanel *panel=[NSOpenPanel openPanel];panel.canChooseFiles=YES;panel.canChooseDirectories=NO;panel.allowsMultipleSelection=NO;panel.allowedContentTypes=@[UTTypeApplicationBundle];
    NSString *key=self.pathKey;panel.message=[self.profile[@"executable"] stringByAppendingString:@".app auswählen"];panel.prompt=@"Auswählen";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response){if(response==NSModalResponseOK){[NSUserDefaults.standardUserDefaults setObject:panel.URL.path forKey:key];[self refresh:nil];}}];
}
- (void)startGame:(id)sender {
    (void)sender;if(self.launching)return;
    if([NSRunningApplication runningApplicationsWithBundleIdentifier:self.profile[@"bundleIdentifier"]].count){[self showGame:nil];return;}
    [self refresh:nil];if(!self.validGame)return;
    NSString *path=[NSUserDefaults.standardUserDefaults stringForKey:self.pathKey];NSError *error=nil;NSDictionary *game=MTInspectGame(path,self.profile,&error);if(!game){self.status.stringValue=error.localizedDescription;return;}
    NSString *module=[NSBundle.mainBundle pathForResource:@"RE2TrainerRuntime" ofType:@"dylib"];
    NSWorkspaceOpenConfiguration *c=[NSWorkspaceOpenConfiguration configuration];c.createsNewApplicationInstance=YES;c.activates=YES;
    NSString *profileID=self.profile[@"id"],*session=NSUUID.UUID.UUIDString;self.gameSessions[profileID]=session;
    NSMutableDictionary *environment=[@{@"DYLD_INSERT_LIBRARIES":module,@"RE2_TRAINER_TARGET":game[@"executable"],@"RE2_TRAINER_CONFIG":[NSBundle.mainBundle pathForResource:@"TrainerConfig" ofType:@"json"],@"RE2_TRAINER_PROFILE":self.profile[@"id"],@"RE2_TRAINER_SESSION":session,@"RE2_TRAINER_OVERLAY_OPTIONS":RE2EncodeOverlayOptions(RE2OverlayOptionsForLaunch([NSUserDefaults.standardUserDefaults objectForKey:RE2OverlayPreferencesKey]))} mutableCopy];
    if(self.restoreCheats.state==NSControlStateValueOn){
        NSDictionary *selection=RE2NormalizeSelection([NSUserDefaults.standardUserDefaults objectForKey:RE2SelectionKey(profileID)],profileID);
        NSString *encoded=RE2EncodeSelection(selection);if(encoded)environment[@"RE2_TRAINER_CHEAT_SELECTION"]=encoded;
    }
    c.environment=environment;
    if(self.bindingDiagnostics){NSMutableDictionary *environment=[c.environment mutableCopy];environment[@"RE2_BINDING_SCAN"]=@"1";c.environment=environment;}
    self.launching=YES;[self updateRunningState];
    __weak RE2Launcher *weakSelf=self;
    [NSWorkspace.sharedWorkspace openApplicationAtURL:[NSURL fileURLWithPath:game[@"path"]] configuration:c completionHandler:^(NSRunningApplication *app,NSError *failure){dispatch_async(dispatch_get_main_queue(),^{
        RE2Launcher *owner=weakSelf;owner.launching=NO;if(app)owner.gameProcesses[profileID]=app;[owner updateRunningState];
        if(app && !failure)[app activateWithOptions:NSApplicationActivateAllWindows];
        if(failure || !app){owner.status.textColor=NSColor.systemOrangeColor;owner.status.stringValue=failure.localizedDescription ?: @"Das Spiel konnte nicht gestartet werden.";}
    });}];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {(void)application;for(NSRunningApplication *game in self.gameProcesses.allValues)if(!game.terminated)return NO;return YES;}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)visible {(void)application;if(!visible)[self.window makeKeyAndOrderFront:nil];[self updateRunningState];return YES;}
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;if(self.settingsObserver)[NSDistributedNotificationCenter.defaultCenter removeObserver:self.settingsObserver];
    if(self.selectionObserver)[NSDistributedNotificationCenter.defaultCenter removeObserver:self.selectionObserver];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
}
@end
int main(int argc,const char *argv[]){@autoreleasepool{
    if(argc>=2 && !strcmp(argv[1],"--control"))return MTControlCLI(argc,argv);
    if(argc==2 && !strcmp(argv[1],"--check-launcher")){
        NSError *error=nil;
        NSDictionary *config=MTLoadConfiguration([NSBundle.mainBundle pathForResource:@"TrainerConfig" ofType:@"json"],&error);
        if(!config){fprintf(stderr,"%s\n",error.localizedDescription.UTF8String);return 2;}
        puts("Signed launcher and bundled configuration loaded; no game started.");return 0;
    }
    if(argc==3 && !strcmp(argv[1],"--re7-overlay-check"))return RE2StartRE7OverlayCheck([NSString stringWithUTF8String:argv[2]]);
    if(argc==3 && !strcmp(argv[1],"--re7-probe"))return RE2StartRE7ReadOnlyProbe([NSString stringWithUTF8String:argv[2]]);
    if(argc==3 && !strcmp(argv[1],"--re8-probe"))return RE2StartRE8ReadOnlyProbe([NSString stringWithUTF8String:argv[2]]);
    if(argc==3 && !strcmp(argv[1],"--re8-overlay-check"))return RE2StartRE8OverlayCheck([NSString stringWithUTF8String:argv[2]]);
    if(argc==3 && !strcmp(argv[1],"--re4-probe"))return RE2StartRE4ReadOnlyProbe([NSString stringWithUTF8String:argv[2]]);
    if(argc==3 && !strcmp(argv[1],"--re3-engine-check"))return RE2StartRE3EngineCheck([NSString stringWithUTF8String:argv[2]]);
    if(argc==3 && !strcmp(argv[1],"--engine-check"))return RE2StartRE2EngineCheck([NSString stringWithUTF8String:argv[2]]);
    if(argc==3 && !strcmp(argv[1],"--overlay-check"))return RE2StartRE2OverlayCheck([NSString stringWithUTF8String:argv[2]]);
    if(argc==4 && !strcmp(argv[1],"--re3-probe"))return RE2StartRE3ReadOnlyProbe([NSString stringWithUTF8String:argv[2]],[NSString stringWithUTF8String:argv[3]]);
    if(argc==4 && !strcmp(argv[1],"--probe"))return RE2StartRE2ReadOnlyProbe([NSString stringWithUTF8String:argv[2]],[NSString stringWithUTF8String:argv[3]]);
    BOOL diagnostics=argc==2 && !strcmp(argv[1],"--binding-scan");
    if(argc!=1 && !diagnostics){fprintf(stderr,"Usage: MacTrainer [--binding-scan | --check-launcher | --engine-check game.app | --overlay-check game.app | --probe game.app new-result.json]\n");return 2;}
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSMenu *mainMenu=[NSMenu new];NSMenuItem *appItem=[NSMenuItem new];[mainMenu addItem:appItem];
    NSMenu *appMenu=[NSMenu new];NSMenuItem *quit=[appMenu addItemWithTitle:@"Resident Evil Trainer beenden" action:@selector(terminate:) keyEquivalent:@"q"];quit.target=NSApp;appItem.submenu=appMenu;NSApp.mainMenu=mainMenu;
    RE2Launcher *delegate=[RE2Launcher new];delegate.bindingDiagnostics=diagnostics;NSApp.delegate=delegate;[NSApp run];
}return 0;}
