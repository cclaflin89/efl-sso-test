import Vapor

extension Request {
    public func redirectWithOriginalParams(to location: String, type: RedirectType = .normal) -> Response {
        var params = ""
        var newLocation = location
        
        //TODO: include all original params
        if let ssoRedirect = try? query.get(String.self, at: "continue") {
            params = "continue=\(ssoRedirect)"
        }
        

        if !params.isEmpty {
            if location.contains("?") {
                newLocation += "&\(params)"
            } else {
                newLocation += "?\(params)"
            }
        }
        
        
        return self.redirect(to: newLocation, type: type)
    }
}
