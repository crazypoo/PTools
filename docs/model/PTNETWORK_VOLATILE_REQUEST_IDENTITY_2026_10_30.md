# Opt-in volatile request header identity (2026-10-30)

## Problem
A consumer may sign every GET request using a fresh millisecond `ts` header. Using *all* headers in the cache and in-flight request keys causes every otherwise identical GET to miss cache and deduplication.

## Contract
- Default remains unchanged: `PTNetworkConfig.requestIdentityIgnoredHeaders = []`.
- The caller can opt into `networkConfig.requestIdentityIgnoredHeaders = ["ts"]` **only when `ts` is non-semantic to response identity**.
- `PT-Identity-Ignored-Headers` carries the opt-in names only inside the request pipeline. The transport strips it before issuing the HTTP request. It is also excluded from request identity itself.
- Never ignore credentials or response variants: `authorization`, `proxy-authorization`, `cookie`, `token`, `x-api-key`, `x-auth-token`, `language`, `accept-language`, `package`, `sign`, `signature`, `host`. These remain part of identity even if accidentally included in the opt-in list.
- Cache-only, cache-else-network, network-only, and network-else-cache semantics are unchanged. Explicit `.networkOnly` still bypasses the cache for a user-initiated refresh.
- This does not change the actual API request timestamp or signature.

## Validation
Automated XCTest covers opt-in versus default request keys, cross-account/language isolation, cache reuse when `ts` changes, and that the identity metadata header is not forwarded to a URLProtocol fixture.

Still required: run PToolsNetworkTests in an Xcode-capable macOS CI/host, verify normal GET caching and revalidation, and validate a signed API request with the consuming app. No local iOS/Xcode run was available in this connector-only edit.
