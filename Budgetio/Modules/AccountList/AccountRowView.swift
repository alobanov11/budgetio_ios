//
//  Created by Антон Лобанов on 24.02.2023.
//

import SwiftUI

struct AccountRowView: View {
	let account: AccountListModule.State.Account

	var body: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading, spacing: 6) {
				Text(account.title)
					.font(.system(size: 16, weight: .bold, design: .monospaced))

				Text(account.originalProportion ?? "")
					.foregroundColor(.gray)
					.font(.system(size: 12, weight: .regular, design: .monospaced))
					.hidden(account.originalProportion == nil)
			}

			Spacer()

			VStack(alignment: .trailing, spacing: 6) {
				Text(account.value)
					.font(.system(size: 16, weight: .bold, design: .monospaced))

				HStack {
					Text(account.diff ?? "")
						.foregroundColor(account.isPositive ? .green : .red)
						.font(.system(size: 12, weight: .regular, design: .monospaced))
						.hidden(account.diff == nil)

					Text("•")
						.foregroundColor(.gray)
						.hidden(account.diff == nil)

					Text(account.proportion)
						.foregroundColor(.gray)
						.font(.system(size: 12, weight: .regular, design: .monospaced))
				}
			}
		}
		.padding(.vertical, 12)
		.padding(.horizontal)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color.white.opacity(0.5))
		)
	}
}

struct AccountRowPreview: PreviewProvider {
	static var previews: some View {
		ZStack {
			AccountRowView(account: .init(
				id: .init(),
				title: "Account #1",
				proportion: "12%",
				originalProportion: "5%",
				value: "2000 RUB",
				diff: "150 RUB",
				isPositive: false
			))
		}
	}
}
