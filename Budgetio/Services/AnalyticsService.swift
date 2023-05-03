//
//  Created by Антон Лобанов on 02.05.2023.
//

import Foundation

protocol IAnalyticsEvent {

    var name: String { get }
    var parameters: [String: Encodable?] { get }
}

protocol IAnalyticsService: AnyObject {

    func send(_ event: IAnalyticsEvent)
}

final class AnalyticsService: IAnalyticsService {

    func send(_ event: IAnalyticsEvent) {}
}


enum AnalyticsEvent: Equatable {

    case tapOnAccount(String, position: Int)
}

extension AnalyticsEvent: IAnalyticsEvent {

    var name: String {
        switch self {
        case .tapOnAccount: return "Tap on account"
        }
    }

    var parameters: [String : Encodable?] {
        switch self {
        case let .tapOnAccount(title, position):
            return ["title": title, "position": position]
        }
    }
}
