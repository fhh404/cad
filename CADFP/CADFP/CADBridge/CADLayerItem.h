#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CADLayerItem : NSObject

@property (nonatomic, readonly) NSInteger index;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) UIColor *color;
@property (nonatomic, readonly, getter=isHidden) BOOL hidden;

- (instancetype)initWithIndex:(NSInteger)index
                         name:(NSString *)name
                        color:(UIColor *)color
                       hidden:(BOOL)hidden NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
