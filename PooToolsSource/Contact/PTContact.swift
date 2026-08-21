//
//  PTContract.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
// Contacts.framework returns reference objects from legacy callbacks; they
// are converted to PTContactSnapshot before crossing the callback boundary.
@preconcurrency import Contacts

private struct PTContactSnapshot: Sendable {
    let givenName: String
    let familyName: String
    let phoneNumbers: [String]
    let thumbnailImageData: Data?
}

@objcMembers
@MainActor
public class PTContactIndexModel: NSObject {
    open var indexStrings:[String] = [String]()
    open var contractModel:[PTContactModel] = [PTContactModel]()
}

@objcMembers
@MainActor
public class PTContactModel: NSObject {
    open var key:String = ""
    open var contractModel:[PTContactSubModel] = [PTContactSubModel]()
}

@objcMembers
@MainActor
public class PTContactSubModel: NSObject {
    open var givenName:String = ""
    open var familyName:String = ""
    open var phonenumbers:[String] = []
    open var image:UIImage?
}

@MainActor
@objcMembers
public class PTContact: NSObject {

    public static let share = PTContact()
    
    public static func getContractData() async throws -> PTContactIndexModel {
        try await withCheckedThrowingContinuation { continuation in
            PTContact.share.getContactData { model in
                if let m = model {
                    continuation.resume(returning: m)
                } else {
                    continuation.resume(throwing: NSError(domain: "PTContact", code: 0, userInfo: [NSLocalizedDescriptionKey: "联系人数据为空"]))
                }
            }
        }
    }
    
    // MARK: 获取通讯录的信息
    /// 获取通讯录的信息
    /// - Parameter keys: 获取Fetch,并且指定之后要获取联系人中的什么属性
    ///   - completion: 结果闭包
    private static func selectContactsData(keys: [String] = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey], completion: @escaping @Sendable ([PTContactSnapshot], Error?) -> Void) {
        // 创建通讯录对象
        let store = CNContactStore()
        store.requestAccess(for: .contacts) {(granted, error) in
            if (granted) && (error == nil) {
                // 创建请求对象 需要传入一个(keysToFetch: [CNKeyDescriptor]) 包含'CNKeyDescriptor'类型的数组
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                do {
                    var contacts: [PTContactSnapshot] = []
                    // 需要传入一个CNContactFetchRequest
                    try store.enumerateContacts(with: request, usingBlock: {(contact : CNContact, stop : UnsafeMutablePointer) -> Void in
                        contacts.append(PTContactSnapshot(
                            givenName: contact.givenName,
                            familyName: contact.familyName,
                            phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue },
                            thumbnailImageData: contact.imageDataAvailable ? contact.thumbnailImageData : nil
                        ))
                    })
                    completion(contacts, nil)
                } catch {
                    completion([], error)
                }
            } else {
                completion([], error)
            }
        }
    }

    public func getContactData(handle: @escaping @MainActor @Sendable (_ model:PTContactIndexModel?) -> Void) {
        PTGCDManager.shared.runOnBackground(priority: .background, block: {
            PTGCDManager.shared.runOnMain {
                PTContact.selectContactsData { contacts, error in
                    PTGCDManager.shared.runOnMain {
                        if error == nil {
                            var contactDict = [String: [(PTContactSnapshot, UIImage?)]]()
                            for contact in contacts {
                                let familyName = contact.familyName
                                let chinestToEng = familyName.chineseTransToMandarinAlphabet()
                                let firstLetter = String(chinestToEng.prefix(1)).uppercased()
                                let image = contact.thumbnailImageData.flatMap(UIImage.init(data:))
                                if var array = contactDict[firstLetter] {
                                    array.append((contact, image))
                                    contactDict[firstLetter] = array
                                } else {
                                    contactDict[firstLetter] = [(contact, image)]
                                }
                            }

                            // 按照首字母排序字典
                            let sortedKeys = contactDict.keys.sorted()

                            let indexModel = PTContactIndexModel()
                            indexModel.indexStrings = sortedKeys

                            // 遍历字典并输出每个键对应的联系人
                            var contractModels = [PTContactModel]()
                            for key in sortedKeys {
                                let keyModel = PTContactModel()
                                keyModel.key = key
                                if let contacts = contactDict[key] {
                                    for contact in contacts {
                                        let subModel = PTContactSubModel()
                                        if let image = contact.1 {
                                            // 处理联系人头像
                                            subModel.image = image
                                        }

                                        for number in contact.0.phoneNumbers {
                                            subModel.phonenumbers.append(number)
                                        }
                                        subModel.givenName = contact.0.givenName
                                        subModel.familyName = contact.0.familyName
                                        keyModel.contractModel.append(subModel)
                                    }
                                }
                                contractModels.append(keyModel)
                            }
                            indexModel.contractModel = contractModels
                            handle(indexModel)
                        } else {
                            PTNSLogConsole(error?.localizedDescription ?? "User denied access to contacts",levelType: .error,loggerType: .contract)
                            handle(nil)
                        }
                    }
                }
            }
        })
    }
    
    // MARK: 添加新联系人
    /// 添加新联系人
    /// - Parameters:
    ///   - contact: 联系人的信息
    ///   - completion: 结果闭包
    static func addContactItem(contact: CNMutableContact, completion: @escaping @Sendable (Bool, Error?) -> Void) {
        // 创建通讯录对象
        let store = CNContactStore()
        store.requestAccess(for: .contacts) {(granted, error) in
            if (granted) && (error == nil) {
                // 添加联系人请求
                let saveRequest = CNSaveRequest()
                saveRequest.add(contact, toContainerWithIdentifier: nil)
                do {
                    // 写入联系人
                    try store.execute(saveRequest)
                    completion(true, nil)
                } catch {
                    completion(false, error)
                }
            } else {
                completion(false, error)
            }
        }
    }
    
    // MARK: 更新联系人
    /// 更新联系人
    /// - Parameters:
    ///   - identifier: 唯一标识符
    ///   - familyName: 姓氏
    ///   - givenName: 名字
    ///   - phoneNumbers: 手机号码数组
    ///   - keys: key
    ///   - completion: 结果闭包
    static func updateContactItem(identifier: String, familyName: String, givenName: String, phoneNumbers: [CNLabeledValue<CNPhoneNumber>], keys: [String] = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey], completion: @escaping @Sendable (Bool, Error?) -> Void) {
        // 创建通讯录对象
        let store = CNContactStore()
        store.requestAccess(for: .contacts) {(granted, error) in
            if (granted) && (error == nil) {
                guard let itemContact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys as [CNKeyDescriptor]) else {
                    return
                }
                guard let mutableContact = itemContact.mutableCopy() as? CNMutableContact else {
                    completion(false, NSError(domain: "PTContact", code: 1, userInfo: [NSLocalizedDescriptionKey: "联系人不可编辑"]))
                    return
                }
                mutableContact.familyName = familyName
                mutableContact.givenName = givenName
                mutableContact.phoneNumbers = phoneNumbers
                // 修改联系人请求
                let request = CNSaveRequest()
                request.update(mutableContact)
                do {
                    // 修改联系人
                    try store.execute(request)
                    completion(true, error)
                } catch {
                    completion(false, error)
                }
            } else {
                completion(false, error)
            }
        }
    }
    
    // MARK: 删除联系人
    /// 删除联系人
    /// - Parameters:
    ///   - identifier: 唯一标识符
    ///   - keys: key
    ///   - completion: 结果闭包
    static func deleteContactItem(identifier: String, keys: [String] = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey], completion: @escaping @Sendable (Bool, Error?) -> Void) {
        // 创建通讯录对象
        let store = CNContactStore()
        store.requestAccess(for: .contacts) {(granted, error) in
            if (granted) && (error == nil) {
                guard let itemContact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys as [CNKeyDescriptor]) else {
                    return
                }
                guard let mutableContact = itemContact.mutableCopy() as? CNMutableContact else {
                    completion(false, NSError(domain: "PTContact", code: 1, userInfo: [NSLocalizedDescriptionKey: "联系人不可删除"]))
                    return
                }
                // 删除联系人请求
                let request = CNSaveRequest()
                request.delete(mutableContact)
                do {
                    // 执行操作
                    try store.execute(request)
                    completion(true, error)
                } catch {
                    completion(false, error)
                }
            } else {
                completion(false, error)
            }
        }
    }
}
