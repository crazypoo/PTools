//
//  PTContract.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Contacts

@objcMembers
public class PTContactIndexModel:NSObject {
    open var indexStrings:[String] = [String]()
    open var contractModel:[PTContactModel] = [PTContactModel]()
}

@objcMembers
public class PTContactModel:NSObject {
    open var key:String = ""
    open var contractModel:[PTContactSubModel] = [PTContactSubModel]()
}

@objcMembers
public class PTContactSubModel:NSObject {
    open var givenName:String = ""
    open var familyName:String = ""
    open var phonenumbers:[String] = []
    open var image:UIImage?
}

@objcMembers
public class PTContact: NSObject {

    public static let share = PTContact()
    
    public static func getContractData() async throws -> PTContactIndexModel {
        await withUnsafeContinuation { continuation in
            PTContact.share.getContactData { model in
                if let m = model {
                    continuation.resume(returning: m)
                } else {
                    continuation.resume(throwing: NSError(domain: "Model nil", code: 0) as! Never)
                }
            }
        }
    }
    
    // MARK: 获取通讯录的信息
    /// 获取通讯录的信息
    /// - Parameter keys: 获取Fetch,并且指定之后要获取联系人中的什么属性
    ///   - completion: 结果闭包
    static func selectContactsData(keys: [String] = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey], completion: @escaping (([CNContact], Error?) -> Void)) {
        // 创建通讯录对象
        let store = CNContactStore()
        store.requestAccess(for: .contacts) {(granted, error) in
            if (granted) && (error == nil) {
                // 创建请求对象 需要传入一个(keysToFetch: [CNKeyDescriptor]) 包含'CNKeyDescriptor'类型的数组
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                do {
                    var contacts: [CNContact] = []
                    // 需要传入一个CNContactFetchRequest
                    try store.enumerateContacts(with: request, usingBlock: {(contact : CNContact, stop : UnsafeMutablePointer) -> Void in
                        contacts.append(contact)
                    })
                    completion(contacts, nil)
                } catch {
                    completion([], nil)
                }
            } else {
                completion([], error)
            }
        }
    }

    public func getContactData(handle: @escaping (_ model:PTContactIndexModel?) -> Void) {
        PTGCDManager.gcdGobal(qosCls: .background) {
            PTContact.selectContactsData { contacts, error in
                if error == nil {
                    var contactDict = [String: [(CNContact,UIImage?)]]()
                    let formatter = CNContactFormatter()
                    formatter.style = .fullName
                    for contact in contacts {
                        let familyName = contact.familyName
                        let chinestToEng = familyName.chineseTransToMandarinAlphabet()
                        let firstLetter = String(chinestToEng.prefix(1)).uppercased()
                        if var array = contactDict[firstLetter] {
                            array.append((contact,contact.imageDataAvailable ? UIImage(data: contact.thumbnailImageData ?? Data()) : nil))
                            contactDict[firstLetter] = array
                        } else {
                            contactDict[firstLetter] = [(contact, contact.imageDataAvailable ? UIImage(data: contact.thumbnailImageData ?? Data()) : nil)]
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
                            let subModel = PTContactSubModel()
                            for contact in contacts {
                                if let image = contact.1 {
                                    // 处理联系人头像
                                    subModel.image = image
                                }

                                for number in contact.0.phoneNumbers {
                                    subModel.phonenumbers.append(number.value.stringValue)
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
                    PTNSLogConsole(error?.localizedDescription ?? "User denied access to contacts",levelType: .Error,loggerType: .Contract)
                    handle(nil)
                }
            }            
        }
    }
    
    // MARK: 添加新联系人
    /// 添加新联系人
    /// - Parameters:
    ///   - contact: 联系人的信息
    ///   - completion: 结果闭包
    static func addContactItem(contact: CNMutableContact, completion: @escaping ((Bool, Error?) -> Void)) {
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
                    completion(true, error)
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
    static func updateContactItem(identifier: String, familyName: String, givenName: String, phoneNumbers: [CNLabeledValue<CNPhoneNumber>], keys: [String] = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey], completion: @escaping ((Bool, Error?) -> Void)) {
        // 创建通讯录对象
        let store = CNContactStore()
        store.requestAccess(for: .contacts) {(granted, error) in
            if (granted) && (error == nil) {
                guard let itemContact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys as [CNKeyDescriptor]) else {
                    return
                }
                let mutableContact = itemContact.mutableCopy() as! CNMutableContact
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
    static func deleteContactItem(identifier: String, keys: [String] = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey], completion: @escaping ((Bool, Error?) -> Void)) {
        // 创建通讯录对象
        let store = CNContactStore()
        store.requestAccess(for: .contacts) {(granted, error) in
            if (granted) && (error == nil) {
                guard let itemContact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys as [CNKeyDescriptor]) else {
                    return
                }
                let mutableContact = itemContact.mutableCopy() as! CNMutableContact
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
