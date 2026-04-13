#import "CADConversionBridge.h"

#import "AppCore/TviTools.h"
#import "CADEngineBootstrap.h"

#include "../../可视化真机/Drawing/Include/DbDatabase.h"
#include "../../可视化真机/Drawing/Include/DbBlockTableRecord.h"
#include "../../可视化真机/Drawing/Include/DbHostAppServices.h"
#include "../../可视化真机/Drawing/Include/HatchPatternManager.h"
#include "../../可视化真机/Drawing/Include/DbDatabaseReactor.h"
#include "../../可视化真机/Drawing/Include/DbDictionary.h"
#include "../../可视化真机/Drawing/Include/DbGsManager.h"
#include "../../可视化真机/Drawing/Include/DbLayout.h"
#include "../../可视化真机/Drawing/Include/DbSystemServices.h"
#include "../../可视化真机/Drawing/Include/GiContextForDbDatabase.h"
#include "../../可视化真机/Drawing/Extensions/ExServices/ExHostAppServices.h"
#include "../../可视化真机/Drawing/Imports/PdfImport/Include/PdfImport.h"

#include "../../可视化真机/Kernel/Exports/PdfExport/Include/PdfExport.h"
#include "../../可视化真机/Kernel/Exports/PdfExport/Include/PdfExportParams.h"
#include "../../可视化真机/Kernel/Include/AbstractViewPE.h"
#include "../../可视化真机/Kernel/Include/ColorMapping.h"
#include "../../可视化真机/Kernel/Include/Gs/Gs.h"
#include "../../可视化真机/Kernel/Include/RxRasterServices.h"
#include "../../可视化真机/KernelBase/Include/OdModuleNames.h"

#include "ExSystemServices.h"
#include "OdError.h"
#include "RxVariantValue.h"
#include "StaticRxObject.h"

using namespace TD_PDF_2D_EXPORT;

static NSString * const CADConversionBridgeErrorDomain = @"CADConversionBridgeErrorDomain";

namespace {

class CADConversionServices : public ExSystemServices, public ExHostAppServices
{
protected:
    ODRX_USING_HEAP_OPERATORS(ExSystemServices);

public:
    OdGsDevicePtr gsBitmapDevice(
        OdRxObject* pViewObj = NULL,
        OdDbBaseDatabase* pDb = NULL,
        OdUInt32 flags = 0
    ) ODRX_OVERRIDE
    {
        OdGsModulePtr module;
        if (GETBIT(flags, kFor2dExportRender) && !GETBIT(flags, kFor2dExportRenderHLR)) {
            module = ::odrxDynamicLinker()->loadModule(OdWinGLES2ModuleName, false);
        }
        if (module.isNull()) {
            module = ::odrxDynamicLinker()->loadModule(OdWinBitmapModuleName, false);
        }

        return module.isNull() ? OdGsDevicePtr() : module->createBitmapDevice();
    }
};

NSError *CADConversionError(NSInteger code, NSString *message)
{
    return [NSError errorWithDomain:CADConversionBridgeErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

void AssignConversionError(NSError **error, NSInteger code, NSString *message)
{
    if (error != nil) {
        *error = CADConversionError(code, message);
    }
}

CADConversionServices *SharedConversionServices()
{
    static OdStaticRxObject<CADConversionServices> services;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        odInitialize(&services);
    });
    return &services;
}

BOOL ValidateConversionPaths(NSString *sourcePath, NSString *targetPath, NSError **error)
{
    if (sourcePath.length == 0 || targetPath.length == 0) {
        AssignConversionError(error, 1, @"转换文件路径无效。");
        return NO;
    }

    return YES;
}

OdDbDatabasePtr ReadDWGDatabase(NSString *sourcePath, NSError **error)
{
    CADConversionServices *services = SharedConversionServices();
    OdDbDatabasePtr database = services->readFile(
        NSString2OdString(sourcePath),
        false,
        false,
        Oda::kShareDenyNo
    );

    if (database.isNull()) {
        AssignConversionError(error, 2, @"DWG 文件没有读取成功。");
    }

    return database;
}

BOOL ExportDWGToDXF(NSString *sourcePath, NSString *targetPath, NSError **error)
{
    OdDbDatabasePtr database = ReadDWGDatabase(sourcePath, error);
    if (database.isNull()) {
        return NO;
    }

    database->writeFile(
        NSString2OdString(targetPath),
        OdDb::kDxf,
        database->originalFileVersion(),
        false,
        16
    );
    return YES;
}

BOOL ExportDWGToPDF(NSString *sourcePath, NSString *targetPath, NSError **error)
{
    OdDbDatabasePtr database = ReadDWGDatabase(sourcePath, error);
    if (database.isNull()) {
        return NO;
    }

    OdPdfExportModulePtr module = ::odrxDynamicLinker()->loadApp(OdPdfExportModuleName, false);
    if (module.isNull()) {
        AssignConversionError(error, 5, @"PDF 导出模块没有加载成功。");
        return NO;
    }

    OdPdfExportPtr exporter = module->create();
    if (exporter.isNull()) {
        AssignConversionError(error, 6, @"PDF 导出器没有创建成功。");
        return NO;
    }

    PDFExportParams params;
    params.setDatabase(database);
    params.setVersion(PDFExportParams::kPDFv1_5);
    params.setOutput(odSystemServices()->createFile(
        NSString2OdString(targetPath),
        Oda::kFileWrite,
        Oda::kShareDenyNo,
        Oda::kCreateAlways
    ));

    params.setExportFlags(PDFExportParams::PDFExportFlags(
        PDFExportParams::kTTFTextAsGeometry |
        PDFExportParams::kSHXTextAsGeometry |
        PDFExportParams::kFlateCompression |
        PDFExportParams::kASCIIHexEncoding |
        PDFExportParams::kZoomToExtentsMode
    ));
    params.setTitle(NSString2OdString([targetPath lastPathComponent]));
    params.setAuthor(OD_T("CADFP"));
    params.setCreator(OD_T("CADFP"));
    params.setGeomDPI(300);
    params.setColorImagesDPI(300);
    params.setBWImagesDPI(300);
    params.setSolidHatchesExportType(PDFExportParams::kDrawing);
    params.setOtherHatchesExportType(PDFExportParams::kDrawing);

    OdDbBlockTableRecordPtr layoutBlock = database->getActiveLayoutBTRId().safeOpenObject();
    if (!layoutBlock.isNull()) {
        OdDbLayoutPtr layout = layoutBlock->getLayoutId().safeOpenObject();
        if (!layout.isNull()) {
            params.layouts().push_back(layout->getLayoutName());
        }
    }

    if (params.layouts().isEmpty()) {
        AssignConversionError(error, 7, @"DWG 文件没有可导出的布局。");
        return NO;
    }

    OdGsPageParams pageParams;
    params.pageParams().resize(params.layouts().size(), pageParams);

    OdUInt32 errorCode = exporter->exportPdf(params);
    if (errorCode != 0) {
        NSString *message = [NSString stringWithFormat:@"DWG 转 PDF 失败：%@", OdString2NSString(exporter->exportPdfErrorCode(errorCode))];
        AssignConversionError(error, 8, message);
        return NO;
    }

    return YES;
}

BOOL ExportDWGToImage(NSString *sourcePath, NSString *targetPath, NSError **error)
{
    OdDbDatabasePtr database = ReadDWGDatabase(sourcePath, error);
    if (database.isNull()) {
        return NO;
    }

    OdGsModulePtr gsModule = ::odrxDynamicLinker()->loadModule(OdWinGLES2ModuleName, false);
    if (gsModule.isNull()) {
        gsModule = ::odrxDynamicLinker()->loadModule(OdWinBitmapModuleName, false);
    }
    if (gsModule.isNull()) {
        AssignConversionError(error, 9, @"图片导出渲染模块没有加载成功。");
        return NO;
    }

    OdGsDevicePtr bitmapDevice = gsModule->createBitmapDevice();
    if (bitmapDevice.isNull()) {
        AssignConversionError(error, 10, @"图片导出设备没有创建成功。");
        return NO;
    }

    OdGiContextForDbDatabasePtr context = OdGiContextForDbDatabase::createObject();
    context->setDatabase(database);
    context->enableGsModel(false);

    OdGsDevicePtr device = OdDbGsManager::setupActiveLayoutViews(bitmapDevice, context);
    if (device.isNull()) {
        AssignConversionError(error, 11, @"图片导出视图没有创建成功。");
        return NO;
    }

    ODCOLORREF backgroundColor = ODRGB(255, 255, 255);
    device->setLogicalPalette(::odcmAcadLightPalette(), 256);
    device->setBackgroundColor(backgroundColor);
    context->setPaletteBackground(backgroundColor);

    OdGsDCRect screenRect(OdGsDCPoint(0, 2048), OdGsDCPoint(2048, 0));
    device->onSize(screenRect);

    OdGsView *view = device->viewAt(0);
    if (view == NULL) {
        AssignConversionError(error, 12, @"图片导出视图不可用。");
        return NO;
    }

    OdAbstractViewPEPtr(view)->zoomExtents(view);
    OdAbstractViewPEPtr(view)->setRenderMode(view, OdDb::k2DOptimized);
    device->update();

    OdGiRasterImagePtr rasterImage = device->properties()->getAt(OD_T("RasterImage"));
    if (rasterImage.isNull()) {
        AssignConversionError(error, 13, @"图片导出后没有生成栅格图像。");
        return NO;
    }

    OdRxRasterServicesPtr rasterServices = ::odrxDynamicLinker()->loadApp(RX_RASTER_SERVICES_APPNAME, false);
    if (rasterServices.isNull()) {
        AssignConversionError(error, 14, @"图片保存模块没有加载成功。");
        return NO;
    }

    rasterServices->saveRasterImage(rasterImage, NSString2OdString(targetPath));
    return YES;
}

NSString *PDFImportResultDescription(OdPdfImport::ImportResult result)
{
    switch (result) {
    case OdPdfImport::success:
        return @"PDF 导入成功。";
    case OdPdfImport::fail:
        return @"PDF 导入失败。";
    case OdPdfImport::bad_password:
        return @"PDF 密码不正确。";
    case OdPdfImport::bad_file:
        return @"PDF 文件无效。";
    case OdPdfImport::bad_database:
        return @"PDF 导入目标数据库无效。";
    case OdPdfImport::encrypted_file:
        return @"PDF 文件已加密，暂时不能转换。";
    case OdPdfImport::invalid_page_number:
        return @"PDF 页码无效。";
    case OdPdfImport::image_file_error:
        return @"PDF 图片资源保存失败。";
    case OdPdfImport::no_objects_imported:
        return @"PDF 没有导入任何可转换对象。";
    case OdPdfImport::font_file_error:
        return @"PDF 字体资源保存失败。";
    }
}

BOOL ExportPDFToDWG(NSString *sourcePath, NSString *targetPath, NSError **error)
{
    CADConversionServices *services = SharedConversionServices();
    OdDbDatabasePtr database = services->createDatabase(true, OdDb::kMetric);
    if (database.isNull()) {
        AssignConversionError(error, 19, @"DWG 数据库没有创建成功。");
        return NO;
    }

    OdPdfImportModulePtr module = ::odrxDynamicLinker()->loadApp(OdPdfImportModuleName, false);
    if (module.isNull()) {
        AssignConversionError(error, 20, @"PDF 导入模块没有加载成功。");
        return NO;
    }

    OdPdfImportPtr importer = module->create();
    if (importer.isNull()) {
        AssignConversionError(error, 21, @"PDF 导入器没有创建成功。");
        return NO;
    }

    OdRxDictionaryPtr properties = importer->properties();
    properties->putAt(OD_T("Database"), database);
    properties->putAt(OD_T("PdfPath"), OdRxVariantValue(NSString2OdString(sourcePath)));
    properties->putAt(OD_T("Password"), OdRxVariantValue(OdString::kEmpty));
    properties->putAt(OD_T("PageNumber"), OdRxVariantValue(OdUInt32(1)));
    properties->putAt(OD_T("Rotation"), OdRxVariantValue(0.0));
    properties->putAt(OD_T("Scaling"), OdRxVariantValue(1.0));
    properties->putAt(OD_T("ImportVectorGeometry"), OdRxVariantValue(true));
    properties->putAt(OD_T("ImportSolidFills"), OdRxVariantValue(true));
    properties->putAt(OD_T("ImportTrueTypeText"), OdRxVariantValue(true));
    properties->putAt(OD_T("ImportRasterImages"), OdRxVariantValue(true));
    properties->putAt(OD_T("ImportGradientFills"), OdRxVariantValue(true));
    properties->putAt(OD_T("ImportWidgets"), OdRxVariantValue(true));
    properties->putAt(OD_T("JoinLineAndArcSegments"), OdRxVariantValue(true));
    properties->putAt(OD_T("ConvertSolidsToHatches"), OdRxVariantValue(true));
    properties->putAt(OD_T("ApplyLineweight"), OdRxVariantValue(true));
    properties->putAt(OD_T("UseGeometryOptimization"), OdRxVariantValue(true));
    properties->putAt(OD_T("UseRgbColor"), OdRxVariantValue(true));
    properties->putAt(OD_T("ImagePath"), OdRxVariantValue(NSString2OdString([targetPath stringByDeletingLastPathComponent])));

    OdPdfImport::ImportResult result = importer->import();
    if (result != OdPdfImport::success) {
        AssignConversionError(error, 22, [NSString stringWithFormat:@"PDF 转 DWG 失败：%@", PDFImportResultDescription(result)]);
        return NO;
    }

    database->writeFile(
        NSString2OdString(targetPath),
        OdDb::kDwg,
        OdDb::kDHL_CURRENT,
        true,
        16
    );
    return YES;
}

}

@implementation CADConversionBridge

+ (BOOL)convertDWGAtPath:(NSString *)sourcePath
             toDXFAtPath:(NSString *)targetPath
                   error:(NSError **)error
{
    if (!ValidateConversionPaths(sourcePath, targetPath, error)) {
        return NO;
    }

    [CADEngineBootstrap activateIfNeeded];

    try {
        return ExportDWGToDXF(sourcePath, targetPath, error);
    } catch (const OdError& e) {
        NSString *message = [NSString stringWithFormat:@"DWG 转 DXF 失败：%@", OdString2NSString(e.description())];
        AssignConversionError(error, 3, message);
        return NO;
    } catch (...) {
        AssignConversionError(error, 4, @"DWG 转 DXF 失败。");
        return NO;
    }
}

+ (BOOL)convertDWGAtPath:(NSString *)sourcePath
             toPDFAtPath:(NSString *)targetPath
                   error:(NSError **)error
{
    if (!ValidateConversionPaths(sourcePath, targetPath, error)) {
        return NO;
    }

    [CADEngineBootstrap activateIfNeeded];

    try {
        return ExportDWGToPDF(sourcePath, targetPath, error);
    } catch (const OdError& e) {
        NSString *message = [NSString stringWithFormat:@"DWG 转 PDF 失败：%@", OdString2NSString(e.description())];
        AssignConversionError(error, 15, message);
        return NO;
    } catch (...) {
        AssignConversionError(error, 16, @"DWG 转 PDF 失败。");
        return NO;
    }
}

+ (BOOL)convertDWGAtPath:(NSString *)sourcePath
           toImageAtPath:(NSString *)targetPath
                   error:(NSError **)error
{
    if (!ValidateConversionPaths(sourcePath, targetPath, error)) {
        return NO;
    }

    [CADEngineBootstrap activateIfNeeded];

    try {
        return ExportDWGToImage(sourcePath, targetPath, error);
    } catch (const OdError& e) {
        NSString *message = [NSString stringWithFormat:@"DWG 转图片失败：%@", OdString2NSString(e.description())];
        AssignConversionError(error, 17, message);
        return NO;
    } catch (...) {
        AssignConversionError(error, 18, @"DWG 转图片失败。");
        return NO;
    }
}

+ (BOOL)convertPDFAtPath:(NSString *)sourcePath
             toDWGAtPath:(NSString *)targetPath
                   error:(NSError **)error
{
    if (!ValidateConversionPaths(sourcePath, targetPath, error)) {
        return NO;
    }

    [CADEngineBootstrap activateIfNeeded];

    try {
        return ExportPDFToDWG(sourcePath, targetPath, error);
    } catch (const OdError& e) {
        NSString *message = [NSString stringWithFormat:@"PDF 转 DWG 失败：%@", OdString2NSString(e.description())];
        AssignConversionError(error, 23, message);
        return NO;
    } catch (...) {
        AssignConversionError(error, 24, @"PDF 转 DWG 失败。");
        return NO;
    }
}

@end
