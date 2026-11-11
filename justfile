# ==================================================================================================
#
# Copyright (c) 2026 Ilya Snegov
#
# Dedicated to the public domain under the Creative Commons
# CC0 1.0 Universal Public Domain Dedication (the "Dedication").
# You may obtain a copy of the Dedication at
#
# https://creativecommons.org/publicdomain/zero/1.0/legalcode.en
#
# ==================================================================================================
# justfile
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Justfile Settings
# --------------------------------------------------------------------------------------------------
set dotenv-load := true
set export := true

# --------------------------------------------------------------------------------------------------
# Environment Mappings: justfile variable -> pixi environment
# --------------------------------------------------------------------------------------------------

ENV_DEFAULT     := "pixi run -e default"
ENV_SERVER      := "pixi run -e server"
ENV_WORKER_INF  := "pixi run -e worker-inference"
ENV_WORKER_DEF  := "pixi run -e worker-default"

# --------------------------------------------------------------------------------------------------
# Scripts
# --------------------------------------------------------------------------------------------------

# Generate .env from template with secure random passwords
gen-env template='local':
    {{ENV_DEFAULT}} python -m scripts.utils.init_env --template {{template}}

# Generate Redis ACL rules for Docker init
gen-acl:
    {{ENV_DEFAULT}} python -m scripts.utils.generate_redis_acl

# Generate PostgreSQL user creation script for Docker init
gen-sql:
    {{ENV_DEFAULT}} python -m scripts.utils.generate_postgres_sql

# Generate MinIO policy and init script for Docker init container
gen-minio:
    {{ENV_DEFAULT}} python -m scripts.utils.generate_minio_setup

# --------------------------------------------------------------------------------------------------
# Infrastructure
# --------------------------------------------------------------------------------------------------

# Generate new revision
db-revision message='New migration':
    {{ENV_SERVER}} alembic -c ./migrations/alembic.ini revision -m "{{message}}"

# Generate new revision with auto-detected changes
db-revision-auto message='Auto migration':
    {{ENV_SERVER}} alembic -c ./migrations/alembic.ini revision --autogenerate -m "{{message}}"

# Apply pending migrations to sync database schema
db-migrate:
    {{ENV_SERVER}} alembic -c ./migrations/alembic.ini upgrade head

# Revert the latest migration step
db-rollback:
    {{ENV_SERVER}} alembic -c ./migrations/alembic.ini downgrade -1

# --------------------------------------------------------------------------------------------------
# Runtime
# --------------------------------------------------------------------------------------------------

# Start Celery worker for ML inference
worker-inference:
    {{ENV_WORKER_INF}} python -m worker_inference.main

# Start Celery worker for general-purpose background tasks
worker-default:
    {{ENV_WORKER_DEF}} python -m worker_default.main

# Launch FastAPI server
server:
    {{ENV_SERVER}} python -m server.main

# --------------------------------------------------------------------------------------------------
# Docker Local
# --------------------------------------------------------------------------------------------------

# Start infrastructure stack to be consumed by locally running services
docker-local-up:
    {{ENV_DEFAULT}} docker compose -f docker/compose.local.yml up -d

# Stop local containers and remove anonymous volumes
docker-local-down:
    {{ENV_DEFAULT}} docker compose -f docker/compose.local.yml down --remove-orphans --volumes

# Stream combined logs from all local services
docker-local-logs:
    {{ENV_DEFAULT}} docker compose -f docker/compose.local.yml logs -f

# --------------------------------------------------------------------------------------------------
# Docker Deploy
# --------------------------------------------------------------------------------------------------

# Launch fully containerized stack with infrastructure, API server, and workers
docker-deploy-up:
    {{ENV_DEFAULT}} docker compose -f docker/compose.deploy.yml up --build -d

# Stop production containers and clean up unused networks/volumes
docker-deploy-down:
    {{ENV_DEFAULT}} docker compose -f docker/compose.deploy.yml down --remove-orphans --volumes

# Stream combined logs from all production services
docker-deploy-logs:
    {{ENV_DEFAULT}} docker compose -f docker/compose.deploy.yml logs -f

# --------------------------------------------------------------------------------------------------
# Quick Start
# --------------------------------------------------------------------------------------------------

# Start full local development environment and open Swagger in browser
quick-start-local:
    {{ENV_DEFAULT}} python -m scripts.quick_start.local

# Start full containerized deployment and open Swagger in browser
quick-start-deploy:
    {{ENV_DEFAULT}} python -m scripts.quick_start.deploy

# ==================================================================================================
