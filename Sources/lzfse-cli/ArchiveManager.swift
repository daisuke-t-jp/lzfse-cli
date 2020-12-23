// Copyright 2020 Daisuke TONOSAKI
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import System
import AppleArchive

class ArchiveManager {
    
    // MARK: - Singleton
    public static let sharedInstance = ArchiveManager()
    
    
    // MARK: - Enum, Const
    public struct ArchiveResult {
        let inputSize: UInt64
        let outputSize: UInt64
    }
    
    public static let extensionLZFSE: String = "lzfse"
    public static let extensionAAR: String = "aar"
    
    private static let permission: FilePermissions = [.ownerReadWrite, .groupRead, .otherRead]
    private static let fieldKeySet: String = "TYP,PAT,LNK,DEV,DAT,UID,GID,MOD,FLG,MTM,BTM,CTM"
    private static let blockSizeDefault: Int = (1 << 20)
    private static let threadCountDefault: Int = 0
    private static let archiveFlagsDefault: ArchiveFlags = [.verbosity(level: 0)]
    
    
    // MARK: - Property
    public var blockSize: Int = blockSizeDefault
    public var threadCount: Int = threadCountDefault
    public var isVerbose: Bool = false  // TODO: Use this flag.
}


// MARK: - Settings
extension ArchiveManager {

    public func resetSettings() {
        self.blockSize = ArchiveManager.blockSizeDefault
        self.threadCount = ArchiveManager.threadCountDefault
    }
    
}


// MARK: - Utility
extension ArchiveManager {
    
    private func removeExistsOuputFileIfNeeded(outputPath: FilePath, overwritable: Bool) -> Bool {
        guard FileManager.default.fileExists(atPath: outputPath.description) else {
            return true
        }
        
        guard overwritable else {
            Print.stderrWrite("\(outputPath.description) is already exists")
            
            return false
        }
        
        
        do {
            try FileManager.default.removeItem(atPath: outputPath.description)
        }
        catch {
            return false
        }
        
        return true
    }
    
}


// MARK: - Stream
extension ArchiveManager {
    
    private func readFileStream(path: FilePath) -> ArchiveByteStream? {
        ArchiveByteStream.fileStream(path: path,
                                     mode: .readOnly,
                                     options: [],
                                     permissions: ArchiveManager.permission)
    }
    
    
    private func writeFileStream(path: FilePath) -> ArchiveByteStream? {
        ArchiveByteStream.fileStream(path: path,
                                     mode: .writeOnly,
                                     options: [.create],
                                     permissions: ArchiveManager.permission)
    }
    
    
    private func compressionStream(writingTo stream: ArchiveByteStream) -> ArchiveByteStream? {
        ArchiveByteStream.compressionStream(using: .lzfse,
                                            writingTo: stream,
                                            blockSize: self.blockSize,
                                            flags: ArchiveManager.archiveFlagsDefault,
                                            threadCount: self.threadCount)
    }
    
    
    private func decompressionStream(readingFrom stream: ArchiveByteStream) -> ArchiveByteStream? {
        ArchiveByteStream.decompressionStream(readingFrom: stream,
                                              flags: ArchiveManager.archiveFlagsDefault,
                                              threadCount: self.threadCount)
    }
    
    
    private func encodeStream(writingTo stream: ArchiveByteStream) -> ArchiveStream? {
        ArchiveStream.encodeStream(writingTo: stream,
                                   selectUsing: nil,
                                   flags: ArchiveManager.archiveFlagsDefault,
                                   threadCount: self.threadCount)
    }
    
    
    private func decodeStream(readingFrom stream: ArchiveByteStream) -> ArchiveStream? {
        ArchiveStream.decodeStream(readingFrom: stream,
                                   selectUsing: nil,
                                   flags: ArchiveManager.archiveFlagsDefault,
                                   threadCount: self.threadCount)
    }
    
    
    private func extractStream(extractingTo: FilePath) -> ArchiveStream? {
        var flags: ArchiveFlags = ArchiveManager.archiveFlagsDefault
        flags.insert(.ignoreOperationNotPermitted)
        
        return ArchiveStream.extractStream(extractingTo: extractingTo,
                                           selectUsing: nil,
                                           flags: flags,
                                           threadCount: self.threadCount)
    }
    
    
    private func process(readingFrom input: ArchiveStream, writingTo output: ArchiveStream) throws -> Int {
        do {
            return try ArchiveStream.process(readingFrom: input,
                                             writingTo: output,
                                             selectUsing: nil,
                                             flags: ArchiveManager.archiveFlagsDefault,
                                             threadCount: self.threadCount)
        }
        catch {
            throw error
        }
    }
    
}


// MARK: - Encode
extension ArchiveManager {
    
    public func encode(inputPath: FilePath, outputPath: FilePath, overwritable: Bool) -> ArchiveResult? {
        
        guard self.removeExistsOuputFileIfNeeded(outputPath: outputPath, overwritable: overwritable) else {
            return nil
        }
        
        
        do {
            guard let readFileStream = self.readFileStream(path: inputPath) else {
                Print.stderrWrite("\(inputPath.description) can't open.")
                return nil
            }
            defer {
                try? readFileStream.close()
            }
            
            
            guard let writeFileStream = self.writeFileStream(path: outputPath) else {
                Print.stderrWrite("\(outputPath.description) is invalid path.")
                return nil
            }
            defer {
                try? writeFileStream.close()
            }
            
            
            guard let compressStream = self.compressionStream(writingTo: writeFileStream) else {
                return nil
            }
            defer {
                try? compressStream.close()
            }
            
            
            do {
                _ = try ArchiveByteStream.process(readingFrom: readFileStream, writingTo: compressStream)
            }
            catch {
                return nil
            }
        }
        
        
        let res = ArchiveResult(inputSize: FileManager.default.fileSize(path: inputPath.description),
                                outputSize: FileManager.default.fileSize(path: outputPath.description))
        
        return res
    }
    
    
    public func encodeDirectory(inputPath: FilePath, outputPath: FilePath, overwritable: Bool) -> ArchiveResult? {
        
        guard self.removeExistsOuputFileIfNeeded(outputPath: outputPath, overwritable: overwritable) else {
            return nil
        }
        
        
        do {
            guard let writeFileStream = self.writeFileStream(path: outputPath) else {
                Print.stderrWrite("\(outputPath.description) is invalid path.")
                return nil
            }
            defer {
                try? writeFileStream.close()
            }
            
            
            guard let compressStream = self.compressionStream(writingTo: writeFileStream) else {
                return nil
            }
            defer {
                try? compressStream.close()
            }
            
            
            guard let encodeStream = self.encodeStream(writingTo: compressStream) else {
                return nil
            }
            defer {
                try? encodeStream.close()
            }
            
            
            guard let fieldKeySet = ArchiveHeader.FieldKeySet(ArchiveManager.fieldKeySet) else {
                return nil
            }
            
            
            do {
                try encodeStream.writeDirectoryContents(archiveFrom: inputPath,
                                                        path: nil,
                                                        keySet: fieldKeySet,
                                                        selectUsing: nil,
                                                        flags: ArchiveManager.archiveFlagsDefault,
                                                        threadCount: self.threadCount)
            }
            catch {
                return nil
            }
        }
        
        
        let res = ArchiveResult(inputSize: FileManager.default.directorySize(path: inputPath.description),
                                outputSize: FileManager.default.directorySize(path: outputPath.description))
        
        return res
    }
}


// MARK: - Decode
extension ArchiveManager {
    
    public func decode(inputPath: FilePath, outputPath: FilePath, overwritable: Bool) -> ArchiveResult? {
        
        guard self.removeExistsOuputFileIfNeeded(outputPath: outputPath, overwritable: overwritable) else {
            return nil
        }
        
        
        do {
            guard let readFileStream = self.readFileStream(path: inputPath) else {
                Print.stderrWrite("\(inputPath.description) can't open.")
                return nil
            }
            defer {
                try? readFileStream.close()
            }
            
            
            guard let writeFileStream = self.writeFileStream(path: outputPath) else {
                Print.stderrWrite("\(outputPath.description) is invalid path.")
                return nil
            }
            defer {
                try? writeFileStream.close()
            }
            
            
            guard let decompressStream = self.decompressionStream(readingFrom: readFileStream) else {
                return nil
            }
            defer {
                try? decompressStream.close()
            }
            
            
            do {
                _ = try ArchiveByteStream.process(readingFrom: decompressStream, writingTo: writeFileStream)
            }
            catch {
                return nil
            }
        }
        
        
        let res = ArchiveResult(inputSize: FileManager.default.fileSize(path: inputPath.description),
                                outputSize: FileManager.default.fileSize(path: outputPath.description))
        
        return res
    }
    
    
    public func decodeDirectory(inputPath: FilePath, outputPath: FilePath, overwritable: Bool) -> ArchiveResult? {
        
        guard self.removeExistsOuputFileIfNeeded(outputPath: outputPath, overwritable: overwritable) else {
            return nil
        }
        
        
        do {
            guard let readFileStream = self.readFileStream(path: inputPath) else {
                Print.stderrWrite("\(inputPath.description) can't open.")
                return nil
            }
            defer {
                try? readFileStream.close()
            }
            
            
            guard let decompressStream = self.decompressionStream(readingFrom: readFileStream) else {
                return nil
            }
            defer {
                try? decompressStream.close()
            }
            
            
            guard let decodeStream = self.decodeStream(readingFrom: decompressStream) else {
                return nil
            }
            defer {
                try? decodeStream.close()
            }
            
            
            do {
                try FileManager.default.createDirectory(atPath: outputPath.description,
                                                        withIntermediateDirectories: false)
            }
            catch {
                return nil
            }
            
            
            guard let extractStream = self.extractStream(extractingTo: outputPath) else {
                return nil
            }
            defer {
                try? extractStream.close()
            }
            
            
            do {
                _ = try self.process(readingFrom: decodeStream, writingTo: extractStream)
            }
            catch {
                return nil
            }
        }
        
        
        let res = ArchiveResult(inputSize: FileManager.default.directorySize(path: inputPath.description),
                                outputSize: FileManager.default.directorySize(path: outputPath.description))
        
        return res
    }
    
}
