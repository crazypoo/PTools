//
// English: Direct nested-model regression coverage for the Foundation-only PTModel path.
// Español: Cobertura de regresión para modelos anidados directos en la ruta PTModel basada en Foundation.
// 中文：覆盖 Foundation-only PTModel 直接嵌套模型的回归测试。
//

import Foundation
import XCTest
@testable import PToolsModelCore
import PToolsModel

#if SWIFT_PACKAGE
@PTModel
private struct PTNestedAddressFixture: Codable, Sendable, Equatable {
    let city: String
    let zipCode: String
}

@PTModel
private struct PTNestedUserFixture: Codable, Sendable, Equatable {
    let id: Int
    let name: String
    let address: PTNestedAddressFixture
}

@PTModel
private struct PTNestedOrderFixture: Codable, Sendable, Equatable {
    let orderID: String
    let user: PTNestedUserFixture
    let items: [PTNestedUserFixture]
}

@PTModel
private struct PTNestedOptionalFixture: Codable, Sendable, Equatable {
    let user: PTNestedUserFixture?
    let users: [PTNestedUserFixture]
    let lookup: [String: PTNestedUserFixture]
}

@PTModel
private struct PTNestedStringifiedFixture: Codable, Sendable, Equatable {
    @PTStringified
    let user: PTNestedUserFixture?
}

// English: Decode the wrapper so the regression exercises a nested object at its real parent path.
// Español: Decodifica el wrapper para que la regresión ejercite el objeto anidado en su ruta padre real.
// 中文：通过包装模型解码真实父路径下的嵌套对象，避免测试错误地直接解码根节点。
@PTModel
private struct PTNestedObjectWrapperFixture: Codable, Sendable, Equatable {
    let user: PTNestedUserFixture
}
#endif

final class PTModelNestedModelTests: XCTestCase {
#if SWIFT_PACKAGE
    func testDirectNestedObjectDecodesRecursively() throws {
        let data = Data("""
        {
            "orderID":"A001",
            "user":{"id":1,"name":"Jax","address":{"city":"Shanghai","zipCode":"200000"}},
            "items":[{"id":2,"name":"Passenger","address":{"city":"Beijing","zipCode":"100000"}}]
        }
        """.utf8)

        let order = try PTModelDecoder(policy: .compatible).decode(PTNestedOrderFixture.self, from: data)

        XCTAssertEqual(order.orderID, "A001")
        XCTAssertEqual(order.user.address.city, "Shanghai")
        XCTAssertEqual(order.items.first?.address.zipCode, "100000")
    }

    func testOptionalArrayAndDictionaryNestedModelsDecode() throws {
        let data = Data("""
        {
            "user":null,
            "users":[{"id":1,"name":"A","address":{"city":"Shanghai","zipCode":"200000"}}],
            "lookup":{"owner":{"id":2,"name":"B","address":{"city":"Beijing","zipCode":"100000"}}}
        }
        """.utf8)

        let value = try PTModelDecoder(policy: .compatible).decode(PTNestedOptionalFixture.self, from: data)

        XCTAssertNil(value.user)
        XCTAssertEqual(value.users.count, 1)
        XCTAssertEqual(value.lookup["owner"]?.name, "B")
    }

    func testStringifiedModelRemainsExplicit() throws {
        let nestedJSON = #"{"id":3,"name":"Stringified","address":{"city":"Shenzhen","zipCode":"518000"}}"#
        let data = try JSONSerialization.data(withJSONObject: ["user": nestedJSON])

        let value = try PTModelDecoder(policy: .compatible).decode(PTNestedStringifiedFixture.self, from: data)

        XCTAssertEqual(value.user?.name, "Stringified")
        XCTAssertEqual(value.user?.address.city, "Shenzhen")
    }

    func testNestedObjectIsNotTreatedAsStringifiedInput() throws {
        let data = Data(#"{"user":{"id":4,"name":"Object","address":{"city":"Guangzhou","zipCode":"510000"}}}"#.utf8)

        let wrapper = try PTModelDecoder(policy: .compatible)
            .decode(PTNestedObjectWrapperFixture.self, from: data)

        XCTAssertEqual(wrapper.user.name, "Object")
        XCTAssertEqual(wrapper.user.address.city, "Guangzhou")
        XCTAssertEqual(wrapper.user.address.zipCode, "510000")
    }
#endif
}
