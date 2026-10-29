/// Bounded FIFO ring for optional diagnostics. Storage remains owned by its
/// actor/manager; this type has no runtime hooks, UIKit or global state.
public struct PTDebugRingBuffer<Element> {
    private let capacity: Int
    private var values: [Element] = []
    private var head = 0

    public init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    /// Returns true only if the oldest element was overwritten.
    @discardableResult
    public mutating func append(_ element: Element) -> Bool {
        guard values.count == capacity else {
            values.append(element)
            return false
        }
        values[head] = element
        head = (head + 1) % capacity
        return true
    }

    public var count: Int { values.count }

    public var latestValue: Element? {
        guard !values.isEmpty else { return nil }
        return values.count == capacity
            ? values[(head + capacity - 1) % capacity]
            : values.last
    }

    public var orderedValues: [Element] {
        guard values.count == capacity, head != 0 else { return values }
        return Array(values[head..<values.count]) + Array(values[0..<head])
    }
}
