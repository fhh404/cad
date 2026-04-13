#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CADConversionBridge : NSObject

+ (BOOL)convertDWGAtPath:(NSString *)sourcePath
             toDXFAtPath:(NSString *)targetPath
                   error:(NSError **)error NS_SWIFT_NAME(convertDWG(atPath:toDXFAtPath:));

+ (BOOL)convertDWGAtPath:(NSString *)sourcePath
             toPDFAtPath:(NSString *)targetPath
                   error:(NSError **)error NS_SWIFT_NAME(convertDWG(atPath:toPDFAtPath:));

+ (BOOL)convertDWGAtPath:(NSString *)sourcePath
           toImageAtPath:(NSString *)targetPath
                   error:(NSError **)error NS_SWIFT_NAME(convertDWG(atPath:toImageAtPath:));

+ (BOOL)convertPDFAtPath:(NSString *)sourcePath
             toDWGAtPath:(NSString *)targetPath
                   error:(NSError **)error NS_SWIFT_NAME(convertPDF(atPath:toDWGAtPath:));

@end

NS_ASSUME_NONNULL_END
