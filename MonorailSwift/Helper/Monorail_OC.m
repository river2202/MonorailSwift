
#import "Monorail_OC.h"
#import <MonorailSwiftTools/MonorailSwiftTools-Swift.h>

@implementation Monorail_OC

+ (void) load {
    [Monorail_OC oc_enableLogger];
    [Monorail_OC oc_writeLog];
}

@end
