from __future__ import annotations

import time
from collections import defaultdict, deque
from collections.abc import Awaitable, Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Small in-memory rate limiter for local/demo deployments.

    Production should replace this with Redis-backed rate limiting at the API
    gateway or reverse proxy layer so limits work across multiple workers.
    """

    def __init__(self, app, max_requests: int = 180, window_seconds: int = 60):
        super().__init__(app)
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: dict[str, deque[float]] = defaultdict(deque)

    async def dispatch(self, request: Request, call_next: Callable[[Request], Awaitable[Response]]) -> Response:
        if request.url.path in {"/api/health", "/docs", "/openapi.json"}:
            return await call_next(request)
        key = request.client.host if request.client else "unknown"
        now = time.time()
        bucket = self.requests[key]
        while bucket and bucket[0] <= now - self.window_seconds:
            bucket.popleft()
        if len(bucket) >= self.max_requests:
            return Response("Rate limit exceeded", status_code=429)
        bucket.append(now)
        return await call_next(request)
