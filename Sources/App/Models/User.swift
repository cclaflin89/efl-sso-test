import FluentSQLite
import Vapor
import Authentication
import JWT

final class User: SQLiteModel {
    var id: Int?
    var email: String
    var password: String
    var firstname: String
    var lastname: String
    
    init(id: Int? = nil, email: String, password: String, firstname: String, lastname: String) {
        self.id = id
        self.email = email
        self.password = password
        self.firstname = firstname
        self.lastname = lastname
    }
    
    struct LoginData : Decodable {
        let email: String
        let password: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.email = try container.decode(String.self, forKey: .email).lowercased()
            self.password = try container.decode(String.self, forKey: .password)
        }
        
        enum CodingKeys: String, CodingKey {
            case email
            case password
        }
    }
}
extension User: Content {}
extension User: Migration {}


extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \User.email
    }
    
    static var passwordKey: WritableKeyPath<User, String> {
        return \User.password
    }
    
    
}

extension User: SessionAuthenticatable {
    
}

extension User: JWTPayload {
    func verify(using signer: JWTSigner) throws {
        
    }
}

extension User {
    // Rest formatted string used for moodle auth_userkey request
    var restFormatString: String {
        //if username exists, sso login fails
        var username: String
        if let userID = try? self.requireID() {
            username = "\(firstname)\(userID)".lowercased()
        } else {
            username = "\(firstname)_\(lastname)".lowercased()
        }
        
        return "user[firstname]=\(firstname)" +
        "&user[lastname]=\(lastname)" +
        "&user[email]=\(email)" +
        "&user[username]=\(username)"
    }
    
    //        let user = DummyUser(email: "cclaflin89@googlemail.com", firstname: "Chris", lastname: "Claflin", username: "cclaflin")
    //        let userInfo = MoodleAuthKeyParam(user: user)
    
    //        let userInfo = ["user[email]": "cclaflin89@googlemail.com", "user[firstname]": "Chris", "user[lastname]": "Claflin", "user[username]": "cclaflin"]
    
    
    //        let userInfo = "Array ( [user] => Array ( [firstname] => chris [lastname] => claflin [username] => cclaflin [email] => cclaflin89@googlemail.com ) ) "
    
    //        let userInfo = ["user": ["email": "cclaflin89@googlemail.com", "firstname": "Chris", "lastname": "Claflin", "username": "cclaflin"]]

}
