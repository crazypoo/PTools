//
//  PTLivePhoto.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/2/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos
import CoreMedia

public class PTLivePhoto {
    public typealias PTLivePhotoResources = (pairedImage:URL,pairedVideo:URL)
    /// Returns the paired image and video for the given PHLivePhoto
    public class func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (PTLivePhotoResources?) -> Void) {
        queue.async {
            shared.extractResources(from: livePhoto, completion: completion)
        }
    }
    /// Generates a PHLivePhoto from an image and video.  Also returns the paired image and video.
    public class func generate(from imageURL: URL?, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (PHLivePhoto?, PTLivePhotoResources?) -> Void) {
        queue.async {
            shared.generate(from: imageURL, videoURL: videoURL, progress: progress, completion: completion)
        }
    }
    /// Save a Live Photo to the Photo Library by passing the paired image and video.
    public class func saveToLibrary(_ resources: PTLivePhotoResources, completion: @escaping PTBoolTask) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            creationRequest.addResource(with: PHAssetResourceType.pairedVideo, fileURL: resources.pairedVideo, options: options)
            creationRequest.addResource(with: PHAssetResourceType.photo, fileURL: resources.pairedImage, options: options)
        }, completionHandler: { (success, error) in
            if error != nil {
                PTNSLogConsole(error as Any)
            }
            completion(success)
        })
    }

    private static let shared = PTLivePhoto()
    private static let queue = DispatchQueue(label: "com.crazypoo.PTLivePhoto.queue",attributes: .concurrent)
    fileprivate lazy var cacheDirectory:URL? = {
        let cacheDirectoryURL = FileManager.pt.CachesDirectory()
        let fullDirectory = cacheDirectoryURL.appendingPathComponent("com.crazypoo.PTLivePhoto")
        if !FileManager.pt.judgeFileOrFolderExists(filePath: fullDirectory) {
            FileManager.pt.createFolder(folderPath: fullDirectory)
        }
        return URL(fileURLWithPath: fullDirectory)
    }()
    
    deinit {
        cleaarCache()
    }
    
    private func cleaarCache() {
        if let cacheDirectory = cacheDirectory {
            FileManager.pt.removefile(filePath: cacheDirectory.absoluteString)
        }
    }
    
    private func generateKeyPhoto(from videoURL: URL) -> URL? {
        var percent:Float = 0.5
        let videoAsset = AVURLAsset(url: videoURL)
        if let stillImageTime = videoAsset.stillImageTime() {
            percent = Float(stillImageTime.value) / Float(videoAsset.duration.value)
        }
        guard let imageFrame = videoAsset.getAssetFrame(percent: percent) else { return nil }
        guard let jpegData = imageFrame.jpegData(compressionQuality: 1.0) else { return nil }
        guard let url = cacheDirectory?.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg") else { return nil }
        do {
            try? jpegData.write(to: url)
            return url
        }
    }
    
    private func generate(from imageURL: URL?, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (PHLivePhoto?, PTLivePhotoResources?) -> Void) {
        guard let cacheDirectory = cacheDirectory else {
            PTGCDManager.gcdMain {
                completion(nil, nil)
            }
            return
        }
        let assetIdentifier = UUID().uuidString
        let _keyPhotoURL = imageURL ?? generateKeyPhoto(from: videoURL)
        guard let keyPhotoURL = _keyPhotoURL, let pairedImageURL = addAssetID(assetIdentifier, toImage: keyPhotoURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("jpg")) else {
            PTGCDManager.gcdMain {
                completion(nil, nil)
            }
            return
        }
        addAssetID(assetIdentifier, toVideo: videoURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("mov"), progress: progress) { (_videoURL) in
            if let pairedVideoURL = _videoURL {
                _ = PHLivePhoto.request(withResourceFileURLs: [pairedVideoURL, pairedImageURL], placeholderImage: nil, targetSize: CGSize.zero, contentMode: PHImageContentMode.aspectFit, resultHandler: { (livePhoto: PHLivePhoto?, info: [AnyHashable : Any]) -> Void in
                    if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded {
                        return
                    }
                    PTGCDManager.gcdMain {
                        completion(livePhoto, (pairedImageURL, pairedVideoURL))
                    }
                })
            } else {
                PTGCDManager.gcdMain {
                    completion(nil, nil)
                }
            }
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, to directoryURL: URL, completion: @escaping (PTLivePhotoResources?) -> Void) {
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        let group = DispatchGroup()
        var keyPhotoURL: URL?
        var videoURL: URL?
        for resource in assetResources {
            let buffer = NSMutableData()
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            group.enter()
            PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { (data) in
                buffer.append(data)
            }) { (error) in
                if error == nil {
                    if resource.type == .pairedVideo {
                        videoURL = self.saveAssetResource(resource, to: directoryURL, resourceData: buffer as Data)
                    } else {
                        keyPhotoURL = self.saveAssetResource(resource, to: directoryURL, resourceData: buffer as Data)
                    }
                } else {
                    PTNSLogConsole(error as Any)
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            guard let pairedPhotoURL = keyPhotoURL, let pairedVideoURL = videoURL else {
                completion(nil)
                return
            }
            completion((pairedPhotoURL, pairedVideoURL))
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (PTLivePhotoResources?) -> Void) {
        if let cacheDirectory = cacheDirectory {
            extractResources(from: livePhoto, to: cacheDirectory, completion: completion)
        }
    }
    
    private func saveAssetResource(_ resource: PHAssetResource, to directory: URL, resourceData: Data) -> URL? {
        // 將 resource.uniformTypeIdentifier 轉為 UTType
        guard let utType = UTType(resource.uniformTypeIdentifier),
              let ext = utType.preferredFilenameExtension else {
            return nil
        }

        var fileUrl = directory.appendingPathComponent(UUID().uuidString)
        fileUrl = fileUrl.appendingPathExtension(ext)

        do {
            try resourceData.write(to: fileUrl, options: .atomic)
            return fileUrl
        } catch {
            PTNSLogConsole("Could not save resource \(resource) to filepath \(fileUrl)")
            return nil
        }
    }
    
    func addAssetID(_ assetIdentifier: String, toImage imageURL: URL, saveTo destinationURL: URL) -> URL? {
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil),
              let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
                var imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable : Any] else { return nil }
        let assetIdentifierKey = "17"
        let assetIdentifierInfo = [assetIdentifierKey : assetIdentifier]
        imageProperties[kCGImagePropertyMakerAppleDictionary] = assetIdentifierInfo
        CGImageDestinationAddImage(imageDestination, imageRef, imageProperties as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        return destinationURL
    }
    
    var audioReader: AVAssetReader?
    var videoReader: AVAssetReader?
    var assetWriter: AVAssetWriter?
    
    func addAssetID(_ assetIdentifier: String, toVideo videoURL: URL, saveTo destinationURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (URL?) -> Void ) {

        var audioWriterInput: AVAssetWriterInput?
        var audioReaderOutput: AVAssetReaderOutput?

        let videoAsset = AVURLAsset(url: videoURL)
        let frameCount = videoAsset.countFrames(exact: false)

        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }

        do {
            // Writer
            assetWriter = try AVAssetWriter(outputURL: destinationURL, fileType: .mov)

            // Video Reader
            videoReader = try AVAssetReader(asset: videoAsset)
            let videoReaderSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            let videoReaderOutput = AVAssetReaderTrackOutput(
                track: videoTrack,
                outputSettings: videoReaderSettings
            )
            videoReaderOutput.alwaysCopiesSampleData = false
            videoReader?.add(videoReaderOutput)

            // Video Writer Input
            let videoWriterInput = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoTrack.naturalSize.width,
                    AVVideoHeightKey: videoTrack.naturalSize.height
                ]
            )
            videoWriterInput.transform = videoTrack.preferredTransform
            videoWriterInput.expectsMediaDataInRealTime = false   // ✅ 修正点
            assetWriter?.add(videoWriterInput)

            // Audio
            if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
                let _audioReader = try AVAssetReader(asset: videoAsset)
                let _audioReaderOutput = AVAssetReaderTrackOutput(
                    track: audioTrack,
                    outputSettings: nil
                )
                _audioReader.add(_audioReaderOutput)

                let _audioWriterInput = AVAssetWriterInput(
                    mediaType: .audio,
                    outputSettings: nil
                )
                _audioWriterInput.expectsMediaDataInRealTime = false

                assetWriter?.add(_audioWriterInput)

                audioReader = _audioReader
                audioReaderOutput = _audioReaderOutput
                audioWriterInput = _audioWriterInput
            }

            // Metadata
            let assetIdentifierMetadata = metadataForAssetID(assetIdentifier)
            let stillImageTimeMetadataAdapter = createMetadataAdaptorForStillImageTime()
            assetWriter?.metadata = [assetIdentifierMetadata]
            assetWriter?.add(stillImageTimeMetadataAdapter.assetWriterInput)

            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)

            let stillPercent: Float = 0.5
            let timeRange = videoAsset.makeStillImageTimeRange(
                percent: stillPercent,
                inFrameCount: frameCount
            )
            stillImageTimeMetadataAdapter.append(
                AVTimedMetadataGroup(
                    items: [metadataItemForStillImageTime()],
                    timeRange: timeRange
                )
            )

            var writingVideoFinished = false
            var writingAudioFinished = audioWriterInput == nil
            var currentFrame = 0

            func finishIfPossible() {
                guard writingVideoFinished && writingAudioFinished else { return }
                assetWriter?.finishWriting {
                    if self.assetWriter?.status == .completed {
                        completion(destinationURL)
                    } else {
                        completion(nil)
                    }
                }
            }

            // Video writing
            if videoReader?.startReading() == true {
                videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "pt.livephoto.video")) {
                    while videoWriterInput.isReadyForMoreMediaData {
                        guard let sample = videoReaderOutput.copyNextSampleBuffer() else {
                            videoWriterInput.markAsFinished()
                            writingVideoFinished = true
                            finishIfPossible()
                            return
                        }

                        currentFrame += 1
                        progress(CGFloat(currentFrame) / CGFloat(frameCount))

                        if !videoWriterInput.append(sample) {
                            self.videoReader?.cancelReading()
                            writingVideoFinished = true
                            finishIfPossible()
                            return
                        }
                    }
                }
            } else {
                writingVideoFinished = true
                finishIfPossible()
            }

            // Audio writing
            if let audioReader = audioReader,
               audioReader.startReading(),
               let audioWriterInput = audioWriterInput {

                audioWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "pt.livephoto.audio")) {
                    while audioWriterInput.isReadyForMoreMediaData {
                        guard let sample = audioReaderOutput?.copyNextSampleBuffer() else {
                            audioWriterInput.markAsFinished()
                            writingAudioFinished = true
                            finishIfPossible()
                            return
                        }
                        audioWriterInput.append(sample)
                    }
                }
            } else {
                writingAudioFinished = true
                finishIfPossible()
            }

        } catch {
            PTNSLogConsole(error)
            completion(nil)
        }
    }
    
    private func metadataForAssetID(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyContentIdentifier =  "com.apple.quicktime.content.identifier"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyContentIdentifier as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
    
    private func createMetadataAdaptorForStillImageTime() -> AVAssetWriterInputMetadataAdaptor {
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
            "\(keySpaceQuickTimeMetadata)/\(keyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
            "com.apple.metadata.datatype.int8"            ]
        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [spec] as CFArray, formatDescriptionOut: &desc)
        let input = AVAssetWriterInput(mediaType: .metadata,
                                       outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
    
    private func metadataItemForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyStillImageTime as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = 0 as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
}

fileprivate extension AVAsset {
    func countFrames(exact:Bool) -> Int {
        var frameCount = 0
        if let videoReader = try? AVAssetReader(asset: self)  {
            if let videoTrack = self.tracks(withMediaType: .video).first {
                frameCount = Int(CMTimeGetSeconds(self.duration) * Float64(videoTrack.nominalFrameRate))
                if exact {
                    frameCount = 0
                    let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
                    videoReader.add(videoReaderOutput)
                    videoReader.startReading()
                    // count frames
                    while true {
                        let sampleBuffer = videoReaderOutput.copyNextSampleBuffer()
                        if sampleBuffer == nil {
                            break
                        }
                        frameCount += 1
                    }
                    videoReader.cancelReading()
                }
            }
        }
        return frameCount
    }
    
    func stillImageTime() -> CMTime?  {
        var stillTime:CMTime? = nil
        if let videoReader = try? AVAssetReader(asset: self)  {
            if let metadataTrack = self.tracks(withMediaType: .metadata).first {
                let videoReaderOutput = AVAssetReaderTrackOutput(track: metadataTrack, outputSettings: nil)
                videoReader.add(videoReaderOutput)
                videoReader.startReading()
                let keyStillImageTime = "com.apple.quicktime.still-image-time"
                let keySpaceQuickTimeMetadata = "mdta"
                var found = false
                while found == false {
                    if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() {
                        if CMSampleBufferGetNumSamples(sampleBuffer) != 0 {
                            let group = AVTimedMetadataGroup(sampleBuffer: sampleBuffer)
                            for item in group?.items ?? [] {
                                if item.key as? String == keyStillImageTime && item.keySpace!.rawValue == keySpaceQuickTimeMetadata {
                                    stillTime = group?.timeRange.start
                                    found = true
                                    break
                                }
                            }
                        }
                    } else {
                        break;
                    }
                }
                videoReader.cancelReading()
            }
        }
        return stillTime
    }
    
    func makeStillImageTimeRange(percent:Float, inFrameCount:Int = 0) -> CMTimeRange {
        var time = self.duration
        var frameCount = inFrameCount
        if frameCount == 0 {
            frameCount = self.countFrames(exact: true)
        }
        let frameDuration = Int64(Float(time.value) / Float(frameCount))
        time.value = Int64(Float(time.value) * percent)
        return CMTimeRangeMake(start: time, duration: CMTimeMake(value: frameDuration, timescale: time.timescale))
    }
    
    func getAssetFrame(percent:Float) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(value: 1,timescale: 100)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(value: 1,timescale: 100)
        var time = self.duration
        time.value = Int64(Float(time.value) * percent)
        do {
            var actualTime = CMTime.zero
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime:&actualTime)
            let img = UIImage(cgImage: imageRef)
            return img
        } catch let error as NSError {
            PTNSLogConsole("Image generation failed with error \(error)")
            return nil
        }
    }
}

