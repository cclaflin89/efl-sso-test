import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let userController = UserController()
    router.get("register", use: userController.renderRegister)
    router.post("register", use: userController.register)
    router.get("login", use: userController.renderLogin)
    
    router.get("moodleLogin", use: userController.moodleLogin)
    router.get("moodleLogout", use: userController.moodleLogout)
    
    let authSessionRouter = router.grouped(User.authSessionsMiddleware())
    
    authSessionRouter.post("login", use: userController.login)
    
    let protectedRouter = authSessionRouter.grouped(SSORedirectMiddleware<User>(path: "/login"))
    protectedRouter.get("profile", use: userController.renderProfile)
    protectedRouter.get("ssoLogin", use: userController.ssoLogin)
    protectedRouter.get("ssoLogout", use: userController.ssoLogout)
    
    
    router.get("logout", use: userController.logout)
}
