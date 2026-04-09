#import "CADEngineBootstrap.h"
#import "AppCore/TviActivator.hpp"

@implementation CADEngineBootstrap

+ (void)activateIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static TviActivator activator;
        activator.activate();
    });
}

@end
