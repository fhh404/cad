#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Sets up font search paths for the ODA Visualize (Teigha) DWG engine so that
/// Chinese (and other CJK) text stored in SHX / TTF fonts renders correctly
/// instead of being shown as "?" placeholders.
///
/// The DWG engine resolves fonts through `OdDbHostAppServices::findFile()`,
/// which honours the `ACAD` and `ACADFONTS` environment variables as well as
/// a `FONTMAP` file for font substitution. This helper:
///
///   1. Copies the bundled `Fonts` folder into a writable cache directory
///      (iOS app bundles are read-only, ODA occasionally wants to write temp
///      files alongside fonts, and the env var needs a stable absolute path).
///   2. Exports `ACAD` and `ACADFONTS` pointing at that writable directory so
///      the engine can locate `.shx` / `.ttf` / `.ttc` files via `findFile()`.
///   3. Writes a default `FONTMAP.txt` that maps missing CJK fonts to a
///      fallback font name, so drawings that reference a Chinese font the
///      user has not provided still render glyphs instead of "?".
///
/// Must be called before the Teigha engine is activated
/// (i.e. before `TviActivator::activate()`).
@interface CADFontSupport : NSObject

/// Idempotent. Safe to call multiple times.
+ (void)setupIfNeeded;

/// Absolute path to the writable fonts directory (populated after
/// `setupIfNeeded` has been invoked). May be `nil` if setup failed.
@property (class, nonatomic, readonly, nullable) NSString *fontsDirectoryPath;

@end

NS_ASSUME_NONNULL_END
