import Foundation

struct PortRegistry {
    struct Entry {
        let name: String
        let category: PortCategory
    }

    nonisolated(unsafe) static let ports: [Int: Entry] = [
        // — Dev Servers —
        1313: .init(name: "Hugo",              category: .devServer),
        2368: .init(name: "Ghost",             category: .devServer),
        3000: .init(name: "Node / Next.js",    category: .devServer),
        3001: .init(name: "Node",              category: .devServer),
        3002: .init(name: "Node",              category: .devServer),
        3003: .init(name: "Node",              category: .devServer),
        4000: .init(name: "Phoenix / Gatsby",  category: .devServer),
        4200: .init(name: "Angular",           category: .devServer),
        4321: .init(name: "Astro",             category: .devServer),
        4567: .init(name: "Sinatra",           category: .devServer),
        5001: .init(name: "Flask alt",         category: .devServer),
        5173: .init(name: "Vite",              category: .devServer),
        5174: .init(name: "Vite",              category: .devServer),
        5175: .init(name: "Vite",              category: .devServer),
        6006: .init(name: "Storybook",         category: .devServer),
        8000: .init(name: "Django / Python",   category: .devServer),
        8080: .init(name: "HTTP alt",          category: .devServer),
        8081: .init(name: "HTTP alt",          category: .devServer),
        8888: .init(name: "Jupyter",           category: .devServer),

        // — Tools & Infrastructure —
        9000: .init(name: "MinIO / PHP-FPM",   category: .tool),
        9001: .init(name: "MinIO Console",     category: .tool),
        9090: .init(name: "Prometheus",        category: .tool),
        9091: .init(name: "Prometheus alt",    category: .tool),
        9200: .init(name: "Elasticsearch",     category: .tool),
        9300: .init(name: "Elasticsearch",     category: .tool),
        16686: .init(name: "Jaeger UI",        category: .tool),

        // — Databases —
        1433:  .init(name: "SQL Server",       category: .database),
        3306:  .init(name: "MySQL",            category: .database),
        3307:  .init(name: "MySQL alt",        category: .database),
        5432:  .init(name: "PostgreSQL",       category: .database),
        5433:  .init(name: "PostgreSQL alt",   category: .database),
        5434:  .init(name: "PostgreSQL alt",   category: .database),
        5984:  .init(name: "CouchDB",          category: .database),
        6379:  .init(name: "Redis",            category: .database),
        6380:  .init(name: "Redis alt",        category: .database),
        6381:  .init(name: "Redis alt",        category: .database),
        27017: .init(name: "MongoDB",          category: .database),
        27018: .init(name: "MongoDB alt",      category: .database),
        27019: .init(name: "MongoDB alt",      category: .database),
        9042:  .init(name: "Cassandra",        category: .database),

        // — macOS System —
        5000:  .init(name: "AirPlay / ControlCenter", category: .system),
        7000:  .init(name: "AirPlay",          category: .system),
        7001:  .init(name: "AirPlay alt",      category: .system),
        1200:  .init(name: "Xcode Device",     category: .system),
        8791:  .init(name: "Xcode Wireless",   category: .system),
        8792:  .init(name: "Xcode Wireless",   category: .system),
        8793:  .init(name: "Xcode Wireless",   category: .system),
        28196: .init(name: "Xcode Support",    category: .system),
        28198: .init(name: "Xcode Support",    category: .system),
    ]

    static func lookup(_ port: Int) -> Entry? { ports[port] }
}
