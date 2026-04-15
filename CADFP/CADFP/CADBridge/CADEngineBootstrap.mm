#import "CADEngineBootstrap.h"
#import "CADFontSupport.h"
#import "AppCore/TviActivator.hpp"

@implementation CADEngineBootstrap

+ (void)activateIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Must run before activate(): the engine reads ACAD / ACADFONTS /
        // FONTMAP environment variables when it resolves fonts during DWG
        // import, and it caches HostAppServices state after activation.
        [CADFontSupport setupIfNeeded];

        static TviActivator activator;
        activator.activate();
    });
}

@end
