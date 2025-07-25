//
//  View+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import SwiftUI

public extension View {
    func alert(isPresent:Binding<Bool>,view:PTAlertTipsProtocol,completion:PTActionTask? = nil) -> some View {
        if isPresent.wrappedValue {
            let wrapperCompletion:PTActionTask = {
                isPresent.wrappedValue = false
                completion?()
            }

            if let window = AppWindows {
                view.present(on: window, completion: wrapperCompletion)
            }
        }
        return self
    }
}
