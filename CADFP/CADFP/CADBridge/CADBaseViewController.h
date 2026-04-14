#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "AppUITools/TviProgressControl.h"
#import "CADLayerItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CADMarkupTool) {
    CADMarkupToolRectangle = 0,
    CADMarkupToolCircle = 1,
    CADMarkupToolCloud = 2,
    CADMarkupToolText = 3,
    CADMarkupToolHandle = 4,
};

@class CADBaseViewController;

@interface CADMeasurementCoordinate : NSObject

@property (nonatomic, assign, readonly) double x;
@property (nonatomic, assign, readonly) double y;
@property (nonatomic, assign, readonly) double z;

- (instancetype)initWithX:(double)x y:(double)y z:(double)z NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@protocol CADBaseViewControllerDelegate <NSObject>
@optional
- (void)cadControllerDidFinishLoading:(CADBaseViewController *)controller;
- (void)cadController:(CADBaseViewController *)controller didUpdateLayers:(NSArray<CADLayerItem *> *)layers;
- (void)cadController:(CADBaseViewController *)controller didExtractTextItems:(NSArray<NSString *> *)textItems;
- (void)cadController:(CADBaseViewController *)controller didMeasureScreenPoint:(CGPoint)screenPoint worldCoordinate:(CADMeasurementCoordinate *)worldCoordinate;
- (void)cadController:(CADBaseViewController *)controller didEmitMessageWithTitle:(NSString *)title message:(nullable NSString *)message;
@end

@interface CADBaseViewController : UIViewController

@property (nonatomic, weak, nullable) id<CADBaseViewControllerDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (strong, nonatomic) EAGLContext *glContext;
@property (strong, nonatomic) TviProgressControl *progressMeter;
@property (nonatomic, readonly, getter=isReady) BOOL ready;
@property (nonatomic, assign, getter=isMeasurementModeEnabled) BOOL measurementModeEnabled;

- (instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)requestLayerSnapshot;
- (void)setLayerHidden:(BOOL)hidden atIndex:(NSInteger)index;
- (void)activateMarkupTool:(CADMarkupTool)tool;
- (void)activateTextMarkupWithText:(NSString *)text;
- (void)activateTextMarkupWithText:(NSString *)text textSize:(double)textSize;
- (void)setMarkupColorWithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue;
- (void)setMarkupLineWeight:(NSInteger)weight;
- (void)finishActiveMarkup;
- (void)setMarkupsHidden:(BOOL)hidden;
- (void)resetView;
- (void)setViewRotationDegrees:(NSInteger)degrees NS_SWIFT_NAME(setViewRotation(degrees:));
- (void)setDrawingBackgroundWithRed:(NSInteger)red
                              green:(NSInteger)green
                               blue:(NSInteger)blue NS_SWIFT_NAME(setDrawingBackground(red:green:blue:));
- (void)requestExtractedTexts;
- (void)requestExtractedTextsInViewRect:(CGRect)rect NS_SWIFT_NAME(requestExtractedTexts(inViewRect:));
- (nullable CADMeasurementCoordinate *)worldCoordinateForViewPoint:(CGPoint)point NS_SWIFT_NAME(worldCoordinate(forViewPoint:));

- (void)showMessage:(NSString *)title message:(nullable NSString *)msg;
- (void)showSaveMarkupDialog;
- (void)showLoadMarkupDialog;
- (void)startTimer;
- (void)stopLoadingIndicator:(double)time;
- (void)addBottomBorder:(nullable UIView *)parentView;
- (void)update;
- (void)loadFileDone;
- (void)openFile:(NSObject *)context;

@end

NS_ASSUME_NONNULL_END
