//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

typealias CommandsGroups = [Inspector.CommandsGroup]
typealias CommandsGroup = Inspector.CommandsGroup

public extension Inspector {
    /// A group of commands.
    struct CommandsGroup {
        public var title: String?
        public var commands: [Command]

        private init(title: String?, commands: [Command]) {
            self.title = title
            self.commands = commands
        }

        public static func group(title: String? = nil, commands: [Command]) -> CommandsGroup {
            CommandsGroup(title: title, commands: commands)
        }

        public static func group(with command: Command) -> CommandsGroup {
            CommandsGroup(title: nil, commands: [command])
        }
    }
}
