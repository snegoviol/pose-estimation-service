<!--    
    ================================================================================================
    
    Copyright (c) 2026 Ilya Snegov
    
    Dedicated to the public domain under the Creative Commons
    CC0 1.0 Universal Public Domain Dedication (the "Dedication").
    You may obtain a copy of the Dedication at
    
    https://creativecommons.org/publicdomain/zero/1.0/legalcode.en

    ================================================================================================
    README.md
    ================================================================================================
-->

# Human Pose Estimation Service

> *Production-oriented REST API service exposing `ensam3d_inference` as a managed backend for distributed 3D human pose estimation, with video ingestion, GPU worker orchestration, annotated visualization rendering, and persistent artifact storage.*

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](#license)
[![License: CC0-1.0](https://img.shields.io/badge/License-CC0--1.0-blue.svg)](#license)

> [!NOTE]  
> This repository is one of two that form the foundation of my Bachelor's thesis on production-ready, scalable 3D human pose estimation. The system is split into two layers:
>
> | Repository | Focus |
> | :--- | :--- |
> | [**Enhanced SAM 3D Body Library**](https://github.com/snegoviol/ensam3d-lib) | Core inference engine: a high-throughput, production-ready reimplementation of the SAM 3D Body architecture. |
> | [**Human Pose Estimation Service**](https://github.com/snegoviol/pose-estimation-service) <br>*(you are here)* | Distributed backend: REST API, GPU/CPU worker orchestration, and persistent artifact storage. |
>
> Since this work is part of a thesis, both repositories include detailed documentation: architectural justifications, C4 diagrams, and empirical benchmarks. These materials were also adapted for the thesis text.
> - [Inference engine documentation](https://github.com/snegoviol/ensam3d-lib/blob/main/docs/ensam3d_inference/README.md)
> - [Service documentation](docs/README.md)

<!--    
    ================================================================================================
-->

## Performance Benchmark

End-to-end performance under concurrent load is summarized below using a parallel-pipeline benchmark — ten videos of mixed resolution and size submitted simultaneously, each running independently through ingestion, estimation, and visualization.

**Configuration**

| | |
|------------------------------|-------------------------------------------------------------|
| Workload                     | 10 videos submitted simultaneously                          |
| Video Resolutions            | 720p – 4K                                                   |
| Video Sizes                  | 3.27 MB – 77.51 MB                                          |
| CPU                          | AMD Ryzen 7 5800H with Radeon Graphics                      |
| GPU                          | NVIDIA GeForce RTX 3070 Laptop GPU                          |
| PyTorch Version              | 2.5.1.post306                                               |
| CUDA Version                 | 12.6                                                        |
| Inference Workers            | 2 (solo pool, CUDA, concurrency 1)                          |
| Post-processing Workers      | 1 (prefork pool, CPU, concurrency 4)                        |

**Results**

| | |
|----------------------------|------------|
| Total Videos Processed     | 10         |
| Wall-Clock Time            | 135.68 sec |
| Summed Stage Times         | 863.15 sec |
| Parallelism Ratio          | 6.36x      |

> **Want more details?**  
> For the full technical documentation — including conceptual design, requirements, runtime concurrency, the domain model, per-endpoint request lifecycles, the dependency stack, project structure, and performance benchmarks — see [the documentation](./docs/README.md).

<!--    
    ================================================================================================
-->

## Project Structure at a Glance

```sh
pose-estimation-service/
├── packages/               # Monorepo root: all independently deployable
│   │                       # Python modules and shared libraries. Each
│   │                       # package uses the standard `src/` layout
│   │                       # (e.g. `packages/server/src/server/`).
│   │
│   ├── server/             # FastAPI app: HTTP routing, request
│   │                       # validation, database interactions, and
│   │                       # task delegation to the workers.
│   │
│   ├── worker-inference/   # Dedicated GPU worker running heavy ML
│   │                       # inference via the `ensam3d_inference` engine.
│   │
│   ├── worker-default/     # General-purpose CPU worker running background
│   │                       # post-processing pipelines (currently:
│   │                       # rendering annotated video overlays and
│   │                       # persisting media assets to S3).
│   │
│   ├── shared/             # Cross-process shared infrastructure: base
│   │                       # configs and unified client abstractions for
│   │                       # external services (PostgreSQL, Redis,
│   │                       # MinIO/S3), and more.
│   │
│   ├── scripts/            # Standalone automation scripts: environment
│   │                       # bootstrapping, infrastructure init, and
│   │                       # auxiliary tasks (e.g. OpenAPI schema export).
│   │
│   └── benchmarks/         # Performance testing suite: endpoint latency,
│                           # pipeline throughput, and parallel
│                           # processing efficiency.
│
├── docker/                 # Docker Compose stacks for local
│                           # (infrastructure-only) and deploy
│                           # (fully containerized) modes.
│
├── config/                 # Environment variable templates for local
│                           # and deploy modes.
│
├── migrations/             # Alembic migration environment and database
│                           # schema change scripts.
│
├── docs/                   # Technical documentation: conceptual overview,
│                           # domain model, runtime architecture,
│                           # engineering decisions, API design, codebase
│                           # layout, and dependencies.
│
├── LICENSES/               # Full texts of all licenses used in the project.
│
├── LICENSE.txt             # Licensing overview: which license applies to which files.
│
├── pixi.toml               # Pixi configuration defining feature-based
│                           # dependency groups for server, workers, and
│                           # ML inference.
│
├── pixi.lock               # Fully resolved, reproducible dependency
│                           # lockfile.
│
└── justfile                # Task runner: bootstrap commands, database
                            # migration targets, runtime process launchers,
                            # and Docker Compose shortcuts. Automatically
                            # manages the pixi environment per recipe.
```

<!--    
    ================================================================================================
-->

## Quick Start

### I. Prerequisites

| **Category** | **Component**               | **Requirement**                        |
| :----------- | :-------------------------- | :------------------------------------- |
| **Hardware** | **CPU**                     | Supports `x86_64` architecture         |
|              | **GPU**                     | Supports `NVIDIA CUDA`                 |
| **Software** | **Operating System**        | `GNU/Linux`-based                      |
|              | **NVIDIA Driver**           | Supports `NVIDIA CUDA Toolkit >= 12.8` |
|              | **Package Management Tool** | [`Pixi`](https://pixi.prefix.dev/latest/#installation) |
|              | **Container Tool**          | [`Docker`](https://docs.docker.com/engine/install/) |

> **Note: on these prerequisites**  
> These are not strict requirements, but rather the baseline environment where the code is 
guaranteed to run out of the box. Alternative setups are possible but may require manual 
configuration.

> **Note: on CUDA versions**  
> The `>= 12.8` constraint is enforced via Pixi's `system-requirements`, reflecting the default 
PyTorch CUDA build at the time of development. Newer driver versions are fully supported.

> **Note: the benchmarking and profiling scripts report**  
> `CUDA Version: 12.6`. This is expected and not a mismatch: that value comes from `torch.version.cuda`, 
i.e. the CUDA version the PyTorch binary was *compiled against*, which is independent of the newer CUDA 
toolkit resolved into the environment. CUDA minor-version compatibility lets a 12.6 build run on 
any 12.x driver with the same major version.

<!--    
    ================================================================================================
-->

### II. Setup

1. **Clone the repository**

    ```sh
    git clone https://github.com/snegoviol/pose-estimation-service.git
    cd pose-estimation-service
    ```

2. **Install dependencies**

    ```sh
    pixi install
    ```

3. **Activate environment**

    ```sh
    pixi shell
    ```

<!--    
    ================================================================================================
-->

### III. Model Weights Access

To perform pose estimation, the service requires the `sam-3d-body-vith` model weights, which are hosted on Hugging Face under restricted access. To obtain them:

1. Navigate to the [facebook/sam-3d-body-vith](https://huggingface.co/facebook/sam-3d-body-vith) repository.
2. Sign in with a Hugging Face account, request access to the repository, and wait for approval.
3. Once access is granted, download the weights manually and place the downloaded `sam-3d-body-vith/` directory in the project root.

    ```sh
    # Expected structure after download:
    pose-estimation-service/
    ├── packages/ 
    ├── docker/
    ├── config/
    ├── migrations/
    ├── pixi.toml
    ├── pixi.lock
    ├── justfile
    └── sam-3d-body-vith/
    ```

<!--    
    ================================================================================================
-->

### IV. Launch

Once the environment is activated and model weights are downloaded, the service can be launched in one of two modes depending on the deployment context.

1. **Local mode** — infrastructure services run in Docker; the API server and workers run on the host machine directly.

    ```sh
    just quick-start-local
    ```

2. **Deploy mode** — the full stack runs in Docker, including infrastructure, API server, and both worker processes.

    ```sh
    just quick-start-deploy
    ```

    > **Note:**  
    > Deploy mode requires [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) to expose the GPU to the `worker-inference` container.

Whichever mode you choose, the launch script will automatically execute all necessary setup steps, start the server, and open the Swagger UI in your default web browser once the API is ready.

> **Want to see what happens under the hood?**  
> The launch scripts are fully documented with step-by-step comments explaining each action. You can find them here:
> - [Local mode script](./packages/scripts/src/scripts/quick_start/local.py)
> - [Deploy mode script](./packages/scripts/src/scripts/quick_start/deploy.py)

<!--    
    ================================================================================================
-->

### V. Cleanup

When you are done, shut down the running services depending on the active launch mode.

1. **Local mode** — stop the API server and workers by terminating their terminal processes, then bring down the infrastructure containers.

    ```sh
    just docker-local-down
    ```

2. **Deploy mode** — stop and remove all containers with a single command.

    ```sh
    just docker-deploy-down
    ```

<!--    
    ================================================================================================
-->

## License

Each file in this repository is licensed under one of the following licenses:

- [Apache License, Version 2.0](LICENSES/Apache-2.0.txt),
- [Creative Commons CC0 1.0 Universal Public Domain Dedication](LICENSES/CC0-1.0.txt).

The applicable license is stated in the header comment of each file. 
See [LICENSE.txt](LICENSE.txt) for details.

<!--    
    ================================================================================================
-->
