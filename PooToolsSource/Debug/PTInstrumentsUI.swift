// English: These lightweight views render PTInstruments snapshots without becoming another diagnostics data source.
// Español: Estas vistas ligeras renderizan snapshots de PTInstruments sin convertirse en otra fuente de diagnóstico.
// 中文：这些轻量视图只负责渲染 PTInstruments 快照，不新增第二套诊断数据源。

import UIKit

// English: The timeline keeps scrolling, zooming, filtering, visibility, and selection in one small adapter.
// Español: La línea de tiempo concentra desplazamiento, zoom, filtros, visibilidad y selección en un adaptador pequeño.
// 中文：时间线适配器统一处理滚动、缩放、过滤、轨道显示和事件选择。
@MainActor
public final class PTInstrumentTimelineView: UIScrollView, UIScrollViewDelegate {
    public var onSelectEvent: ((PTInstrumentEvent) -> Void)?
    public var query: String = "" {
        didSet { canvas.query = query; refreshLayout() }
    }

    public private(set) var timelineSnapshot: PTInstrumentSessionSnapshot?
    private let canvas = PTInstrumentTimelineCanvas()
    private var visibleKinds = Set(PTInstrumentKind.allCases)
    private var zoom: CGFloat = 1

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public func update(snapshot: PTInstrumentSessionSnapshot) {
        self.timelineSnapshot = snapshot
        visibleKinds.formIntersection(snapshot.selectedInstruments)
        canvas.snapshot = snapshot
        canvas.visibleKinds = visibleKinds
        canvas.query = query
        refreshLayout()
    }

    public func setTrackVisible(_ kind: PTInstrumentKind, visible: Bool) {
        if visible {
            visibleKinds.insert(kind)
        } else {
            visibleKinds.remove(kind)
        }
        canvas.visibleKinds = visibleKinds
        refreshLayout()
    }

    public func setZoom(_ value: CGFloat) {
        zoom = min(8, max(0.5, value))
        refreshLayout()
    }

    public func setSelectedRange(_ range: DateInterval?) {
        canvas.selectedRange = range
        canvas.setNeedsDisplay()
    }

    private func commonInit() {
        delegate = self
        alwaysBounceHorizontal = true
        alwaysBounceVertical = false
        showsHorizontalScrollIndicator = true
        showsVerticalScrollIndicator = false
        canvas.onSelectEvent = { [weak self] event in
            self?.onSelectEvent?(event)
        }
        addSubview(canvas)
    }

    private func refreshLayout() {
        let trackCount = max(1, visibleKinds.count)
        let duration = timelineSnapshot?.timeline.duration ?? 1
        let contentWidth = max(bounds.width, CGFloat(duration * 120) * zoom + 40)
        let contentHeight = CGFloat(trackCount * 48)
        canvas.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        contentSize = canvas.bounds.size
        canvas.setNeedsDisplay()
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        canvas
    }
}

@MainActor
private final class PTInstrumentTimelineCanvas: UIView {
    var snapshot: PTInstrumentSessionSnapshot?
    var visibleKinds = Set(PTInstrumentKind.allCases)
    var query = ""
    var selectedRange: DateInterval?
    var onSelectEvent: ((PTInstrumentEvent) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        isAccessibilityElement = false
    }

    override func draw(_ rect: CGRect) {
        guard let timeline = snapshot?.timeline else { return }
        let visibleTracks = timeline.tracks.filter { visibleKinds.contains($0.kind) }
        guard !visibleTracks.isEmpty else { return }
        let duration = max(0.001, timeline.duration)
        let scale = max(1, bounds.width - 40) / CGFloat(duration)
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(1)

        for (index, track) in visibleTracks.enumerated() {
            let y = CGFloat(index * 48) + 24
            UIColor.separator.setStroke()
            context?.move(to: CGPoint(x: 0, y: y + 16))
            context?.addLine(to: CGPoint(x: bounds.width, y: y + 16))
            context?.strokePath()

            let title = track.kind.rawValue
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor.secondaryLabel
            ]
            title.draw(at: CGPoint(x: 8, y: y - 18), withAttributes: attributes)

            for sample in track.samples {
                let x = xPosition(for: sample.timestamp, timeline: timeline, scale: scale)
                guard x >= 0, x <= bounds.width else { continue }
                let sampleRect = CGRect(x: x, y: y + 4, width: 2, height: 10)
                UIColor.systemBlue.setFill()
                context?.fill(sampleRect)
            }

            for event in track.events {
                guard query.isEmpty || event.name.lowercased().contains(query) || event.metadata.values.contains(where: { $0.lowercased().contains(query) }) else { continue }
                let x = xPosition(for: event.timestamp, timeline: timeline, scale: scale)
                guard x >= 0, x <= bounds.width else { continue }
                let eventRect = CGRect(x: x - 3, y: y - 2, width: 6, height: 6)
                UIColor.systemOrange.setFill()
                context?.fillEllipse(in: eventRect)
            }
        }

        if let selectedRange {
            let startX = xPosition(for: selectedRange.start, timeline: timeline, scale: scale)
            let endX = xPosition(for: selectedRange.end, timeline: timeline, scale: scale)
            UIColor.systemBlue.withAlphaComponent(0.12).setFill()
            context?.fill(CGRect(x: startX, y: 0, width: max(0, endX - startX), height: bounds.height))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, let timeline = snapshot?.timeline else { return }
        let point = touch.location(in: self)
        let duration = max(0.001, timeline.duration)
        let scale = max(1, bounds.width - 40) / CGFloat(duration)
        let date = timeline.startDate.addingTimeInterval(TimeInterval(max(0, point.x - 20) / scale))
        let candidates = timeline.events(in: DateInterval(start: date.addingTimeInterval(-0.08),
                                                           end: date.addingTimeInterval(0.08)),
                                          kinds: visibleKinds,
                                          query: query)
        if let event = candidates.first {
            onSelectEvent?(event)
        }
    }

    private func xPosition(for date: Date, timeline: PTInstrumentTimeline, scale: CGFloat) -> CGFloat {
        20 + CGFloat(date.timeIntervalSince(timeline.startDate)) * scale
    }
}

// English: The inspector presents only a value snapshot and its nearby cross-track correlation.
// Español: El inspector presenta solo un snapshot de valores y su correlación cercana entre pistas.
// 中文：事件检查器只展示值类型快照及其附近的跨轨道关联数据。
@MainActor
public final class PTInstrumentEventInspectorViewController: UIViewController {
    private let correlation: PTInstrumentCorrelation
    private let textView = UITextView()

    public init(correlation: PTInstrumentCorrelation) {
        self.correlation = correlation
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Event"
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.text = makeText()
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func makeText() -> String {
        let event = correlation.event
        let relatedEvents = correlation.relatedEvents.map { "\($0.timestamp): \($0.kind.rawValue) \($0.name)" }.joined(separator: "\n")
        let relatedSamples = correlation.relatedSamples.map { "\($0.timestamp): \($0.kind.rawValue) \($0.value) \($0.unit)" }.joined(separator: "\n")
        let duration = event.duration.map { String($0) } ?? "-"
        let metadata = event.metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        let lines: [String] = [
            "Name: \(event.name)",
            "Track: \(event.kind.rawValue)",
            "Timestamp: \(event.timestamp)",
            "Duration: \(duration)",
            "Metadata: \(metadata)",
            "",
            "Related events:",
            relatedEvents.isEmpty ? "-" : relatedEvents,
            "",
            "Related samples:",
            relatedSamples.isEmpty ? "-" : relatedSamples
        ]
        return lines.joined(separator: "\n")
    }
}

// English: Dashboard is a presentation adapter over an existing session and never starts collectors by itself.
// Español: El dashboard es un adaptador de presentación sobre una sesión existente y nunca inicia collectors por sí mismo.
// 中文：Dashboard 只是现有 Session 的展示适配器，不会自行启动 Collector。
@MainActor
public final class PTInstrumentDashboardViewController: UIViewController {
    private let session: PTInstrumentSession
    private let timelineView = PTInstrumentTimelineView()
    private let summaryLabel = UILabel()
    private var snapshot: PTInstrumentSessionSnapshot?

    public init(session: PTInstrumentSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "PTools Instruments"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(exportSession)),
            UIBarButtonItem(title: "Stop", style: .plain, target: self, action: #selector(stopRecording))
        ]
        setupViews()
        timelineView.onSelectEvent = { [weak self] event in
            guard let self, let snapshot = self.snapshot, let correlation = snapshot.timeline.correlation(for: event.id) else { return }
            self.navigationController?.pushViewController(PTInstrumentEventInspectorViewController(correlation: correlation), animated: true)
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let snapshot = await self.session.snapshot()
            self.snapshot = snapshot
            self.summaryLabel.text = Self.summaryText(snapshot.summary)
            self.timelineView.update(snapshot: snapshot)
        }
    }

    @objc private func stopRecording() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let snapshot = await PTInstrumentRecorder.shared.stop() else { return }
            self.snapshot = snapshot
            self.summaryLabel.text = Self.summaryText(snapshot.summary)
            self.timelineView.update(snapshot: snapshot)
        }
    }

    @objc private func exportSession() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let url = try await session.export()
                let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                // English: Configure the iPad popover to keep archive sharing safe on regular-width scenes.
                // Español: Configura el popover del iPad para mantener seguro el uso compartido en escenas anchas.
                // 中文：配置 iPad popover，保证常规宽度场景分享归档时不会触发系统异常。
                if let popover = share.popoverPresentationController {
                    popover.sourceView = view
                    popover.sourceRect = CGRect(x: view.bounds.midX,
                                                y: view.bounds.midY,
                                                width: 1,
                                                height: 1)
                }
                present(share, animated: true)
            } catch {
                let alert = UIAlertController(title: "Export failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func setupViews() {
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.numberOfLines = 0
        summaryLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        summaryLabel.textColor = .secondaryLabel
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryLabel)
        view.addSubview(timelineView)
        NSLayoutConstraint.activate([
            summaryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            summaryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            timelineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timelineView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 12),
            timelineView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private static func summaryText(_ summary: [String: Double]) -> String {
        let duration = summary["duration"] ?? 0
        let events = Int(summary["eventCount"] ?? 0)
        let samples = Int(summary["sampleCount"] ?? 0)
        let dropped = Int(summary["droppedCount"] ?? 0)
        return String(format: "Duration %.2fs  Events %d  Samples %d  Dropped %d", duration, events, samples, dropped)
    }
}
