# ==================================================================================================
# 
# Copyright (c) 2026 Ilya Snegov
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# ==================================================================================================
# packages/server/src/server/modules/health/shallow/routes.py
# ==================================================================================================

from fastapi import status
from .schemas import ShallowHealthResponse, ServiceStatus
from ..router import health_router

# ==================================================================================================

@health_router.get(
    "/shallow/",
    status_code=status.HTTP_200_OK,
    response_model=ShallowHealthResponse,
    summary="Shallow health check",
    description="Returns the availability status of the application.",
)
async def shallow_health_route() -> ShallowHealthResponse:
    """
    Provide a lightweight process liveness probe.

    Returns an immediate success response without inspecting external
    dependencies or internal state. Designed for fast liveness checks
    used by orchestrators and load balancers to verify that the web
    server process is running and accepting HTTP requests.
    """
    return ShallowHealthResponse(status=ServiceStatus.OK)

# ==================================================================================================
