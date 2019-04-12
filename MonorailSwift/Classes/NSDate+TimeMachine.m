
#import "NSDate+TimeMachine.h"
#import <objc/runtime.h>

@interface NSDate (TimeMachine_Private)
+(void) enableTimeMachine;
+ (instancetype) swizzledDate;
@end

@implementation NSDate (TimeMachine)

static NSTimeInterval timeIntervalTraveled = 0;

+ (void) load {
    [self enableTimeMachine];
}

+ (instancetype) realNow {
    return [[self class] swizzledDate];
}

+ (void) travelTo: (NSDate *) date {
    if (date != NULL) {
        timeIntervalTraveled = [[[self class] swizzledDate] timeIntervalSinceDate: date];
    } else {
        timeIntervalTraveled = 0;
    }
}
@end


@implementation NSDate (TimeMachine_Private)

- (id) newPlaceHolderDate {
    return [[NSDate alloc] newInitWithTimeIntervalSinceNow: -timeIntervalTraveled ];
}

- (id) newInitWithTimeIntervalSinceNow:(NSTimeInterval)secs {
    return [self newInitWithTimeIntervalSinceNow: secs - timeIntervalTraveled];
}

- (NSTimeInterval) newTimeIntervalSinceNow {
    return [self newTimeIntervalSinceNow] + timeIntervalTraveled;
}

+ (void)enableTimeMachine {
    Class class = [self class];
    [self swizzleClassMethod: @selector(date) oldClass: class new: @selector(swizzledDate) newClass: class];
    [self swizzleClassMethod: @selector(dateWithTimeIntervalSinceNow:) oldClass: class new: @selector(newDateWithTimeIntervalSinceNow:) newClass: class];
    
    [self swizzleInstanceMethod:@selector(timeIntervalSinceNow) oldClass: class
                            new:@selector(newTimeIntervalSinceNow) newClass: class];
    
    [self swizzleInstanceMethod: @selector(init) oldClass:NSClassFromString(@"__NSPlaceholderDate")
                            new:@selector(newPlaceHolderDate) newClass: class];
    
    [self swizzleInstanceMethod:@selector(initWithTimeIntervalSinceNow:) oldClass:NSClassFromString(@"__NSPlaceholderDate")
                            new:@selector(newInitWithTimeIntervalSinceNow:) newClass: class];
}

+(void) swizzleClassMethod: (SEL)old oldClass: (Class)oldClass new: (SEL)new newClass: (Class)newClass {
    Method oldMethod = class_getClassMethod(newClass, old);
    Method newMethod = class_getClassMethod(newClass, new);
    method_exchangeImplementations(oldMethod, newMethod);
}

+(void) swizzleInstanceMethod: (SEL)old oldClass: (Class)oldClass new:(SEL)new newClass: (Class)newClass {
    Method oldMethod = class_getInstanceMethod(oldClass, old);
    Method newMethod = class_getInstanceMethod(newClass, new);
    method_exchangeImplementations(oldMethod, newMethod);
}

+ (instancetype) swizzledDate {
    return [NSDate dateWithTimeInterval: timeIntervalTraveled sinceDate: [self swizzledDate]];
}

+ (instancetype) newDateWithTimeIntervalSinceNow: (NSTimeInterval) secs {
    return [NSDate dateWithTimeInterval:secs sinceDate: [self swizzledDate]];
}

@end
