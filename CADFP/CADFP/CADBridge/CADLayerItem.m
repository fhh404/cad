#import "CADLayerItem.h"

@implementation CADLayerItem

- (instancetype)initWithIndex:(NSInteger)index
                         name:(NSString *)name
                        color:(UIColor *)color
                       hidden:(BOOL)hidden
{
    self = [super init];
    if (self) {
        _index = index;
        _name = [name copy];
        _color = color;
        _hidden = hidden;
    }
    return self;
}

@end
