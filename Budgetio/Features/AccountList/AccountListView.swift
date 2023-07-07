import SwiftUI
import ComposableArchitecture

struct AccountListView: View {
    let store: StoreOf<AccountList>

    var body: some View {
        WithViewStore(store.scope(state: \.view, action: { .view($0) })) { viewStore in
            ZStack {
                if viewStore.items.isEmpty {
                    VStack(spacing: 16) {
                        Text("Add you first account")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button("Create", action: { viewStore.send(.addButtonTapped) })
                            .buttonBorderShape(.capsule)
                            .buttonStyle(.borderedProminent)
                    }
                }
                else {
                    List {
                        ForEach(viewStore.items, id: \.self) { item in
                            HStack {
                                Text(item.title)
                                    .font(.body)

                                Spacer()

                                Text(item.value)
                                    .font(.body)
                            }
                            .onTapGesture {
                                viewStore.send(.itemTapped(item))
                            }
                        }
                    }
                }

                if let error = viewStore.error {
                    Text(error)
                        .foregroundColor(.red)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewStore.send(.errorDisplayed)
                            }
                        }
                }

                if viewStore.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewStore.items.isEmpty {
                        Button(action: { viewStore.send(.addButtonTapped) }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle(viewStore.total)
            .onAppear {
                viewStore.send(.viewAppeared)
            }
        }
    }
}

struct AccountListPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountListView(store: Store(
                initialState: AccountList.State(),
                reducer: EmptyReducer()
            ))
        }
    }
}
