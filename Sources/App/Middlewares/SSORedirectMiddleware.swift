import Authentication

public struct SSORedirectMiddleware<A>: Middleware where A: Authenticatable {
    /// The path to redirect to
    let path: String
    
    // copy of RedirectMiddleware
    public init(A authenticatableType: A.Type = A.self, path: String) {
        self.path = path
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        if try req.isAuthenticated(A.self) {
            return try next.respond(to: req)
        }
        
        // TODO: redirect with all query parameters if possible
        if let ssoContinue = try? req.query.get(String.self, at: "continue") {
            
            //TODO: check origin for allowed access
            try req.session()["continue"] = ssoContinue
        }
        
        let redirect = req.redirect(to: path)
        return req.eventLoop.newSucceededFuture(result: redirect)
    }
    
    /// Use this middleware to redirect users away from
    /// protected content to a login page
    public static func login(path: String = "/login") -> SSORedirectMiddleware {
        return SSORedirectMiddleware(path: path)
    }
}
