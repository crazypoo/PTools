//
//  PTRichTextMediaController.swift
//  PToolsUIFoundation
//
// English: Resolve rich-media attachments for UIKit hosts with cancellation and generation checks.
// Español: Resuelve adjuntos multimedia para hosts UIKit con cancelación y comprobaciones de generación.
// 中文：为 UIKit 宿主解析富媒体附件，并提供取消与 generation 校验。
//

import Foundation
import UIKit

// English: Resolve image and video attachments with one controller, preserving generations during host reuse.
// Español: Resuelve adjuntos de imagen y vídeo con un solo controlador y conserva generaciones durante la reutilización.
// 中文：使用一个控制器解析图片和视频附件，并在宿主复用时保护 generation。
@MainActor
final class PTRichTextMediaController: NSObject {
    private weak var label: UILabel?
    private weak var textView: UITextView?
    private let richText: PTRichText
    private let loader: PTRichTextMediaLoader
    private var tokens: [UUID: PTRichTextMediaLoadToken] = [:]
    private var generations: [UUID: UInt64] = [:]
    private var resolvedImages: [UUID: (image: UIImage, size: CGSize)] = [:]

    init(richText: PTRichText,
         label: UILabel? = nil,
         textView: UITextView? = nil,
         loader: PTRichTextMediaLoader) {
        self.richText = richText
        self.label = label
        self.textView = textView
        self.loader = loader
        super.init()
    }

    func start() {
        var attachments: [PTRichTextMediaAttachment] = []
        richText.value.enumerateAttribute(.attachment,
                                          in: NSRange(location: 0, length: richText.value.length),
                                          options: []) { value, _, _ in
            guard let attachment = value as? PTRichTextMediaTextAttachment,
                  !attachments.contains(where: { $0.id == attachment.media.id }) else {
                return
            }
            attachments.append(attachment.media)
        }
        attachments.forEach(load)
    }

    func cancel() {
        tokens.values.forEach { $0.cancel() }
        tokens.removeAll(keepingCapacity: false)
        generations.removeAll(keepingCapacity: false)
        resolvedImages.removeAll(keepingCapacity: false)
    }

    private func load(_ media: PTRichTextMediaAttachment) {
        let generation = (generations[media.id] ?? 0) &+ 1
        generations[media.id] = generation
        media.generation = generation
        media.loadState = .loading

        let task = Task { @MainActor [weak self, media] in
            guard let self else { return }
            do {
                let result: (image: UIImage, metadata: PTRichTextVideoMetadata)
                let displayImage: UIImage
                switch media.kind {
                case .image:
                    displayImage = try await loader.loadImage(source: media.source,
                                                              targetSize: media.displayConfiguration.preferredSize)
                    result = (displayImage, .init())
                case .video:
                    let configuration = media.videoConfiguration ?? PTRichTextVideoConfiguration()
                    let poster: UIImage
                    let metadata: PTRichTextVideoMetadata
                    if let posterSource = media.posterSource {
                        poster = try await loader.loadImage(source: posterSource,
                                                            targetSize: media.displayConfiguration.preferredSize)
                        metadata = configuration.showsDuration
                            ? await loader.loadVideoMetadata(source: media.source)
                            : .init()
                    } else {
                        let posterResult = try await loader.loadVideoPoster(source: media.source,
                                                                            frameNumber: configuration.thumbnailFrameNumber,
                                                                            time: configuration.thumbnailTime,
                                                                            targetSize: media.displayConfiguration.preferredSize)
                        poster = posterResult.image
                        metadata = posterResult.metadata
                    }
                    displayImage = PTRichTextVideoPosterRenderer.render(image: poster,
                                                                         metadata: metadata,
                                                                         configuration: configuration,
                                                                         id: media.id)
                    result = (displayImage, metadata)
                }

                guard !Task.isCancelled,
                      generations[media.id] == generation,
                      media.generation == generation else {
                    return
                }
                media.metadata = result.metadata
                media.loadState = .loaded
                tokens[media.id] = nil
                apply(result.image,
                      to: media,
                      size: media.displayConfiguration.resolvedSize(for: result.image,
                                                                     naturalSize: result.metadata.naturalSize))
            } catch is CancellationError {
                guard generations[media.id] == generation else { return }
                media.loadState = .cancelled
                tokens[media.id] = nil
            } catch {
                guard generations[media.id] == generation else { return }
                media.loadState = .failed
                tokens[media.id] = nil
                if let failureImage = media.failureImage {
                    apply(failureImage,
                          to: media,
                          size: media.displayConfiguration.resolvedSize(for: failureImage))
                }
            }
        }
        tokens[media.id] = PTRichTextMediaLoadToken(task: task)
    }

    private func apply(_ image: UIImage,
                       to media: PTRichTextMediaAttachment,
                       size: CGSize) {
        resolvedImages[media.id] = (image, size)
        let updated = NSMutableAttributedString(attributedString: richText.value)
        updated.enumerateAttribute(.attachment,
                                   in: NSRange(location: 0, length: updated.length),
                                   options: []) { value, subrange, _ in
            guard let attachment = value as? PTRichTextMediaTextAttachment,
                  let resolved = resolvedImages[attachment.media.id] else {
                return
            }
            updated.addAttribute(.attachment,
                                 value: attachment.resolvedAttachment(with: resolved.image,
                                                                       size: resolved.size),
                                 range: subrange)
        }
        label?.attributedText = updated
        textView?.attributedText = updated
    }
}
