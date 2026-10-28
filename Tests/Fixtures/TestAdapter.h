// SPDX-License-Identifier: GPL-3.0-only
#import "GameAdapter.h"
@interface RE2TestAdapter : NSObject <RE2GameAdapter>
@property(nonatomic) RE2SessionKind mode;
@property(nonatomic,copy) NSString *identity;
@property(nonatomic) BOOL confirmed;
@property(nonatomic) NSUInteger oneShots, releases, applications;
@end
