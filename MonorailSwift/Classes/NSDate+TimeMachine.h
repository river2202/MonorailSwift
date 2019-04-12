#import <Foundation/Foundation.h>

@interface NSDate (TimeMachine)

+ (instancetype) realNow;
+ (void) travelTo:(NSDate *)date;

@end
