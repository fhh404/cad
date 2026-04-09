#import "CADBaseViewController.h"

#import "AppCore/TviCore.hpp"
#import "AppCore/TviDraggers.hpp"
#import "AppCore/TviImportParameters.hpp"
#import "AppCore/TviTools.h"
#import "CADEngineBootstrap.h"
#import "RenderViewController.h"

@interface CADBaseViewController () {
    TviCore _tvCore;
    TviGlobalParameters *_globalParams;
    TviImportParamsController *_importController;
    OdTvBaseImportParams *_importParams;
    std::vector<OdTvLayerId> _layerIds;
    NSTimer *_autoUpdateTimer;
    OdTvVector _backDelta;
    int _xMin;
    int _xMax;
    int _yMin;
    int _yMax;
    BOOL _markupsHidden;
}

@property (nonatomic, copy, readwrite) NSString *filePath;
@property (nonatomic, assign, readwrite, getter=isReady) BOOL ready;
@property (nonatomic, strong) UIView *renderContainerView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *loadingStatusLabel;
@property (nonatomic, strong) RenderViewController *renderViewController;

@end

@implementation CADBaseViewController

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _filePath = [filePath copy];
        _ready = NO;
        _markupsHidden = NO;
        _globalParams = new TviGlobalParameters();
        _globalParams->setDevice(TviGlobalParameters::OpenGLES2);
        _globalParams->setPartialOpen(false);
        _importController = new TviImportParamsController();
        _importParams = _importController->getDwgImportParams();
        _tvCore.attach(self);
        _tvCore.setGlobalParams(_globalParams);
        _tvCore.setFileExtension(TviCore::Drw);
    }
    return self;
}

- (void)dealloc
{
    [_autoUpdateTimer invalidate];
    _autoUpdateTimer = nil;
    _tvCore.detach();
    delete _importController;
    delete _globalParams;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [CADEngineBootstrap activateIfNeeded];

    self.view.backgroundColor = UIColor.blackColor;

    self.renderContainerView = [[UIView alloc] init];
    self.renderContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.renderContainerView.backgroundColor = UIColor.blackColor;
    [self.view addSubview:self.renderContainerView];

    [NSLayoutConstraint activateConstraints:@[
        [self.renderContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.renderContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.renderContainerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.renderContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.progressMeter = [[TviProgressControl alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
    self.progressMeter.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressMeter.hidden = YES;
    self.progressMeter.hintHidden = NO;
    [self.view addSubview:self.progressMeter];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.color = UIColor.whiteColor;
    [self.view addSubview:self.loadingIndicator];

    self.loadingStatusLabel = [[UILabel alloc] init];
    self.loadingStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingStatusLabel.textColor = [UIColor colorWithWhite:1 alpha:0.82];
    self.loadingStatusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.loadingStatusLabel.text = @"正在载入图纸...";
    [self.view addSubview:self.loadingStatusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.progressMeter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.progressMeter.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.progressMeter.widthAnchor constraintEqualToConstant:72],
        [self.progressMeter.heightAnchor constraintEqualToConstant:72],
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.loadingStatusLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingStatusLabel.topAnchor constraintEqualToAnchor:self.loadingIndicator.bottomAnchor constant:18],
    ]];

    [self.loadingIndicator startAnimating];

    [self installGestures];
    [self.view layoutIfNeeded];
    [self updateRenderBounds];
    [self embedRenderer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateRenderBounds];
}

- (void)embedRenderer
{
    self.renderViewController = [[RenderViewController alloc] init];
    [self addChildViewController:self.renderViewController];
    self.renderViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.renderContainerView addSubview:self.renderViewController.view];
    [NSLayoutConstraint activateConstraints:@[
        [self.renderViewController.view.leadingAnchor constraintEqualToAnchor:self.renderContainerView.leadingAnchor],
        [self.renderViewController.view.trailingAnchor constraintEqualToAnchor:self.renderContainerView.trailingAnchor],
        [self.renderViewController.view.topAnchor constraintEqualToAnchor:self.renderContainerView.topAnchor],
        [self.renderViewController.view.bottomAnchor constraintEqualToAnchor:self.renderContainerView.bottomAnchor],
    ]];
    [self.renderViewController didMoveToParentViewController:self];
}

- (void)installGestures
{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    pan.maximumNumberOfTouches = 1;
    [self.renderContainerView addGestureRecognizer:pan];

    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomEvent:)];
    [self.renderContainerView addGestureRecognizer:pinch];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTouchEvent:)];
    [self.renderContainerView addGestureRecognizer:tap];
}

- (void)updateRenderBounds
{
    if (CGRectIsEmpty(self.renderContainerView.bounds)) {
        return;
    }

    CGFloat scale = UIScreen.mainScreen.scale;
    _xMin = 0;
    _yMax = 0;
    _xMax = (int)lrint(CGRectGetWidth(self.renderContainerView.bounds) * scale);
    _yMin = (int)lrint(CGRectGetHeight(self.renderContainerView.bounds) * scale);
    _importController->setRect(_xMax, _yMin);

    if (self.isReady) {
        _tvCore.resizeDevice(_xMin, _xMax, _yMin, _yMax);
    }
}

- (void)openFile:(NSObject *)context
{
    if (self.filePath.length == 0) {
        [self showMessage:@"无法打开图纸" message:@"没有找到可用的 DWG 文件。"];
        return;
    }

    NSString *ext = self.filePath.pathExtension.lowercaseString ?: @"";
    BOOL shouldImport = ![ext isEqualToString:@"vsf"];
    _tvCore.openFile(NSString2OdString(self.filePath), _importParams, shouldImport, context, OdTvDCRect(_xMin, _xMax, _yMin, _yMax));
}

- (void)update
{
    _tvCore.update();
}

- (void)loadFileDone
{
    if (!_tvCore.isValid()) {
        [self showMessage:@"图纸打开失败" message:@"底层 CAD 引擎没有返回可用视图。"];
        return;
    }

    self.ready = YES;
    [_loadingIndicator stopAnimating];
    _loadingIndicator.hidden = YES;
    self.progressMeter.hidden = YES;
    self.loadingStatusLabel.hidden = YES;

    _tvCore.set3DView(OdTvExtendedView::kTop);
    [self requestLayerSnapshot];

    if ([self.delegate respondsToSelector:@selector(cadControllerDidFinishLoading:)]) {
        [self.delegate cadControllerDidFinishLoading:self];
    }
}

- (void)requestLayerSnapshot
{
    if (!self.isReady) {
        return;
    }

    NSMutableArray<CADLayerItem *> *items = [NSMutableArray array];
    _layerIds.clear();

    OdTvLayersIteratorPtr layersIter = _tvCore.getLayers();
    OdTvResult rc;
    for (; !layersIter->done(); layersIter->step()) {
        OdTvLayerId layerId = layersIter->getLayer(&rc);
        OdTvLayerPtr layerPtr = layerId.openObject(OdTv::kForRead);
        if (layerPtr.isNull()) {
            continue;
        }

        _layerIds.push_back(layerId);
        NSInteger index = (NSInteger)_layerIds.size() - 1;

        OdTvColorDef color = layerPtr->getColor(&rc);
        UIColor *uiColor = UIColor.whiteColor;
        if (color.getType() == OdTvColorDef::kColor) {
            OdUInt8 r, g, b;
            color.getColor(r, g, b);
            uiColor = [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1.0];
        } else if (color.getType() == OdTvColorDef::kIndexed) {
            OdUInt32 rgb = _tvCore.getIndexedColor(color.getIndexedColor(&rc));
            uiColor = [UIColor colorWithRed:ODGETRED(rgb) / 255.0
                                      green:ODGETGREEN(rgb) / 255.0
                                       blue:ODGETBLUE(rgb) / 255.0
                                      alpha:1.0];
        }

        CADLayerItem *item = [[CADLayerItem alloc] initWithIndex:index
                                                            name:OdString2NSString(layerPtr->getName(&rc))
                                                           color:uiColor
                                                          hidden:!layerPtr->getVisible(&rc)];
        [items addObject:item];
    }

    if ([self.delegate respondsToSelector:@selector(cadController:didUpdateLayers:)]) {
        [self.delegate cadController:self didUpdateLayers:items];
    }
}

- (void)setLayerHidden:(BOOL)hidden atIndex:(NSInteger)index
{
    if (index < 0 || index >= (NSInteger)_layerIds.size()) {
        return;
    }

    OdTvLayerPtr layerPtr = _layerIds[(size_t)index].openObject(OdTv::kForWrite);
    if (layerPtr.isNull()) {
        return;
    }

    layerPtr->setVisible(!hidden);
    _tvCore.update();
    [self requestLayerSnapshot];
}

- (void)activateMarkupTool:(CADMarkupTool)tool
{
    if (!self.isReady) {
        return;
    }

    if (_markupsHidden) {
        [self setMarkupsHidden:NO];
    }

    switch (tool) {
        case CADMarkupToolRectangle:
            _tvCore.runMarkupAction(TviCore::Rectangle);
            break;
        case CADMarkupToolCircle:
            _tvCore.runMarkupAction(TviCore::Circle);
            break;
        case CADMarkupToolCloud:
            _tvCore.runMarkupAction(TviCore::Cloud);
            break;
        case CADMarkupToolText:
            _tvCore.runMarkupAction(TviCore::Text);
            break;
    }
}

- (void)setMarkupsHidden:(BOOL)hidden
{
    _markupsHidden = hidden;

    if (hidden) {
        _tvCore.disableMarkups();
        _tvCore.update();
        return;
    }

    _tvCore.showMarkups();
    _tvCore.update();
}

- (void)requestExtractedTexts
{
    if (!self.isReady) {
        return;
    }

    _tvCore.searchDBDataContent();
    NSMutableArray<NSString *> *texts = [NSMutableArray array];
    const std::vector<OdString> &extractedTexts = _tvCore.getExtractedTexts();
    for (const OdString &text : extractedTexts) {
        NSString *value = OdString2NSString(text);
        if (value.length > 0) {
            [texts addObject:value];
        }
    }

    if ([self.delegate respondsToSelector:@selector(cadController:didExtractTextItems:)]) {
        [self.delegate cadController:self didExtractTextItems:texts];
    }
}

- (void)showMessage:(NSString *)title message:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(cadController:didEmitMessageWithTitle:message:)]) {
            [self.delegate cadController:self didEmitMessageWithTitle:title message:msg];
            return;
        }

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:msg
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)showSaveMarkupDialog
{
    [self showMessage:@"暂未接入" message:@"首版先支持直接批注，标注存档会在下一阶段补上。"];
}

- (void)showLoadMarkupDialog
{
    [self showMessage:@"暂未接入" message:@"首版先支持直接批注，历史标注加载会在下一阶段补上。"];
}

- (void)startTimer
{
    if (_autoUpdateTimer != nil) {
        return;
    }

    _autoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(timeOut:)
                                                      userInfo:nil
                                                       repeats:NO];
}

- (void)timeOut:(NSTimer *)timer
{
    [_autoUpdateTimer invalidate];
    _autoUpdateTimer = nil;
    _tvCore.autoUpdate();
}

- (void)stopLoadingIndicator:(double)time
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadingStatusLabel.text = [NSString stringWithFormat:@"载入完成 %.2f s", time];
        self.progressMeter.hidden = YES;
    });
}

- (void)addBottomBorder:(UIView *)parentView
{
}

- (CGPoint)setupPoint:(CGPoint)point
{
    CGFloat scale = UIScreen.mainScreen.scale;
    return CGPointMake(point.x * scale, point.y * scale);
}

- (OdGePoint3d)toEyeToWorld:(int)x yPos:(int)y viewPtr:(OdTvGsViewPtr)viewPtr
{
    OdGePoint3d wcsPoint(x, y, 0.0);
    if (viewPtr->isPerspective()) {
        wcsPoint.z = viewPtr->projectionMatrix()(2, 3);
    }
    wcsPoint.transformBy((viewPtr->screenMatrix() * viewPtr->projectionMatrix()).inverse());
    wcsPoint.z = 0.0;
    wcsPoint.transformBy(viewPtr->eyeToWorldMatrix());
    return wcsPoint;
}

- (void)onTouchEvent:(UITapGestureRecognizer *)sender
{
    OdTvDragger *dragger = _tvCore.getActiveDragger();
    if (!dragger) {
        return;
    }

    OdTvTextMarkupDragger *textDragger = dynamic_cast<OdTvTextMarkupDragger *>(dragger);
    if (!textDragger) {
        return;
    }

    CGPoint touchPoint = [self setupPoint:[sender locationInView:self.renderContainerView]];
    eDraggerResult result = dragger->activate();
    _tvCore.actionsAfterDragger(result);
    result = dragger->nextpoint(touchPoint.x, touchPoint.y);
    _tvCore.actionsAfterDragger(result);

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请输入批注文字"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self->_tvCore.finishDragger();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }

        NSString *text = alert.textFields.firstObject.text ?: @"";
        OdTvDragger *activeDragger = self->_tvCore.getActiveDragger();
        if (!activeDragger) {
            return;
        }

        eDraggerResult textResult = activeDragger->processText(NSString2OdString(text));
        self->_tvCore.actionsAfterDragger(textResult);

        OdTvGsViewPtr viewPtr = self->_tvCore.getActiveTvViewPtr();
        if (!viewPtr.isNull()) {
            viewPtr->dolly(self->_backDelta.transformBy(viewPtr->viewingMatrix()));
            self->_backDelta.set(0.0, 0.0, 0.0);
        }

        self->_tvCore.finishDragger();
    }]];

    OdTvGsViewPtr viewPtr = _tvCore.getActiveTvViewPtr();
    if (!viewPtr.isNull()) {
        OdTvPoint screenPrevPoint = viewPtr->position().transformBy(viewPtr->worldToDeviceMatrix());
        OdTvPoint prevPoint = [self toEyeToWorld:(int)screenPrevPoint.x yPos:(int)screenPrevPoint.y viewPtr:viewPtr] - viewPtr->position().asVector();
        OdTvPoint currentPoint = [self toEyeToWorld:(int)touchPoint.x yPos:(int)touchPoint.y viewPtr:viewPtr];
        OdTvVector delta = (prevPoint - (currentPoint - viewPtr->position())).asVector();
        _backDelta = (prevPoint + (viewPtr->position() - currentPoint)).asVector();
        viewPtr->dolly(-delta.transformBy(viewPtr->viewingMatrix()));
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)panEvent:(UIPanGestureRecognizer *)sender
{
    OdTvDragger *dragger = _tvCore.getActiveDragger();
    if (!dragger) {
        return;
    }

    CGPoint touchPoint = [self setupPoint:[sender locationInView:self.renderContainerView]];
    eDraggerResult result = kNothingToDo;

    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            result = dragger->activate();
            _tvCore.actionsAfterDragger(result);
            result = dragger->nextpoint(touchPoint.x, touchPoint.y);
            if (dynamic_cast<TviOrbitDragger *>(dragger) != NULL) {
                _tvCore.disableMarkups();
            }
            break;
        case UIGestureRecognizerStateChanged:
            result = dragger->drag(touchPoint.x, touchPoint.y);
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            result = dragger->nextpointup(touchPoint.x, touchPoint.y);
            _tvCore.setRegenAbort(false);
            break;
        default:
            break;
    }

    _tvCore.actionsAfterDragger(result);
}

- (void)zoomEvent:(UIPinchGestureRecognizer *)sender
{
    CGPoint pinchCenter = [self setupPoint:[sender locationInView:self.renderContainerView]];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            _tvCore.performFixedFrameRate();
            break;
        case UIGestureRecognizerStateChanged:
            _tvCore.zoom(sender.scale, pinchCenter.x, pinchCenter.y);
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            _tvCore.finishFixedFrameRate();
            _tvCore.setRegenAbort(false);
            break;
        default:
            break;
    }
    sender.scale = 1.0;
}

@end
