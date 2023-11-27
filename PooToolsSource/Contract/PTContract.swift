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
public class PTContractIndexModel:NSObject {
    open var indexStrings:[String] = [String]()
    open var contractModel:[PTContractModel] = [PTContractModel]()
}

@objcMembers
public class PTContractModel:NSObject {
    open var key:String = ""
    open var contractModel:[PTContractSubModel] = [PTContractSubModel]()
}

@objcMembers
public class PTContractSubModel:NSObject {
    open var givenName:String = ""
    open var familyName:String = ""
    open var phonenumbers:[String] = []
    open var image:UIImage?
}

@objcMembers
public class PTContract: NSObject {

    public static let share = PTContract()
    
    public static func getContractData() async throws -> PTContractIndexModel {
        await withUnsafeContinuation { continuation in
            PTContract.share.getContractData { model in
                if model != nil {
                    continuation.resume(returning: model!)
                } else {
                    continuation.resume(throwing: NSError(domain: "Model nil", code: 0) as! Never)
                }
            }
        }
    }
    
    public func getContractData(handle: @escaping (_ model:PTContractIndexModel?)->Void) {
        PTGCDManager.gcdGobal(qosCls: .background) {
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    let keys = [CNContactGivenNameKey,CNContactFamilyNameKey,CNContactPhoneNumbersKey,CNContactThumbnailImageDataKey,CNContactImageDataAvailableKey]
                    var contacts = [CNContact]()
                    let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                    do {
                        try store.enumerateContacts(with: request, usingBlock: { contact, stop in
                            contacts.append(contact)
                        })
                        
                        // 将联系人按照姓氏的首字母进行分类
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

                        let indexModel = PTContractIndexModel()
                        indexModel.indexStrings = sortedKeys
                        
                        // 遍历字典并输出每个键对应的联系人
                        var contractModels = [PTContractModel]()
                        for key in sortedKeys {
                            let keyModel = PTContractModel()
                            keyModel.key = key
                            if let contacts = contactDict[key] {
                                let subModel = PTContractSubModel()
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
                    } catch {
                        PTNSLogConsole(error.localizedDescription)
                        handle(nil)
                    }
                } else {
                    PTNSLogConsole(error?.localizedDescription ?? "User denied access to contacts")
                    handle(nil)
                }
            }
        }
    }
}
