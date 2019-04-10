import Leaf
import Vapor
import FluentSQLite
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    let leafProvider = LeafProvider()
    try services.register(leafProvider)
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    try services.register(FluentSQLiteProvider())
    
    var databases = DatabasesConfig()
    try databases.add(database: SQLiteDatabase(storage: .file(path: "db.sqlite")), as: .sqlite)
    services.register(databases)
    
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .sqlite)
    services.register(migrations)
    
    try services.register(AuthenticationProvider())
    
    var middlewares = MiddlewareConfig.default()
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}
