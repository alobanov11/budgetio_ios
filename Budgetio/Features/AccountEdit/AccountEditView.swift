import SwiftUI
import ComposableArchitecture

struct AccountEditView: View {
    let store: StoreOf<AccountEdit>

    var body: some View {
        WithViewStore(store, observe: \.view, send: { .view($0) }) { viewStore in
            Form {
                Section("Title") {
                    TextField("e.g. JP bank", text: viewStore.$title)
                        .autocorrectionDisabled()
                        .font(.body)
                }

                Section("Value") {
                    TextField("e.g. 1000", text: viewStore.$value)
                        .keyboardType(.numberPad)
                        .font(.body)
                }

                Section {
                    Button(action: { viewStore.send(.saveTapped) }) {
                        Text(viewStore.isNew ? "Create" : "Save")
                            .font(.body)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .tint(Color.blue)
                }
            }
            .onAppear {
                viewStore.send(.viewAppeared)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewStore.isNew {
                        Button(role: .destructive, action: { viewStore.send(.deleteTapped) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle((viewStore.isNew ? "Create " : "Edit ") + "account")
        }
    }
}

struct AccountEditPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountEditView(store: Store(
                initialState: AccountEdit.State(
                    account: nil
                ),
                reducer: AccountEdit()
            ))
        }
    }
}
