// English: Keep URL session diagnostics separate from request construction and execution.
// Español: Mantiene los diagnósticos de URLSession separados de la construcción y ejecución de solicitudes.
// 中文：将 URLSession 诊断从请求构造和执行中独立出来。

import Foundation

// MARK: - ================= 9. 监控探针与耗时剖析 =================

public final class NetworkSessionDelegate:NSObject,URLSessionTaskDelegate {
    public func urlSession(_ session:URLSession,task:URLSessionTask,didFinishCollecting metrics: URLSessionTaskMetrics) {
        PTNSLogConsole("网络任务实例化和完成之间的时间间隔（taskInterval）: \(String(describing: metrics.taskInterval))")
        PTNSLogConsole("网络任务重定向次数（redirectCount）: \(String(describing: metrics.redirectCount))")
        for metric in metrics.transactionMetrics { handleTransactionMetric(metric) }
    }

    private func handleTransactionMetric(_ metric:URLSessionTaskTransactionMetrics) {
        PTNSLogConsole("----------网络时间方面-----")
        PTNSLogConsole("开始获取资源的时间（fetchStartDate）: \( String(describing: metric.fetchStartDate))")
        PTNSLogConsole("域名解析开始的时间（domainLookupStartDate）: \(String(describing: metric.domainLookupStartDate))")
        PTNSLogConsole("域名解析结束的时间（domainLookupEndDate）: \(String(describing: metric.domainLookupEndDate))")
        PTNSLogConsole("开始建立TCP连接的时间(connectStartDate): \(String(describing: metric.connectStartDate))")
        PTNSLogConsole("完成建立TCP连接的时间(connectEndDate): \(String(describing: metric.connectEndDate))")
        PTNSLogConsole("开始TLS安全握手的时间（secureConnectionStartDate）: \(String(describing: metric.secureConnectionStartDate))")
        PTNSLogConsole("完成TLS安全握手的时间（secureConnectionEndDate）: \(String(describing: metric.secureConnectionEndDate))")
        PTNSLogConsole("请求发送的时间（requestStartDate）: \(String(describing: metric.requestStartDate))")
        PTNSLogConsole("请求结束的时间（requestEndDate）: \(String(describing: metric.requestEndDate))")
        PTNSLogConsole("收到响应的第一个字节的时间（responseStartDate）: \(String(describing: metric.responseStartDate))")
        PTNSLogConsole("收到响应的最后一个字节的时间（responseEndDate）: \(String(describing: metric.responseEndDate))")

        if let domainLookupEndDate = metric.domainLookupEndDate,let domainLookupStartDate = metric.domainLookupStartDate {
            PTNSLogConsole("域名解析时长：\(domainLookupEndDate.timeIntervalSince(domainLookupStartDate) * 1000) 秒")
        } else { PTNSLogConsole("域名解析时长无法计算") }

        if let tcpConnectionEndDate = metric.connectEndDate,let tcpConnectionStartDate = metric.connectStartDate {
            PTNSLogConsole("TCP连接时长: \(tcpConnectionEndDate.timeIntervalSince(tcpConnectionStartDate) * 1000) 秒")
        } else { PTNSLogConsole("TCP连接时长无法计算") }

        if let tlsHandshakeEndDate = metric.secureConnectionEndDate,let tlsHandshakeStartDate = metric.secureConnectionStartDate {
            PTNSLogConsole("TLS安全握手时长: \(tlsHandshakeEndDate.timeIntervalSince(tlsHandshakeStartDate) * 1000) 秒")
        } else { PTNSLogConsole("TLS安全握手时长无法计算") }

        if let responseEndDate = metric.responseEndDate,let requestStartDate = metric.requestStartDate {
            PTNSLogConsole("请求响应时长【从请求开发到请求结束】：\(responseEndDate.timeIntervalSince(requestStartDate)) 秒")
        } else { PTNSLogConsole("请求响应时长无法计算") }

        if let connectionEndDate = metric.responseStartDate,let connectionStartDate = metric.responseStartDate {
            PTNSLogConsole("响应时长: \(connectionEndDate.timeIntervalSince(connectionStartDate) * 1000) 秒")
        } else { PTNSLogConsole("响应时长无法计算") }

        PTNSLogConsole("----------网络数据监控方面（iOS13+有效）-----")
        PTNSLogConsole("iOS13+发送前编码之前请求体数据的大小(countOfRequestBodyBytesBeforeEncoding):\(metric.countOfRequestBodyBytesBeforeEncoding)")
        PTNSLogConsole("iOS13+发送的请求头字节数(countOfRequestHeaderBytesSent):\(metric.countOfRequestHeaderBytesSent)")
        PTNSLogConsole("iOS13+发送前编码之前请求体数据的大小(countOfResponseBodyBytesAfterDecoding):\(metric.countOfResponseBodyBytesAfterDecoding)")
        PTNSLogConsole("iOS13+传递给代理或完成处理程序的数据的大小(countOfResponseBodyBytesAfterDecoding):\(metric.countOfResponseBodyBytesAfterDecoding)")
        PTNSLogConsole("iOS13+接收的响应体字节数(countOfResponseBodyBytesReceived):\(metric.countOfResponseBodyBytesReceived)")
        PTNSLogConsole("iOS13+接收的响应头字节数(countOfResponseHeaderBytesReceived):\(metric.countOfResponseHeaderBytesReceived)")

        PTNSLogConsole("----------网络协议基础属性方面-----")
        PTNSLogConsole("使用的网络协议名称(networkProtocolName): \(metric.networkProtocolName ?? "Unknown")")
        PTNSLogConsole("iOS13+远程接口的IP地址(remoteAddress): \(String(describing: metric.remoteAddress))")
        PTNSLogConsole("iOS13 +本地接口的 IP 地址(localAddress): \(String(describing: metric.localAddress))")
        PTNSLogConsole("远程接口的端口号(remotePort): \(String(describing: metric.remotePort))")
        PTNSLogConsole("本地接口的端口号(localPort): \(String(describing: metric.localPort))")
        PTNSLogConsole("TLS密码套件(negotiatedTLSCipherSuite): \(String(describing: metric.negotiatedTLSCipherSuite?.rawValue))")
        PTNSLogConsole("TLS协议版本(negotiatedTLSProtocolVersion): \(String(describing: metric.negotiatedTLSProtocolVersion?.rawValue))")
        PTNSLogConsole("连接是否经由蜂窝网络(isCellular): \(metric.isCellular)")
        PTNSLogConsole("连接是否经由高成本接口(isExpensive): \(metric.isExpensive)")
        PTNSLogConsole("连接是否经由受限制的接口(isConstrained): \(metric.isConstrained)")
        PTNSLogConsole("是否使用了代理连接来获取资源(isProxyConnection): \(metric.isProxyConnection)")
        PTNSLogConsole("任务是否使用了重用连接来获取资源(isReusedConnection): \(metric.isReusedConnection)")
        PTNSLogConsole("连接是否成功协商了多路径协议(isMultipath): \(metric.isMultipath)")
        PTNSLogConsole("标识资源的加载方式(resourceFetchType): \(metric.resourceFetchType.rawValue)")
        
        switch(metric.domainResolutionProtocol) {
        case .unknown: PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): unknown")
        case .udp:     PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了udp 协议进行域名解析")
        case .tcp:     PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了tcp 协议进行域名解析")
        case .tls:     PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol):  表示使用了tls协议进行域名解析")
        case .https:   PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了https 协议进行域名解析")
        @unknown default: PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): unknown")
        }

        PTNSLogConsole("request url:\(String(describing: metric.request.url))")
        PTNSLogConsole("request httpMethod:\(String(describing: metric.request.httpMethod))")
        PTNSLogConsole("request timeoutInterval:\(metric.request.timeoutInterval)")
        let requestHeaders = Network.redactedHeaders(metric.request.allHTTPHeaderFields ?? [:])
        PTNSLogConsole("-----request allHTTPHeaderFields---\n\(requestHeaders)\n-----request allHTTPHeaderFields end-----")
        let requestBodySize = metric.request.httpBody?.count ?? 0
        PTNSLogConsole("request httpBody: [\(requestBodySize) bytes]")

        let httpURLResponse:HTTPURLResponse? = metric.response as? HTTPURLResponse ?? nil
        PTNSLogConsole("response statusCode:\(String(describing: httpURLResponse?.statusCode))")
        let responseHeaders = httpURLResponse?.allHeaderFields.reduce(into: [String: String]()) { result, item in
            result[String(describing: item.key)] = String(describing: item.value)
        } ?? [:]
        PTNSLogConsole("-----response allHeaderFields:\n\(Network.redactedHeaders(responseHeaders))\n-----response allHeaderFields end-----")
    }
}
