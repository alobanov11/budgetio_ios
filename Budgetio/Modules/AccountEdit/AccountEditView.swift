//
//  Created by Антон Лобанов on 18.11.2022.
//

import StoreSwift
import SwiftUI

struct AccountEditView: View {
    @StateObject var store: Store<AccountEditFeature>
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                titleFieldView

                Divider()

                HStack(spacing: 24) {
                    valueFieldView

                    proportionFieldView
                }

                if store.isNewAccount == false {
                    Button(action: store.action(.didTapOnDelete)) {
                        Label("Delete Account", systemImage: "trash.fill")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 24)
                }
            }
            .padding()
            .padding(.vertical)
        }
        .navigationTitle(store.isNewAccount ? "New account" : "Edit account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: store.action(.didTapOnCancel)) {
                    Text("Cancel")
                }
            }
            ToolbarItem {
                Button(action: store.action(.didTapOnDone)) {
                    Text(store.isNewAccount ? "Add" : "Done")
                }
                .disabled(store.title.isEmpty)
            }
        }
        .onAppear {
            focused = true
            store.send(.viewAppear)
        }
    }
}

private extension AccountEditView {
    var titleFieldView: some View {
        VStack(alignment: .leading) {
            Text("Name")
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.bold)

            RoundedRectangle(cornerRadius: 12)
                .stroke(lineWidth: 2)
                .frame(height: 48)
                .overlay {
                    TextField("", text: store.binding(\.title, by: .didEditTitle))
                        .font(.system(.body, design: .monospaced))
                        .offset(x: 12)
                }
        }
    }

    var valueFieldView: some View {
        VStack(alignment: .leading) {
            Text("Value")
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.bold)

            RoundedRectangle(cornerRadius: 12)
                .stroke(lineWidth: 2)
                .frame(height: 48)
                .overlay {
                    TextField("", text: store.binding(\.value, by: .didEditValue))
                        .keyboardType(.numberPad)
                        .font(.system(.body, design: .monospaced))
                        .focused($focused)
                        .offset(x: 12)
                }
        }
    }

    var proportionFieldView: some View {
        VStack(alignment: .leading) {
            Text("Proportion")
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.bold)

            RoundedRectangle(cornerRadius: 12)
                .stroke(lineWidth: 2)
                .frame(height: 48)
                .overlay {
                    TextField("", text: store.binding(\.proportion, by: .didEditProportion))
                        .keyboardType(.numberPad)
                        .font(.system(.body, design: .monospaced))
                        .offset(x: 12)
                }
        }
    }
}

struct AccountEditPreview: PreviewProvider {
    static var state: AccountEditFeature.State {
        AccountEditFeature.State(
            title: "",
            proportion: "",
            value: "",
            isNewAccount: true
        )
    }

    static var store: Store<AccountEditFeature> {
        Store<AccountEditFeature>(
            initialState: state,
            enviroment: .init(
                saveAccount: { _ in .init() },
                deleteAccount: { _ in },
                contentType: .new,
                router: .init(onDismiss: {})
            ),
            middleware: { _, _, _ in .none },
            reducer: { _, _ in }
        )
    }

    static var previews: some View {
        NavigationView {
            AccountEditView(store: store)
        }
    }
}
