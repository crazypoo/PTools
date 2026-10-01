// English: A lightweight timeline view keeps phase rendering on the UI boundary.
// Español: Una vista de línea temporal ligera mantiene el renderizado de fases en el límite de UI.
// 中文：轻量时间线视图把阶段渲染限制在 UI 边界内。

import UIKit

@MainActor
public final class PTNetworkTimelineView: UIView {

    private let phaseStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 4
        return stack
    }()

    private let insightLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(phaseStack)
        addSubview(insightLabel)
        phaseStack.translatesAutoresizingMaskIntoConstraints = false
        insightLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            phaseStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            phaseStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            phaseStack.topAnchor.constraint(equalTo: topAnchor),
            insightLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            insightLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            insightLabel.topAnchor.constraint(equalTo: phaseStack.bottomAnchor, constant: 4),
            insightLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func configure(metrics: PTNetworkTaskMetricsSnapshot?, responseBytes: Int64 = 0) {
        let timeline = PTNetworkTimeline(metrics: metrics, responseBytes: responseBytes)
        phaseStack.arrangedSubviews.forEach {
            phaseStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let durations = timeline.phases.compactMap { $0.duration }.map(Self.seconds)
        let maximum = max(durations.max() ?? 0, 0.001)
        for phase in timeline.phases {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 6

            let name = UILabel()
            name.text = phase.name
            name.font = .preferredFont(forTextStyle: .caption2)
            name.textColor = .secondaryLabel
            name.setContentHuggingPriority(.required, for: .horizontal)
            name.widthAnchor.constraint(equalToConstant: 52).isActive = true

            let progress = UIProgressView(progressViewStyle: .default)
            progress.progressTintColor = .tintColor
            progress.trackTintColor = .tertiarySystemFill
            progress.progress = Float(min(1, Self.seconds(phase.duration) / maximum))

            let duration = UILabel()
            duration.text = phase.duration.map { String(format: "%.1f ms", Self.seconds($0) * 1000) } ?? "—"
            duration.font = .preferredFont(forTextStyle: .caption2)
            duration.textColor = .secondaryLabel
            duration.textAlignment = .right
            duration.setContentHuggingPriority(.required, for: .horizontal)

            row.addArrangedSubview(name)
            row.addArrangedSubview(progress)
            row.addArrangedSubview(duration)
            phaseStack.addArrangedSubview(row)
        }

        let insights = timeline.insights.map { insight -> String in
            switch insight {
            case .slowDNS: return "Slow DNS"
            case .slowTLS: return "Slow TLS"
            case .slowTTFB: return "Slow TTFB"
            case .largeDownload: return "Large Download"
            case .redirectHeavy: return "Redirect-heavy"
            }
        }
        insightLabel.text = insights.isEmpty ? "No timing insight" : insights.joined(separator: " · ")
    }

    private static func seconds(_ duration: Duration?) -> Double {
        guard let duration else { return 0 }
        let components = duration.components
        return max(0, Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000)
    }
}
