//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SafeSFSymbols

extension Manager: KeyCommandPresentable {
    var keyCommands: [UIKeyCommand] {
        if let cachedKeyCommands = keyCommandsStore.wrappedValue {
            return cachedKeyCommands
        }
        let keyCommands = [presentInspectorKeyCommand] + makeKeyCommands(withSelector: keyCommandAction)
        keyCommandsStore.wrappedValue = keyCommands
        return keyCommands
    }

    var commandGroups: CommandsGroups {
        makeCommandGroups(limit: .none)
    }

    var keyCommandAction: Selector {
        #selector(UIViewController.inspectorKeyCommandHandler(_:))
    }

    private var slowAnimationsCommand: Command {
        let totalSpeed = snapshot
            .root
            .windows
            .map(\.layer.speed)
            .reduce(into: 0.0) { partialResult, speed in
                partialResult += speed
            }
        let isSlowingAnimations = totalSpeed < Float(snapshot.root.windows.count)

        return Command(
            title: "Slow Animations",
            icon: .init(.tortoise.fill, weight: .regular),
            isSelected: isSlowingAnimations
        ) { [weak self] in
            guard let self = self else { return }
            self.snapshot
                .root
                .windows
                .forEach { $0.layer.speed = isSlowingAnimations ? 1 : 1 / 5 }
        }
    }

    private func makeKeyCommands(withSelector aSelector: Selector) -> [UIKeyCommand] {
        let layerToggleInputRange = Inspector.sharedInstance.configuration.keyCommands.layerToggleInputRange
        let limit = layerToggleInputRange.upperBound - layerToggleInputRange.lowerBound
        let commandGroups = makeCommandGroups(limit: limit)

        return commandGroups
            .flatMap(\.commands)
            .compactMap { command in
                guard let keyInput = command.keyInput else { return nil }
                return .init(
                    title: command.title,
                    action: aSelector,
                    input: keyInput,
                    modifierFlags: command.modifierFlags,
                    discoverabilityTitle: command.title,
                    attributes: command.isEnabled ? .init() : .disabled,
                    state: command.isSelected ? .on : .off
                )
            }
        // .sortedByInputKey()
    }

    private var defaultActions: CommandsGroup {
        .group(
            commands: {
                var array = [Command]()
                array.append(slowAnimationsCommand)
                if let toggleInterfaceStyle = toggleInterfaceStyleCommand {
                    array.append(toggleInterfaceStyle)
                }
                return array
            }()
        )
    }

    private func makeCommandGroups(limit: Int?) -> CommandsGroups {
        var commandGroups: CommandsGroups = []
        if let userCommandGroups = dependencies.customization?.commandGroups {
            commandGroups.append(contentsOf: userCommandGroups)
            commandGroups.append(defaultActions)
        }
        else {
            commandGroups.append(defaultActions)
        }

        commandGroups.append(contentsOf: insectViewHierarchy)

        commandGroups.append(contentsOf: viewHierarchyCoordinator.commandsGroups(limit: limit))

        return commandGroups
    }

    private var presentInspectorKeyCommand: UIKeyCommand {
        let settings = Inspector.sharedInstance.configuration.keyCommands.presentationSettings
        return .init(
            title: Texts.presentInspector,
            action: #selector(UIViewController.presentationKeyCommandHandler(_:)),
            input: settings.input,
            modifierFlags: settings.modifierFlags
        )
    }

    private var hideSystemWindows: Command {
        Command(
            title: "Show System Windows",
            icon: .init(.macwindow.onRectangle),
            isSelected: dependencies.configuration.showFullApplicationHierarchy,
            closure: {
                Inspector.sharedInstance.configuration.showFullApplicationHierarchy.toggle()

                if Inspector.sharedInstance.configuration.showFullApplicationHierarchy {
                    Task {
                        await Inspector.present()
                    }
                }
            }
        )
    }

    private var insectViewHierarchy: CommandsGroups {
        guard let keyWindow = keyWindow else { return [] }

        let showFullApplicationHierarchy = dependencies.configuration.showFullApplicationHierarchy

        let root = snapshot.root

        let allWindows = root
            .children
            .filter { $0.underlyingView is UIWindow }

        let windows = allWindows.filter {
            showFullApplicationHierarchy || ($0.underlyingView as? UIWindow)?.isKeyWindow == true
        }

        var commands = windows.map { inspectCommands(window: $0, from: keyWindow) }

        if allWindows.count > windows.count {
            commands.append(
                .group(with: hideSystemWindows)
            )
        }

        return commands
    }

    private func inspectCommands(window element: ViewHierarchyElementReference, from presenter: UIView) -> CommandsGroup {
        .group(
            title: "\(element.displayName) Hierarchy",
            commands: {
                var commands = [Command]()
                commands.append(
                    .inspectElement(element) { [weak self] in
                        guard let self = self else { return }
                        self.perform(
                            action: .inspect(preferredPanel: .default),
                            with: element,
                            from: presenter
                        )
                    }
                )

                commands.append(
                    contentsOf: forEach(
                        viewController: snapshot.root.viewHierarchy.filter { $0.underlyingView?.window === element.underlyingView },
                        .inspect(preferredPanel: .default),
                        from: presenter
                    )
                )

                return commands
            }()
        )
    }

    private var toggleInterfaceStyleCommand: Command? {
        guard
            let keyWindow = keyWindow,
            snapshot.root.bundleInfo?.interfaceStyle == nil
        else {
            return .none
        }

        let keyInput = "i"
        let modifierFlags: UIKeyModifierFlags = [.control, .shift]

        let closure: () -> Void = {
            keyWindow.overrideUserInterfaceStyle = {
                switch keyWindow.traitCollection.userInterfaceStyle {
                case .dark: return .light
                case .light: return .dark
                default: return .unspecified
                }
            }()
        }

        guard keyWindow.traitCollection.userInterfaceStyle == .light else {
            return .init(
                title: "Light Mode",
                icon: .init(.sun.max),
                keyInput: keyInput,
                modifierFlags: modifierFlags,
                closure: closure
            )
        }
        return .init(
            title: "Dark Mode",
            icon: .init(.moon.starsFill),
            keyInput: keyInput,
            modifierFlags: modifierFlags,
            closure: closure
        )
    }

    private func forEach(
        viewController viewHierarchy: [ViewHierarchyElementReference],
        _ action: ViewHierarchyElementAction,
        from sourceView: UIView
    ) -> [Command] {
        viewHierarchy
            .compactMap { $0 as? ViewHierarchyElementController }
            .sorted { $0.depth < $1.depth }
            .map { viewController in
                .inspectElement(viewController) { [weak self] in
                    guard let self = self else { return }
                    self.perform(action: action, with: viewController, from: sourceView)
                }
            }
    }
}
