//
//  PTErrorHelper.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum PTErrorHelper {
    static func handle(_ error: Error?, model: PTHttpModel) -> PTHttpModel {
        if error == nil {
            // https://httpstatuses.com
            switch Int(model.statusCode ?? "") {
            case 100:
                model.errorDescription = "Error continue description"
                model.errorLocalizedDescription = "Error continue"
            case 101:
                model.errorDescription = "Error switching protocolsdescription"
                model.errorLocalizedDescription = "Error switchingprotocols"
            case 102:
                model.errorDescription = "Error processingdescription"
                model.errorLocalizedDescription = "Error processing"
            case 103:
                model.errorDescription = "Error checkpointdescription"
                model.errorLocalizedDescription = "Error checkpoint"
            case 122:
                model.errorDescription = "Error uritoolongdescription"
                model.errorLocalizedDescription = "Error uritoolong"
            case 300:
                model.errorDescription = "Error multiplechoicesdescription"
                model.errorLocalizedDescription = "Error multiplechoices"
            case 301:
                model.errorDescription = "Error movedpermanentlydescription"
                model.errorLocalizedDescription = "Error movedpermanently"
            case 302:
                model.errorDescription = "Error founddescription"
                model.errorLocalizedDescription = "Error found"
            case 303:
                model.errorDescription = "Error seeotherdescription"
                model.errorLocalizedDescription = "Error seeother"
            case 304:
                model.errorDescription = "Error notmodifieddescription"
                model.errorLocalizedDescription = "Error notmodified"
            case 305:
                model.errorDescription = "Error useproxydescription"
                model.errorLocalizedDescription = "Error useproxy"
            case 306:
                model.errorDescription = "Error switchproxydescription"
                model.errorLocalizedDescription = "Error switchproxy"
            case 307:
                model.errorDescription = "Error temporaryredirectdescription"
                model.errorLocalizedDescription = "Error temporaryredirect"
            case 308:
                model.errorDescription = "Error permanentredirectdescription"
                model.errorLocalizedDescription = "Error permanentredirect"
            case 400:
                model.errorDescription = "Error badrequestdescription"
                model.errorLocalizedDescription = "Error badrequest"
            case 401:
                model.errorDescription = "Error unauthorizeddescription"
                model.errorLocalizedDescription = "Error unauthorized"
            case 402:
                model.errorDescription = "Error paymentrequireddescription"
                model.errorLocalizedDescription = "Error paymentrequired"
            case 403:
                model.errorDescription = "Error forbiddendescription"
                model.errorLocalizedDescription = "Error forbidden"
            case 404:
                model.errorDescription = "Error notfounddescription"
                model.errorLocalizedDescription = "Error notfound"
            case 405:
                model.errorDescription = "Error methodnotalloweddescription"
                model.errorLocalizedDescription = "Error methodnotallowed"
            case 406:
                model.errorDescription = "Error notacceptabledescription"
                model.errorLocalizedDescription = "Error notacceptable"
            case 407:
                model.errorDescription = "Error proxyauthenticationrequireddescription"
                model.errorLocalizedDescription = "Error proxyauthenticationrequired"
            case 408:
                model.errorDescription = "Error requesttimeoutdescription"
                model.errorLocalizedDescription = "Error requesttimeout"
            case 409:
                model.errorDescription = "Error conflictdescription"
                model.errorLocalizedDescription = "Error conflict"
            case 410:
                model.errorDescription = "Error gonedescription"
                model.errorLocalizedDescription = "Error gone"
            case 411:
                model.errorDescription = "Error lengthrequireddescription"
                model.errorLocalizedDescription = "Error lengthrequired"
            case 412:
                model.errorDescription = "Error preconditionfaileddescription"
                model.errorLocalizedDescription = "Error preconditionfailed"
            case 413:
                model.errorDescription = "Error requestentitytoolargedescription"
                model.errorLocalizedDescription = "Error requestentitytoolarge"
            case 414:
                model.errorDescription = "Error requesturitoolongdescription"
                model.errorLocalizedDescription = "Error requesturitoolong"
            case 415:
                model.errorDescription = "Error unsupportedmediatypedescription"
                model.errorLocalizedDescription = "Error unsupportedmediatype"
            case 416:
                model.errorDescription = "Error requestedrangenotsatisfiabledescription"
                model.errorLocalizedDescription = "Error requestedrangenotsatisfiable"
            case 417:
                model.errorDescription = "Error expectationfaileddescription"
                model.errorLocalizedDescription = "Error expectationfailed"
            case 418:
                model.errorDescription = "Error imateapotdescription"
                model.errorLocalizedDescription = "Error imateapot"
            case 420:
                model.errorDescription = "Error twitterratelimitingdescription"
                model.errorLocalizedDescription = "Error twitterratelimiting"
            case 421:
                model.errorDescription = "Error misdirectedrequestdescription"
                model.errorLocalizedDescription = "Error misdirectedrequest"
            case 422:
                model.errorDescription = "Error unprocessableentitydescription"
                model.errorLocalizedDescription = "Error unprocessableentity"
            case 423:
                model.errorDescription = "Error lockeddescription"
                model.errorLocalizedDescription = "Error locked"
            case 424:
                model.errorDescription = "Error faileddependencydescription"
                model.errorLocalizedDescription = "Error faileddependency"
            case 426:
                model.errorDescription = "Error upgraderequireddescription"
                model.errorLocalizedDescription = "Error upgraderequired"
            case 428:
                model.errorDescription = "Error preconditionrequireddescription"
                model.errorLocalizedDescription = "Error preconditionrequired"
            case 429:
                model.errorDescription = "Error toomanyrequestsdescription"
                model.errorLocalizedDescription = "Error toomanyrequests"
            case 431:
                model.errorDescription = "Error requestheaderfieldstoolargedescription"
                model.errorLocalizedDescription = "Error requestheaderfieldstoolarge"
            case 444:
                model.errorDescription = "Error noresponsedescription"
                model.errorLocalizedDescription = "Error noresponse"
            case 449:
                model.errorDescription = "Error retrywithdescription"
                model.errorLocalizedDescription = "Error retrywith"
            case 450:
                model.errorDescription = "Error blockedbywindowsparentalcontrolsdescription"
                model.errorLocalizedDescription = "Error blockedbywindowsparentalcontrols"
            case 451:
                model.errorDescription = "Error wrongexchangeserverdescription"
                model.errorLocalizedDescription = "Error wrongexchangeserver"
            case 499:
                model.errorDescription = "Error clientclosedrequestdescription"
                model.errorLocalizedDescription = "Error clientclosedrequest"
            case 500:
                model.errorDescription = "Error internalserverError description"
                model.errorLocalizedDescription = "Error internalservererror"
            case 501:
                model.errorDescription = "Error notimplementeddescription"
                model.errorLocalizedDescription = "Error notimplemented"
            case 502:
                model.errorDescription = "Error badgatewaydescription"
                model.errorLocalizedDescription = "Error badgateway"
            case 503:
                model.errorDescription = "Error serviceunavailabledescription"
                model.errorLocalizedDescription = "Error serviceunavailable"
            case 504:
                model.errorDescription = "Error gatewaytimeoutdescription"
                model.errorLocalizedDescription = "Error gatewaytimeout"
            case 505:
                model.errorDescription = "Error httpversionnotsupporteddescription"
                model.errorLocalizedDescription = "Error httpversionnotsupported"
            case 506:
                model.errorDescription = "Error variantalsonegotiatesdescription"
                model.errorLocalizedDescription = "Error variantalsonegotiates"
            case 507:
                model.errorDescription = "Error insufficientstoragedescription"
                model.errorLocalizedDescription = "Error insufficientstorage"
            case 508:
                model.errorDescription = "Error loopdetecteddescription"
                model.errorLocalizedDescription = "Error loopdetected"
            case 509:
                model.errorDescription = "Error bandwidthlimitexceededdescription"
                model.errorLocalizedDescription = "Error bandwidthlimitexceeded"
            case 510:
                model.errorDescription = "Error notextendeddescription"
                model.errorLocalizedDescription = "Error notextended"
            case 511:
                model.errorDescription = "Error networkauthenticationrequireddescription"
                model.errorLocalizedDescription = "Error networkauthenticationrequired"
            case 526:
                model.errorDescription = "Error invalidsslcertificatedescription"
                model.errorLocalizedDescription = "Error invalidsslcertificate"
            case 598:
                model.errorDescription = "Error networkreadtimeoutdescription"
                model.errorLocalizedDescription = "Error networkreadtimeout"
            case 599:
                model.errorDescription = "Error networkconnecttimeoutdescription"
                model.errorLocalizedDescription = "Error networkconnecttimeout"
            default:
                break
            }
        }

        return model
    }
}
