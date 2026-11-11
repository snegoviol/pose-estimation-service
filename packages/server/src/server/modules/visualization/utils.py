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
# packages/server/src/server/modules/visualization/utils.py
# ==================================================================================================

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from postgres_lib import Visualization, VisualizationRepository

# ==================================================================================================

async def get_visualization_or_404(
    session: AsyncSession,
    visualization_id: int,
) -> Visualization:
    """
    Fetch a visualization record by primary key or raise a 404 HTTP exception.

    Utility function to consolidate the common pattern of looking up a
    visualization by its database identifier and returning a standardized
    Not Found response when the record does not exist.

    Parameters
    ----------
    session : AsyncSession
        Active async database session bound to the current transaction.
    visualization_id : int
        Primary key of the target visualization record in the visualizations table.

    Returns
    -------
    Visualization
        ORM instance of the requested visualization record.

    Raises
    ------
    HTTPException
        404 Not Found with a standardized detail message if the visualization
        ID does not exist in the database.
    """
    visualization = await VisualizationRepository.get_by_id(session, visualization_id)
    if visualization is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Visualization record not found in the database.",
        )
    return visualization

# ==================================================================================================
