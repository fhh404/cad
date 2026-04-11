import Foundation

struct ConversionDocumentStore {
    static let defaultBaseDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    .appendingPathComponent("ConvertedDocuments", isDirectory: true)

    private let userDefaults: UserDefaults
    private let baseDirectory: URL
    private let dateProvider: () -> Date
    private let storageKey = "conversion.documents.v1"

    init(
        userDefaults: UserDefaults = .standard,
        baseDirectory: URL = Self.defaultBaseDirectory,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.baseDirectory = baseDirectory
        self.dateProvider = dateProvider
    }

    func documents(for kind: ConversionKind? = nil) -> [ConversionDocument] {
        loadDocuments()
            .filter { kind == nil || $0.kind == kind }
            .sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func saveConvertedPlaceholder(
        kind: ConversionKind,
        sourceName: String? = nil
    ) throws -> ConversionDocument {
        try FileManager.default.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )

        let id = UUID()
        let outputFileName = outputFileName(for: kind, sourceName: sourceName)
        let relativePath = "\(id.uuidString)-\(outputFileName)"
        let fileURL = baseDirectory.appendingPathComponent(relativePath, isDirectory: false)
        let data = Data("Mock converted file for \(kind.title)".utf8)
        try data.write(to: fileURL, options: .atomic)

        let document = ConversionDocument(
            id: id,
            kind: kind,
            fileName: outputFileName,
            createdAt: dateProvider(),
            relativePath: relativePath
        )

        var documents = loadDocuments()
        documents.removeAll { $0.id == document.id }
        documents.insert(document, at: 0)
        saveDocuments(documents)
        return document
    }

    private func outputFileName(for kind: ConversionKind, sourceName: String?) -> String {
        let rawName = sourceName ?? kind.defaultSourceFileName
        let baseName = (rawName as NSString).deletingPathExtension
        return "\(baseName).\(kind.outputExtension)"
    }

    private func loadDocuments() -> [ConversionDocument] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        return (try? JSONDecoder().decode([ConversionDocument].self, from: data)) ?? []
    }

    private func saveDocuments(_ documents: [ConversionDocument]) {
        guard let data = try? JSONEncoder().encode(documents) else {
            return
        }

        userDefaults.set(data, forKey: storageKey)
    }
}
