import Testing
import UniformTypeIdentifiers
@testable import Recon

struct OutputFormatTests {

    @Test("UTType maps to the canonical type identifier per format")
    func utTypeMapping() {
        #expect(OutputFormat.jpeg.utType == .jpeg)
        #expect(OutputFormat.webp.utType == .webP)
        #expect(OutputFormat.png.utType == .png)
        #expect(OutputFormat.tiff.utType == .tiff)
        #expect(OutputFormat.avif.utType.identifier == "public.avif")
    }

    @Test("Filename extensions are lowercase, bare, no leading dot")
    func filenameExtensions() {
        #expect(OutputFormat.jpeg.filenameExtension == "jpg")
        #expect(OutputFormat.webp.filenameExtension == "webp")
        #expect(OutputFormat.avif.filenameExtension == "avif")
        #expect(OutputFormat.png.filenameExtension == "png")
        #expect(OutputFormat.tiff.filenameExtension == "tiff")
        for format in OutputFormat.allCases {
            #expect(!format.filenameExtension.hasPrefix("."))
            #expect(format.filenameExtension == format.filenameExtension.lowercased())
        }
    }

    @Test("MIME types are canonical IANA names")
    func mimeTypes() {
        #expect(OutputFormat.jpeg.mimeType == "image/jpeg")
        #expect(OutputFormat.webp.mimeType == "image/webp")
        #expect(OutputFormat.avif.mimeType == "image/avif")
        #expect(OutputFormat.png.mimeType == "image/png")
        #expect(OutputFormat.tiff.mimeType == "image/tiff")
    }

    @Test("supportsQuality is true only for lossy formats")
    func supportsQualityTable() {
        #expect(OutputFormat.jpeg.supportsQuality)
        #expect(OutputFormat.webp.supportsQuality)
        #expect(OutputFormat.avif.supportsQuality)
        #expect(!OutputFormat.png.supportsQuality)
        #expect(!OutputFormat.tiff.supportsQuality)
    }

    @Test("Every case has a non-empty display name and subtitle")
    func displayStrings() {
        for format in OutputFormat.allCases {
            #expect(!format.displayName.isEmpty)
            #expect(!format.subtitle.isEmpty)
        }
    }

    @Test("All five formats are present and ordered")
    func caseIteration() {
        let expected: [OutputFormat] = [.jpeg, .webp, .avif, .png, .tiff]
        #expect(OutputFormat.allCases == expected)
    }
}
