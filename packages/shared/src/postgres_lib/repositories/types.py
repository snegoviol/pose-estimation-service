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
# packages/shared/src/postgres_lib/repositories/types.py
# ==================================================================================================

from typing import TypeVar
from ..models import Base

# ==================================================================================================

ModelType = TypeVar("ModelType", bound=Base)
"""
Generic type variable representing any SQLAlchemy ORM model inheriting from Base.

Used to parameterize repository and service interfaces while preserving static
type safety across different entity types. The bound constraint restricts valid
substitutions to subclasses of the application declarative base.
"""

# ==================================================================================================
