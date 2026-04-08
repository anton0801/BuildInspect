import Foundation

typealias MiddlewareNext = (AppRequest, RequestContext) async -> AppResponse

protocol Middleware {
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse
}

final class MiddlewareChain {
    private var middlewares: [Middleware] = []
    private let finalHandler: (AppRequest, RequestContext) async -> AppResponse
    
    init(finalHandler: @escaping (AppRequest, RequestContext) async -> AppResponse) {
        self.finalHandler = finalHandler
    }
    
    func use(_ middleware: Middleware) {
        middlewares.append(middleware)
    }
    
    func execute(request: AppRequest, context: RequestContext) async -> AppResponse {
        await executeChain(at: 0, request: request, context: context)
    }
    
    private func executeChain(
        at index: Int,
        request: AppRequest,
        context: RequestContext
    ) async -> AppResponse {
        if index >= middlewares.count {
            return await finalHandler(request, context)
        }
        
        let middleware = middlewares[index]
        
        let next: MiddlewareNext = { [weak self] req, ctx in
            guard let self = self else {
                return .error(MiddlewareError.invalidData)
            }
            return await self.executeChain(at: index + 1, request: req, context: ctx)
        }
        
        return await middleware.handle(request: request, context: context, next: next)
    }
}
