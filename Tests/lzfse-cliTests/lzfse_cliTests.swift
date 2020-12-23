import XCTest
import class Foundation.Bundle

final class lzfse_cliTests: XCTestCase {
        
    var temporaryDirectory: URL?
    
    
    override class func setUp() {
    }
    
    override class func tearDown() {
    }
    
    override func setUp() {
        var url = FileManager.default.temporaryDirectory
        let uuid = UUID().uuidString
        url.appendPathComponent(uuid, isDirectory: true)
        
        self.temporaryDirectory = url
        
        do {
            try FileManager.default.createDirectory(at: self.temporaryDirectory!,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
        }
        catch {
            XCTAssert(false)
        }
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: self.temporaryDirectory!)
    }
    
    
    func testEncodeFile() throws {
        _ = try self.processRun(arguments: ["--encode",
                                            "-i",
                                            URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/alice29", ofType: "txt")!).path,
                                            "-o",
                                            self.temporaryDirectory!.path
        ])
        
        
        var outputPath = self.temporaryDirectory!.appendingPathComponent("alice29.txt")
        outputPath.appendPathExtension("lzfse")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    func testEncodeFileOmitOutput() throws {
        try FileManager.default.copyItem(at: URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/alice29", ofType: "txt")!),
                                         to: temporaryDirectory!.appendingPathComponent("alice29.txt"))
        
        let inputPath = self.temporaryDirectory!.appendingPathComponent("alice29.txt")
        
        _ = try self.processRun(arguments: ["--encode",
                                            "-i",
                                            inputPath.path,
        ])
        
        
        var outputPath = self.temporaryDirectory!.appendingPathComponent("alice29.txt")
        outputPath.appendPathExtension("lzfse")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    func testDecodeFile() throws {
        _ = try self.processRun(arguments: ["--decode",
                                            "-i",
                                            URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/alice29.txt", ofType: "lzfse")!).path,
                                            "-o",
                                            self.temporaryDirectory!.path
        ])
        
        
        let outputPath = self.temporaryDirectory!.appendingPathComponent("alice29.txt")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    func testDecodeFileOmitOutput() throws {
        try FileManager.default.copyItem(at: URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/alice29.txt", ofType: "lzfse")!),
                                         to: temporaryDirectory!.appendingPathComponent("alice29.txt.lzfse"))
        
        let inputPath = self.temporaryDirectory!.appendingPathComponent("alice29.txt.lzfse")
        
        _ = try self.processRun(arguments: ["--decode",
                                            "-i",
                                            inputPath.path,
        ])
        
        
        let outputPath = self.temporaryDirectory!.appendingPathComponent("alice29.txt")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    func testEncodeDirectory() throws {
        _ = try self.processRun(arguments: ["--encode",
                                            "-i",
                                            URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/dir", ofType: nil)!).path,
                                            "-o",
                                            self.temporaryDirectory!.path
        ])
        
        
        var outputPath = self.temporaryDirectory!.appendingPathComponent("dir")
        outputPath.appendPathExtension("aar")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    func testEncodeDirectoryOmitOutput() throws {
        try FileManager.default.copyItem(at: URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/dir", ofType: nil)!),
                                         to: temporaryDirectory!.appendingPathComponent("dir"))
        
        let inputPath = self.temporaryDirectory!.appendingPathComponent("dir")
        
        _ = try self.processRun(arguments: ["--encode",
                                            "-i",
                                            inputPath.path,
        ])
        
        
        var outputPath = self.temporaryDirectory!.appendingPathComponent("dir")
        outputPath.appendPathExtension("aar")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    func testDecodeDirectory() throws {
        _ = try self.processRun(arguments: ["--decode",
                                            "-i",
                                            URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/dir", ofType: "aar")!).path,
                                            "-o",
                                            self.temporaryDirectory!.path
        ])
        
        
        let outputPath = self.temporaryDirectory!.appendingPathComponent("dir")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    func testDecodeDirectoryOmitOutput() throws {
        try FileManager.default.copyItem(at: URL(fileURLWithPath: Bundle.module.path(forResource: "Resources/dir", ofType: "aar")!),
                                         to: temporaryDirectory!.appendingPathComponent("dir.aar"))
        
        let inputPath = self.temporaryDirectory!.appendingPathComponent("dir.aar")
        
        _ = try self.processRun(arguments: ["--decode",
                                            "-i",
                                            inputPath.path,
        ])
        
        
        let outputPath = self.temporaryDirectory!.appendingPathComponent("dir")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
    }
    
    
    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
    
    
    func processRun(arguments: [String]) throws -> String? {
        let fooBinary = productsDirectory.appendingPathComponent("lzfse-cli")
        
        let process = Process()
        process.executableURL = fooBinary
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        return output
    }
    
    
    static var allTests = [
        ("testEncodeFile", testEncodeFile),
        ("testEncodeFileOmitOutput", testEncodeFileOmitOutput),
        ("testDecodeFile", testDecodeFile),
        ("testDecodeFileOmitOutput", testDecodeFileOmitOutput),
        ("testEncodeDirectory", testEncodeDirectory),
        ("testEncodeDirectoryOmitOutput", testEncodeDirectoryOmitOutput),
        ("testDecodeDirectory", testDecodeDirectory),
        ("testDecodeDirectoryOmitOutput", testDecodeDirectoryOmitOutput),
    ]
}
