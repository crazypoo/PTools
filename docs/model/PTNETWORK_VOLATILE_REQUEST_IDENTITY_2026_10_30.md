# Opt-in volatile request header identity (2026-10-30)

## Problem
A consumer may sign every GET request using a fresh millisecond `ts` header. Using *all* headers in the cache and in-flight request keys causes every otherwise identical GET to miss cache and deduplication.

## Contract
- Default remains unchanged: `PTNetworkConfig.requestIdentityIgnoredHeaders = []`.
- The caller can opt into `networkConfig.requestIdentityIgnoredHeaders = ["ts"]` **only when `ts` is non-semantic to response identity**.
- This option is applied at `Network.executeRequest` / `executeLegacyRequest`, to the actual `URLRequest` **after** any caller-provided custom headers. It does **not** require the caller to use `Network.prepareRequestHeaders` or a predefined PTools header layout.
- `PT-Identity-Ignored-Headers` is only internal request metadata produced by PTools at the execution boundary (not something a caller needs to set). Any caller-provided value with that name is overwritten; transport strips the internal metadata before sending the original custom headers to the server.
- A project that calls its own Alamofire/URLSession transport without going through PTools `Network` is not affected; this opt-in only applies to PTools-managed requests.
- Never ignore credentials or response variants: `authorization`, `proxy-authorization`, `cookie`, `token`, `x-api-key`, `x-auth-token`, `language`, `accept-language`, `package`, `sign`, `signature`, `host`. These remain part of identity even if accidentally included in the opt-in list.
- Cache-only, cache-else-network, network-only, and network-else-cache semantics are unchanged. Explicit `.networkOnly` still bypasses the cache for a user-initiated refresh.
- This does not change the actual API request timestamp or signature.

## Validation
Automated XCTest covers opt-in versus default request keys, custom `URLRequest` headers and nonstandard nonce/identity names, cross-account/language isolation, cache reuse when `ts` changes, and that only real caller headers (not internal metadata) are forwarded to a URLProtocol fixture.

Still required: run PToolsNetworkTests in an Xcode-capable macOS CI/host, verify normal GET caching and revalidation, and validate a signed API request with the consuming app. No local iOS/Xcode run was available in this connector-only edit.
