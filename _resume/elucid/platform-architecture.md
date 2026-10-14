---
title: Platform Architecture
date: 2026-05-28
collection: resume
resume_tag: elucid
i_order: 140
---

Responsibilities:

- lead the design and implementation of an
  [AWS ECS](https://aws.amazon.com/ecs/)-based containerization platform for the company's arterial
  analysis software, reducing production deployment time from hours to under five minutes
- architect Docker images for the platform's GPU workloads: [PyTorch](https://pytorch.org/) inference models with [CUDA](https://developer.nvidia.com/cuda-toolkit) support, and a C++ rendering service built on [VTK](https://vtk.org/), EGL/OpenGL, and the CUDA runtime
- author the reference Docker image for the platform's Python/Django backend, then lead development of the C++ build and runtime images for processing and rendering CT imagery
- design GitHub Actions workflows that build the C++ images and test them on GPU runners
- architect a cross-region warm-standby disaster recovery footprint, defining the
  [Terraform IaC](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code)
  patterns for network, compute, storage, and identity layers
- design asynchronous task-processing infrastructure for backend services, introducing managed
  message brokering and dedicated worker tiers to support scalable, long-running workloads
- develop the [HTCondor](https://htcondor.org/) cluster that schedules inference and rendering jobs onto auto-scaling GPU instance pools
- guide the evolution of the company's service-based architecture, partnering with engineering
  leaders to navigate organizational and technical trade-offs
- build GPU-enabled base [AMIs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) with [EC2 Image Builder](https://aws.amazon.com/image-builder/), and establish cross-account, multi-region distribution patterns for AMIs and container images, decoupling build pipelines from deployment topology
- own multi-account cost management for over eighty environments serving six product development
  teams, balancing engineering velocity with budget accountability
- develop DICOM interoperability and performance-testing tools, including a cross-platform C-ECHO
  service class user and a Python-based load-testing harness for DICOM service class providers
