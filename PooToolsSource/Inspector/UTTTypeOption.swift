//
//  UTTTypeOption.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

public typealias UTTTypeOptions = [UTTTypeOption]

public enum UTTTypeOption: Equatable, Hashable {
    case image
    case jpeg
    case tiff
    case gif
    case png
    case appleICNS
    case bpm
    case ico
    case rawImage
    case scalableVectorGraphics
    case livePhoto
    case audiovisualContent
    case movie
    case video
    case audio
    case quickTimeMovie
    case mpeg
    case mpeg2Video
    case mpeg2TransportStream
    case mp3
    case mpeg4
    case mpeg4Audio
    case appleProtectedMPEG4Audio
    case appleProtectedMPEG4Video
    case aviMovie
    case waveformAudio
    case midiAudio
    case playlist
    case m3uPlaylist
    case folder
    case volume
    case package
    case bundle
    case pluginBundle
    case spotlightImporter
    case quickLookGenerator
    case xpcService
    case framework
    case application
    case applicationBundle
    case unixExecutable
    case systemPreferencesPane
    case gnuZipArchive
    case bzip2Archive
    case zipArchive
    case spreadsheet
    case presentation
    case database
    case vCard
    case toDoItem
    case calendarEvent
    case emailMessage
    case internetLocation
    case font
    case bookmark
    case x509Certificate
    case log
    case pkcs12
    
    var rawValue: String {
        String(cfString)
    }
    
    var uttType: UTType {
        switch self {
        case .image:
            return .image
        case .jpeg:
            return .jpeg
        case .tiff:
            return .tiff
        case .gif:
            return .gif
        case .png:
            return .png
        case .appleICNS:
            return .icns
        case .bpm:
            return .bmp
        case .ico:
            return .ico
        case .rawImage:
            return .rawImage
        case .scalableVectorGraphics:
            return .svg
        case .livePhoto:
            return .livePhoto
        case .audiovisualContent:
            return .audiovisualContent
        case .movie:
            return .movie
        case .video:
            return .video
        case .audio:
            return .audio
        case .quickTimeMovie:
            return .quickTimeMovie
        case .mpeg:
            return .mpeg
        case .mpeg2Video:
            return .mpeg2Video
        case .mpeg2TransportStream:
            return .mpeg2TransportStream
        case .mp3:
            return .mp3
        case .mpeg4:
            return .mpeg4Movie
        case .mpeg4Audio:
            return .mpeg4Audio
        case .appleProtectedMPEG4Audio:
            return .appleProtectedMPEG4Audio
        case .appleProtectedMPEG4Video:
            return .appleProtectedMPEG4Video
        case .aviMovie:
            return .avi
        case .waveformAudio:
            return .wav
        case .midiAudio:
            return .midi
        case .playlist:
            return .playlist
        case .m3uPlaylist:
            return .m3uPlaylist
        case .folder:
            return .folder
        case .volume:
            return .volume
        case .package:
            return .package
        case .bundle:
            return .bundle
        case .pluginBundle:
            return .pluginBundle
        case .spotlightImporter:
            return .spotlightImporter
        case .quickLookGenerator:
            return .quickLookGenerator
        case .xpcService:
            return .xpcService
        case .framework:
            return .framework
        case .application:
            return .application
        case .applicationBundle:
            return .applicationBundle
        case .unixExecutable:
            return .unixExecutable
        case .systemPreferencesPane:
            return .systemPreferencesPane
        case .gnuZipArchive:
            return .gzip
        case .bzip2Archive:
            return .bz2
        case .zipArchive:
            return .zip
        case .spreadsheet:
            return .spreadsheet
        case .presentation:
            return .presentation
        case .database:
            return .database
        case .vCard:
            return .vCard
        case .toDoItem:
            return .toDoItem
        case .calendarEvent:
            return .calendarEvent
        case .emailMessage:
            return .emailMessage
        case .internetLocation:
            return .internetLocation
        case .font:
            return .font
        case .bookmark:
            return .bookmark
        case .pkcs12:
            return .pkcs12
        case .x509Certificate:
            return .x509Certificate
        case .log:
            return .log
        }
    }
    
    private var cfString: CFString {
        switch self {
        case .image:
            return kUTTypeImage
        case .jpeg:
            return kUTTypeJPEG
        case .tiff:
            return kUTTypeTIFF
        case .gif:
            return kUTTypeGIF
        case .png:
            return kUTTypePNG
        case .appleICNS:
            return kUTTypeAppleICNS
        case .bpm:
            return kUTTypeBMP
        case .ico:
            return kUTTypeICO
        case .rawImage:
            return kUTTypeRawImage
        case .scalableVectorGraphics:
            return kUTTypeScalableVectorGraphics
        case .livePhoto:
            return kUTTypeLivePhoto
        case .audiovisualContent:
            return kUTTypeAudiovisualContent
        case .movie:
            return kUTTypeMovie
        case .video:
            return kUTTypeVideo
        case .audio:
            return kUTTypeAudio
        case .quickTimeMovie:
            return kUTTypeQuickTimeMovie
        case .mpeg:
            return kUTTypeMPEG
        case .mpeg2Video:
            return kUTTypeMPEG2Video
        case .mpeg2TransportStream:
            return kUTTypeMPEG2TransportStream
        case .mp3:
            return kUTTypeMP3
        case .mpeg4:
            return kUTTypeMPEG4
        case .mpeg4Audio:
            return kUTTypeMPEG4Audio
        case .appleProtectedMPEG4Audio:
            return kUTTypeAppleProtectedMPEG4Audio
        case .appleProtectedMPEG4Video:
            return kUTTypeAppleProtectedMPEG4Video
        case .aviMovie:
            return kUTTypeAVIMovie
        case .waveformAudio:
            return kUTTypeWaveformAudio
        case .midiAudio:
            return kUTTypeMIDIAudio
        case .playlist:
            return kUTTypePlaylist
        case .m3uPlaylist:
            return kUTTypeM3UPlaylist
        case .folder:
            return kUTTypeFolder
        case .volume:
            return kUTTypeVolume
        case .package:
            return kUTTypePackage
        case .bundle:
            return kUTTypeBundle
        case .pluginBundle:
            return kUTTypePluginBundle
        case .spotlightImporter:
            return kUTTypeSpotlightImporter
        case .quickLookGenerator:
            return kUTTypeQuickLookGenerator
        case .xpcService:
            return kUTTypeXPCService
        case .framework:
            return kUTTypeFramework
        case .application:
            return kUTTypeApplication
        case .applicationBundle:
            return kUTTypeApplicationBundle
        case .unixExecutable:
            return kUTTypeUnixExecutable
        case .systemPreferencesPane:
            return kUTTypeSystemPreferencesPane
        case .gnuZipArchive:
            return kUTTypeGNUZipArchive
        case .bzip2Archive:
            return kUTTypeBzip2Archive
        case .zipArchive:
            return kUTTypeZipArchive
        case .spreadsheet:
            return kUTTypeSpreadsheet
        case .presentation:
            return kUTTypePresentation
        case .database:
            return kUTTypeDatabase
        case .vCard:
            return kUTTypeVCard
        case .toDoItem:
            return kUTTypeToDoItem
        case .calendarEvent:
            return kUTTypeCalendarEvent
        case .emailMessage:
            return kUTTypeEmailMessage
        case .internetLocation:
            return kUTTypeInternetLocation
        case .font:
            return kUTTypeFont
        case .bookmark:
            return kUTTypeBookmark
        case .pkcs12:
            return kUTTypePKCS12
        case .x509Certificate:
            return kUTTypeX509Certificate
        case .log:
            return kUTTypeLog
        }
    }
}

extension Collection where Element == UTTTypeOption {
    var rawValues: [String] {
        map { $0.rawValue }
    }
    
    var uttypes: [UTType] {
        map { $0.uttType }
    }
}

