//
//  Created by Антон Лобанов on 02.05.2023.
//

import XCTest
@testable import Budgetio

final class BudgetioTests: XCTestCase {

    func testViewAppear() async {
        // arrange
        let middleware = AccountListFeature.middleware
        let state = AccountListFeature.State()
        let accounts: [AccountEntity] = [
            .init(id: nil, title: "Some title", value: 0, proportion: 0, records: []),
        ]
        var env = AccountListFeature.Enviroment(
            fetchAccounts: { accounts },
            sendAnalytics: { _ in },
            router: .init(onCreateAccount: {}, onEditAccount: { _ in })
        )
        // act
        let effectTask = middleware(state, &env, .action(.viewAppear))
        let events = await effectTask.unwrap(&env)
        // assert
        XCTAssertEqual(events, [
            .effect(.setLoading(true)),
            .effect(.setAccounts(accounts)),
            .effect(.setLoading(false)),
        ])
        XCTAssertEqual(env.accounts, accounts)
    }

    func testDidTapOnAccount() async {
        // arrange
        let middleware = AccountListFeature.middleware
        let accountEntity = AccountEntity(id: nil, title: "Some title", value: 0, proportion: 0, records: [])
        let account = AccountListFeature.mapAccount(with: accountEntity, total: 0)
        let state = AccountListFeature.State(data: [account])
        var analyticsEvent: [AnalyticsEvent] = []
        var accountToEdit: AccountEntity?
        var env = AccountListFeature.Enviroment(
            accounts: [accountEntity],
            fetchAccounts: { [] },
            sendAnalytics: { analyticsEvent.append($0) },
            router: .init(onCreateAccount: {}, onEditAccount: { accountToEdit = $0 })
        )
        // act
        let effectTask = middleware(state, &env, .action(.didTapOnAccount(account)))
        _ = await effectTask.unwrap(&env)
        // assert
        XCTAssertEqual(accountEntity, accountToEdit)
        XCTAssertEqual(analyticsEvent, [
            .tapOnAccount(accountEntity.title, position: 0),
        ])
    }

}
