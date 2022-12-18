//
//  Created by Антон Лобанов on 21.11.2022.
//

import Foundation

func onMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    }
    else {
        DispatchQueue.main.async(execute: block)
    }
}

func onMainThreadAsync(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}

func onMainThreadAsync(_ delay: TimeInterval, _ block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
}

func onBackgroundThread(_ block: @escaping () -> Void) {
    onBackgroundThread(qos: .default)(block)
}

func onBackgroundThread(qos: DispatchQoS.QoSClass) -> (@escaping () -> Void) -> Void {
    {
        DispatchQueue.global(qos: qos).async(execute: $0)
    }
}
