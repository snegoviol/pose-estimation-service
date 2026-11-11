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
# packages/server/src/server/modules/video/__init__.py
# ==================================================================================================

from .router import video_router
from .ingest import ingest_video_route
from .get import list_videos_route, get_video_route
from .download import download_video_route
from .delete import delete_video_route

# ==================================================================================================
