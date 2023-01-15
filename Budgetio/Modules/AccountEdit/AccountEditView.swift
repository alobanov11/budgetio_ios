//
//  Created by Антон Лобанов on 18.11.2022.
//

import StoreSwift
import SwiftUI

struct AccountEditView: View {
    @StateObject var store: ViewStore<AccountEditModule>
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

                if store.state.isNewAccount == false {
                    Button(action: { store.dispatch(.didTapOnDelete) }) {
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
        .navigationTitle(store.state.isNewAccount ? "New account" : "Edit account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { store.dispatch(.didTapOnCancel) }) {
                    Text("Cancel")
                }
            }
            ToolbarItem {
                Button(action: { store.dispatch(.didTapOnDone) }) {
                    Text(store.state.isNewAccount ? "Add" : "Done")
                }
                .disabled(store.state.title.isEmpty)
            }
        }
        .onAppear {
            focused = true
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
                    TextField("", text: store.bind(\.title, by: .didEditTitle))
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
                    TextField("", text: store.bind(\.value, by: .didEditValue))
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
                    TextField("", text: store.bind(\.proportion, by: .didEditProportion))
                        .keyboardType(.numberPad)
                        .font(.system(.body, design: .monospaced))
                        .offset(x: 12)
                }
        }
    }
}

struct AccountEditPreview: PreviewProvider {
    static var store: ViewStore<AccountEditModule> {
        .init(initialState: .init(
            title: "",
            proportion: "",
            value: "",
            isNewAccount: true
        ))
    }

    static var previews: some View {
        NavigationView {
            AccountEditView(store: store)
        }
    }
}
