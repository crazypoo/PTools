//
//  PTModelNetworkDemoViewController.swift
//
// English: A deterministic Learning Lab for PTModel and typed Network response paths.
// Español: Un Learning Lab determinista para PTModel y las rutas de respuesta Network tipadas.
// 中文：用于演示 PTModel 和类型化 Network 响应路径的确定性 Learning Lab。
//

import Foundation
import UIKit
import PooTools

// English: Keep the Example screen on the same list infrastructure used by production clients.
// Español: Mantiene la pantalla Example sobre la misma infraestructura de listas que usan los clientes reales.
// 中文：让 Example 页面复用真实业务使用的列表基础设施。
@MainActor
final class PTModelNetworkDemoViewController: PTListViewController {
    fileprivate struct Profile: Codable, Sendable, Equatable {
        let nickname: String
    }

    fileprivate struct User: Codable, Sendable, Equatable {
        let id: Int
        let name: String
        let profile: Profile
    }

    private struct OwnerEnvelope: Codable, Sendable, Equatable {
        let owner: User
    }

    private struct DemoItem {
        let id: String
        let title: String
        let detail: String
    }

    private typealias DemoAction = @MainActor () -> Void

    private var actions: [String: DemoAction] = [:]
    private var outputText = "选择一个操作查看确定性结果。\n\nNetwork 不会自动猜测 data/result/payload；请显式传入 modelPath。"

    override func viewDidLoad() {
        pt_Title = "PTModel + Network Learning Lab"
        view.backgroundColor = .systemBackground
        super.viewDidLoad()
        reloadLearningSections()
    }

    override func makeListViewConfiguration() -> PTCollectionViewConfig {
        let configuration = PTCollectionViewConfig()
        configuration.viewType = .Normal
        configuration.itemHeight = 78
        configuration.contentTopSpace = 12
        configuration.contentBottomSpace = 24
        configuration.cellLeadingSpace = 12
        configuration.cellTrailingSpace = 8
        configuration.showEmptyAlert = false
        return configuration
    }

    override func configureListView(_ listView: PTCollectionView) {
        listView.registerClassCells(classs: [PTFusionCell.ID: PTFusionCell.self])
        listView.collectionDidSelect = { [weak self] _, section, indexPath in
            guard let self,
                  let rows = section.rows,
                  rows.indices.contains(indexPath.item) else { return }
            let row = rows[indexPath.item]
            self.actions[row.diffId]?()
        }
    }

    // English: Rebuild only the deterministic snapshot; the list facade keeps registration and delegate ownership stable.
    // Español: Reconstruye solo el snapshot determinista; la fachada conserva estables el registro y el delegate.
    // 中文：只重建确定性 snapshot，列表门面继续持有注册信息和代理关系。
    private func reloadLearningSections() {
        let items: [(String, [DemoItem])] = [
            ("1. Basic PTModel", [DemoItem(id: "basic", title: "Basic Model", detail: "Decode · Encode · JSON string · Dictionary")]),
            ("2. Nested Model", [DemoItem(id: "nested", title: "Nested Object", detail: "普通 JSON Object 不需要 @PTStringified")]),
            ("3. Nested Collections", [DemoItem(id: "collections", title: "Array / Dictionary", detail: "[User] 与 [String: User]")]),
            ("4. PTKey / PTPath", [DemoItem(id: "path", title: "Key and Path", detail: "把外部 key 与深层路径映射到模型")]),
            ("5. PTDefault / PTLossy", [DemoItem(id: "fallback", title: "Defaults and Lossy", detail: "缺省值与集合容错策略")]),
            ("6. PTStringified", [DemoItem(id: "stringified", title: "Object vs JSON String", detail: "同屏对比普通 Object 与字符串化 JSON")]),
            ("7. Network Root", [DemoItem(id: "network-root", title: "Root Response", detail: "PTNetworkResponseDecoder.ptModel(User.self)")]),
            ("8. Network $.data", [DemoItem(id: "network-data", title: "Envelope Response", detail: "显式 modelPath = $.data")]),
            ("9. Array Path", [DemoItem(id: "network-list", title: "List Response", detail: "modelType = [User].self · $.data.list")]),
            ("10. Diagnostics", [DemoItem(id: "diagnostics", title: "Decode Diagnostics", detail: "展示 $.data 与字段级错误路径")]),
            ("11. Model → JSON", [DemoItem(id: "encode", title: "Encoding", detail: "jsonData · jsonString · dictionary")]),
            ("12. Font Catalog", [DemoItem(id: "font-catalog", title: "Generated Catalog", detail: "PTFontCatalog · family lookup · PostScript lookup")]),
            ("13. Runtime Fonts", [DemoItem(id: "font-runtime", title: "Simulator Runtime", detail: "当前 Runtime 的真实字体与 Catalog 差异")]),
            ("14. Legacy FontName", [DemoItem(id: "font-legacy", title: "Compatibility Forwarding", detail: "5.x FontName 继续可用，底层转发到 PTFont")])
        ]

        actions.removeAll(keepingCapacity: true)
        var sections: [PTSection] = []
        let outputModel = makeCellModel(id: "output", title: "Result", detail: outputText, isOutput: true)
        let outputRow = PTRows(model: outputModel, reuseID: PTFusionCell.ID, title: outputModel.name)
        sections.append(PTSection(identifier: "network.ptmodel-lab.output",
                                  headerTitle: "Result",
                                  headerHeight: CGFloat.leastNormalMagnitude,
                                  rows: [outputRow]))

        for (sectionIndex, entry) in items.enumerated() {
            let rows = entry.1.map { item in
                let model = makeCellModel(id: item.id, title: item.title, detail: item.detail)
                actions[model.diffId] = { [weak self] in self?.runDemo(id: item.id) }
                return PTRows(model: model, reuseID: PTFusionCell.ID, title: model.name)
            }
            sections.append(PTSection(identifier: "network.ptmodel-lab.section.\(sectionIndex)",
                                      headerTitle: entry.0,
                                      headerHeight: CGFloat.leastNormalMagnitude,
                                      rows: rows))
        }
        listView.showCollectionDetail(collectionData: sections, animated: false)
    }

    private func makeCellModel(id: String, title: String, detail: String, isOutput: Bool = false) -> PTFusionCellModel {
        let model = PTFusionCellModel(diffIdentifier: "network.ptmodel-lab.\(id)")
        model.cellID = PTFusionCell.ID
        model.cellClass = PTFusionCell.self
        model.name = title
        model.content = detail
        model.contentNumberOfLines = isOutput ? 0 : 2
        model.contentLineBreakMode = .byWordWrapping
        model.rightSpace = 12
        model.leftSpace = 12
        model.contentRightSpace = 12
        return model
    }

    private func publish(_ text: String) {
        outputText = text
        reloadLearningSections()
    }

    private func runDemo(id: String) {
        switch id {
        case "basic": runBasicModel()
        case "nested": runNestedObject()
        case "collections": runNestedCollections()
        case "path": runKeyAndPath()
        case "fallback": runDefaultsAndLossy()
        case "stringified": runStringifiedComparison()
        case "network-root": runNetworkRoot()
        case "network-data": runNetworkData()
        case "network-list": runNetworkList()
        case "diagnostics": runDiagnostics()
        case "encode": runEncoding()
        case "font-catalog": runFontCatalog()
        case "font-runtime": runFontRuntime()
        case "font-legacy": runLegacyFontName()
        default: break
        }
    }

    private func runBasicModel() {
        let data = Data(#"{"id":1,"name":"Jax","profile":{"nickname":"Basic"}}"#.utf8)
        do {
            let user = try PTModelDecoder(policy: .compatible).decode(User.self, from: data)
            let dictionary = try PTModelEncoder().dictionary(user)
            publish("Basic PTModel\nid = \(user.id)\nname = \(user.name)\nDictionary keys = \(dictionary.keys.sorted())")
        } catch { publish("Basic decode failed: \(error.localizedDescription)") }
    }

    private func runNestedObject() {
        let data = Data(#"{"id":1,"name":"Jax","profile":{"nickname":"Nested"}}"#.utf8)
        do {
            let user = try PTModelDecoder(policy: .compatible).decode(User.self, from: data)
            publish("Nested Object\nuser.profile.nickname = \(user.profile.nickname)\n\n普通 Object 不需要 @PTStringified。")
        } catch { publish("Nested decode failed: \(error.localizedDescription)") }
    }

    private func runNestedCollections() {
        let data = Data(#"{"users":[{"id":1,"name":"A","profile":{"nickname":"A"}}],"owners":{"main":{"id":2,"name":"B","profile":{"nickname":"B"}}}}"#.utf8)
        do {
            let value = try PTModelDecoder(policy: .compatible).decode(CollectionFixture.self, from: data)
            publish("Nested Collections\nusers = \(value.users.count)\nowners.main = \(value.owners["main"]?.name ?? "nil")")
        } catch { publish("Collection decode failed: \(error.localizedDescription)") }
    }

    private func runKeyAndPath() {
        let data = Data(#"{"payload":{"owner":{"id":7,"name":"Path","profile":{"nickname":"Deep"}}}}"#.utf8)
        do {
            let payload = PTNetworkResponsePayload(data: data)
            let value = try PTNetworkResponseDecoder<OwnerEnvelope>
                .ptModel(OwnerEnvelope.self, at: "$.payload")
                .decode(payload)
            publish("PTPath\n$.payload.owner.name = \(value.owner.name)\nkey mapping remains explicit at the model boundary.")
        } catch { publish("Path decode failed: \(error.localizedDescription)") }
    }

    private func runDefaultsAndLossy() {
        publish("PTDefault / PTLossy\n缺省值和集合容错应写在模型契约中；不要在 Network 层猜测字段。\n请查看 Quick Start 中的类型化示例。")
    }

    private func runStringifiedComparison() {
        let objectData = Data(#"{"id":3,"name":"Object","profile":{"nickname":"Nested"}}"#.utf8)
        let stringifiedData = Data(#"{"id":4,"name":"String","profile":"{\"nickname\":\"Stringified\"}"}"#.utf8)
        do {
            let object = try PTModelDecoder(policy: .compatible).decode(User.self, from: objectData)
            let string = try PTModelDecoder(policy: .compatible).decode(StringifiedFixture.self, from: stringifiedData)
            publish("PTStringified\nObject → \(object.profile.nickname)\nJSON String → \(string.profile.value.nickname)")
        } catch { publish("Stringified comparison failed: \(error.localizedDescription)") }
    }

    private func runNetworkRoot() {
        let payload = PTNetworkResponsePayload(data: Data(#"{"id":5,"name":"Root","profile":{"nickname":"Network"}}"#.utf8))
        do {
            let user = try PTNetworkResponseDecoder<User>.ptModel(User.self).decode(payload)
            publish("Network Root\nmodelType = User.self\nuser.name = \(user.name)")
        } catch { publish("Root response failed: \(error.localizedDescription)") }
    }

    private func runNetworkData() {
        let payload = PTNetworkResponsePayload(data: Data(#"{"code":200,"data":{"id":6,"name":"Data","profile":{"nickname":"Envelope"}}}"#.utf8))
        do {
            let user = try PTNetworkResponseDecoder<User>.ptModel(User.self, at: "$.data").decode(payload)
            publish("Network $.data\nmodelPath = $.data\nuser.name = \(user.name)")
        } catch { publish("$.data response failed: \(error.localizedDescription)") }
    }

    private func runNetworkList() {
        let payload = PTNetworkResponsePayload(data: Data(#"{"data":{"list":[{"id":8,"name":"List","profile":{"nickname":"Array"}}]}}"#.utf8))
        do {
            let users = try PTNetworkResponseDecoder<[User]>.ptModel([User].self, at: "$.data.list").decode(payload)
            publish("Array Path\nmodelType = [User].self\nmodelPath = $.data.list\ncount = \(users.count)")
        } catch { publish("List response failed: \(error.localizedDescription)") }
    }

    private func runDiagnostics() {
        let payload = PTNetworkResponsePayload(data: Data(#"{"data":{"id":"not-an-int","name":"Broken","profile":{"nickname":"Diagnostics"}}}"#.utf8))
        do {
            _ = try PTNetworkResponseDecoder<User>.ptModel(User.self, at: "$.data").decode(payload)
            publish("Diagnostics unexpectedly succeeded")
        } catch {
            publish("Decode Diagnostics\nmodelPath = $.data\nfield = $.data.id\nerror = \(error.localizedDescription)")
        }
    }

    private func runEncoding() {
        let user = User(id: 9, name: "Encoded", profile: Profile(nickname: "JSON"))
        do {
            let encoder = PTModelEncoder(prettyPrinted: true)
            let data = try encoder.encode(user)
            let dictionary = try encoder.dictionary(user)
            let jsonString = try encoder.jsonString(user)
            publish("Model → JSON\njsonData bytes = \(data.count)\ndictionary keys = \(dictionary.keys.sorted())\n\(jsonString)")
        } catch { publish("Encode failed: \(error.localizedDescription)") }
    }

    private func runFontCatalog() {
        let font = PTFontCatalog.font(named: PTFont.pingFangSCRegular.postScriptName)
        let familyCount = PTFontCatalog.fonts(family: PTFont.pingFangSCRegular.familyName).count
        publish("Font Catalog\ncount = \(PTFontCatalog.allFonts.count)\nlookup = \(font?.postScriptName ?? "nil")\nfamily count = \(familyCount)")
    }

    private func runFontRuntime() {
        let catalogNames = Set(PTFontCatalog.allFonts.map(\.postScriptName))
        let installed = PTFontRuntime.installedFonts
        let installedNames = Set(installed.map(\.postScriptName))
        let added = installedNames.subtracting(catalogNames).sorted()
        let missing = catalogNames.subtracting(installedNames).sorted()
        publish("Runtime Fonts\ninstalled = \(installed.count)\ncatalog-only = \(missing.count)\nruntime-only = \(added.count)\nRuntime 缺失不代表 Apple 废弃字体。")
    }

    private func runLegacyFontName() {
        let migratedFont = PTFont.pingFangSCRegular
        publish("Legacy FontName\n迁移后的字体 = \(migratedFont.postScriptName)\nforwarded catalog count = \(PTFontCatalog.allFonts.count)\n迁移新代码请使用 PTFont.pingFangSCRegular。")
    }
}

private struct CollectionFixture: Codable, Sendable {
    let users: [PTModelNetworkDemoViewController.User]
    let owners: [String: PTModelNetworkDemoViewController.User]
}

private struct StringifiedFixture: Codable, Sendable {
    let id: Int
    let name: String
    let profile: PTStringifiedValue<PTModelNetworkDemoViewController.Profile>
}
