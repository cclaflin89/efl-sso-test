import Vapor
import FluentSQL
import Crypto
import JWT
import HTTP

final class UserController {
    
    func renderRegister(_ req: Request) throws -> Future<View> {
        return try req.view().render("register")
    }
    
    func renderLogin(_ req: Request) throws-> Future<View> {
        return try req.view().render("login")
    }
    
    func ssoLogin(_ req: Request) throws -> Future<Response> {
        
        if try req.isAuthenticated(User.self) {
            print("already authenticated")
        }
        
        if let session = try? req.session(), let ssoContinue = session["continue"] {
            try req.session()["continue"] = nil
            
            return Future.map(on: req) {
                if let token = try self.generateJWTToken(req) {
                    return req.redirect(to: "\(ssoContinue)?ssoToken=\(token)")
                } else {
                    return req.redirect(to: ssoContinue)
                }
            }
        }
        
        return Future.map(on: req) {
            req.redirect(to: "/profile")
        }
    }
    
    func ssoLogout(_ req: Request) throws -> Future<Response> {
        print("ssoLogout")
        
        try req.unauthenticateSession(User.self)
        
        if let ssoContinue = try? req.query.get(String.self, at: "continue") {
            return Future.map(on: req) {
                req.redirect(to: ssoContinue)
            }
        } else {
            return Future.map(on: req) {
                req.redirect(to: "/login")
            }
        }
    }
    

    private func generateJWTToken(_ req: Request) throws -> String? {
        let user = try req.requireAuthenticated(User.self)
        
        let data = try JWT(payload: user).sign(using: .hs256(key: "secret"))
        
        print("jwt token:", data)
        
        return String(data: data, encoding: .utf8) ?? nil
    }
    
    
    func login(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.LoginData.self).flatMap { login in
            return User.authenticate(username: login.email, password: login.password, using: BCryptDigest(), on: req).flatMap { user in
                guard let user = user else {
                    return Future.map(on: req) {
                      req.redirect(to: "/login")
                    }
                }
                
                try req.authenticateSession(user)
                
                if let session = try? req.session() {
                    
//                    if let ssoContinue = session["continue"] {
//                        if let token = try self.generateJWTToken(req) {
//                            return req.redirect(to: "\(ssoContinue)?ssoToken=\(token)")
//                        } else {
//                            return req.redirect(to: ssoContinue)
//                        }
//                    }
                    
                    if let _ = session["sso_login"] {
                        let ssoReturnTo = session["sso_return_to"]
                        
                        if ssoReturnTo == "moodle_training_efl" {
                            
                            session["sso_return_to"] = nil
                            session["sso_login"] = nil
                            
                            return try self.redirectToMoodle(req)
                        }
                    }
                }

                return Future.map(on: req) {
                    req.redirect(to: "/profile")
                }
                
            }
        }
    }
    
    func register(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap{ user in
            return User.query(on: req).filter(\User.email == user.email).first().flatMap{ result in
                if let _ = result {
                    return Future.map(on: req) {
                        return req.redirect(to: "/register")
                    }
                }
                
                user.password = try BCryptDigest().hash(user.password)
                
                return user.save(on: req).map{ _ in
                    return req.redirect(to: "/login")
                }
            }
        }
    }
    
    
    
    func renderProfile(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        
        return try req.view().render("profile", ["user": user])
    }
    
    func logout(_ req: Request) throws -> Future<Response> {
        try req.unauthenticateSession(User.self)
        
        return Future.map(on: req) {
            return req.redirect(to: "/login")
        }
    }
    
    // MARK: Moodle SSO Login
    
    func moodleLogin(_ req: Request) throws -> Future<Response> {
        if let _ = try? req.requireAuthenticated(User.self) {
            return try redirectToMoodle(req)
        } else {
            let session = try req.session()
            session["sso_login"] = "true"
            session["sso_return_to"] = "moodle_training_efl"
            
            return Future.map(on: req) {
                return req.redirect(to: "/login")
            }
        }
    }
    
    func moodleLogout(_ req: Request) throws -> Future<Response> {
        try? req.unauthenticateSession(User.self)
        
        return Future.map(on: req) {
            return req.redirect(to: "https://training-dev.eflapp.com")
        }
    }
    
    // called after user sign
    func redirectToMoodle(_ req: Request) throws -> Future<Response> {
        let client = try req.client()
        let user = try req.requireAuthenticated(User.self)
        
        struct MoodleAuthKeyResponse : Content {
            let loginurl: String
        }
        
//        return try req.content.decode(User.self).flatMap { user in
            return client.post("https://training-dev.eflapp.com/webservice/rest/server.php?wstoken=8bed711b28b2f6a9b3674d53776895b2&wsfunction=auth_userkey_request_login_url&moodlewsrestformat=json") { (req) in
                try req.content.encode(user.restFormatString)
                req.http.headers = [
                    "Content-Type": "application/x-www-form-urlencoded"
                ]
                
                print(req.content)
                
                }.flatMap{ response -> Future<Response> in
                    print(response.http.body)
                    
                    return try response.content.decode(MoodleAuthKeyResponse.self).flatMap { response -> Future<Response> in
                        print(response.loginurl)
                        
                        return Future.map(on: req) {
                            return req.redirect(to: response.loginurl)
                        }
                    }
            }
//        }
        
        
    }
}
