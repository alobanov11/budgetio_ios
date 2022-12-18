//
//  Created by Антон Лобанов on 18.12.2022.
//

import SwiftUI

extension View {
    @ViewBuilder
    func hidden(_ hidden: Bool) -> some View {
        if hidden == false {
            self
        }
    }
}
