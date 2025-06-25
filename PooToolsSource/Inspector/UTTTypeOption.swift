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
            return UTType.image.identifier as CFString
        case .jpeg:
            return UTType.jpeg.identifier as CFString
        case .tiff:
            return UTType.tiff.identifier as CFString
        case .gif:
            return UTType.gif.identifier as CFString
        case .png:
            return UTType.png.identifier as CFString
        case .appleICNS:
            return UTType.icns.identifier as CFString
        case .bpm:
            return UTType.bmp.identifier as CFString
        case .ico:
            return UTType.ico.identifier as CFString
        case .rawImage:
            return UTType.rawImage.identifier as CFString
        case .scalableVectorGraphics:
            return UTType.svg.identifier as CFString
        case .livePhoto:
            return UTType.livePhoto.identifier as CFString
        case .audiovisualContent:
            return UTType.audiovisualContent.identifier as CFString
        case .movie:
            return UTType.movie.identifier as CFString
        case .video:
            return UTType.video.identifier as CFString
        case .audio:
            return UTType.audio.identifier as CFString
        case .quickTimeMovie:
            return UTType.quickTimeMovie.identifier as CFString
        case .mpeg:
            return UTType.mpeg.identifier as CFString
        case .mpeg2Video:
            return UTType.mpeg2Video.identifier as CFString
        case .mpeg2TransportStream:
            return UTType.mpeg2TransportStream.identifier as CFString
        case .mp3:
            return UTType.mp3.identifier as CFString
        case .mpeg4:
            return UTType.mpeg4Movie.identifier as CFString
        case .mpeg4Audio:
            return UTType.mpeg4Audio.identifier as CFString
        case .appleProtectedMPEG4Audio:
            return UTType.appleProtectedMPEG4Audio.identifier as CFString
        case .appleProtectedMPEG4Video:
            return UTType.appleProtectedMPEG4Video.identifier as CFString
        case .aviMovie:
            return UTType.avi.identifier as CFString
        case .waveformAudio:
            return UTType.wav.identifier as CFString
        case .midiAudio:
            return UTType.midi.identifier as CFString
        case .playlist:
            return UTType.playlist.identifier as CFString
        case .m3uPlaylist:
            return UTType.m3uPlaylist.identifier as CFString
        case .folder:
            return UTType.folder.identifier as CFString
        case .volume:
            return UTType.volume.identifier as CFString
        case .package:
            return UTType.package.identifier as CFString
        case .bundle:
            return UTType.bundle.identifier as CFString
        case .pluginBundle:
            return UTType.pluginBundle.identifier as CFString
        case .spotlightImporter:
            return UTType.spotlightImporter.identifier as CFString
        case .quickLookGenerator:
            return UTType.quickLookGenerator.identifier as CFString
        case .xpcService:
            return UTType.xpcService.identifier as CFString
        case .framework:
            return UTType.framework.identifier as CFString
        case .application:
            return UTType.application.identifier as CFString
        case .applicationBundle:
            return UTType.applicationBundle.identifier as CFString
        case .unixExecutable:
            return UTType.unixExecutable.identifier as CFString
        case .systemPreferencesPane:
            return UTType.systemPreferencesPane.identifier as CFString
        case .gnuZipArchive:
            return UTType.gzip.identifier as CFString
        case .bzip2Archive:
            return UTType.bz2.identifier as CFString
        case .zipArchive:
            return UTType.zip.identifier as CFString
        case .spreadsheet:
            return UTType.spreadsheet.identifier as CFString
        case .presentation:
            return UTType.presentation.identifier as CFString
        case .database:
            return UTType.database.identifier as CFString
        case .vCard:
            return UTType.vCard.identifier as CFString
        case .toDoItem:
            return UTType.toDoItem.identifier as CFString
        case .calendarEvent:
            return UTType.calendarEvent.identifier as CFString
        case .emailMessage:
            return UTType.emailMessage.identifier as CFString
        case .internetLocation:
            return UTType.internetLocation.identifier as CFString
        case .font:
            return UTType.font.identifier as CFString
        case .bookmark:
            return UTType.bookmark.identifier as CFString
        case .pkcs12:
            return UTType.pkcs12.identifier as CFString
        case .x509Certificate:
            return UTType.x509Certificate.identifier as CFString
        case .log:
            return UTType.log.identifier as CFString
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

