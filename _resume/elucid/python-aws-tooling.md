---
title: Python AWS Tooling
date: 2026-10-20
collection: resume
resume_tag: elucid
i_order: 138
---

Responsibilities:

- build Python CLI tools on [Typer](https://typer.tiangolo.com/) and [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) for controlling AWS resources through the AWS API, used by the platform team for release and deployment operations and by release managers to create new releases, backing the larger utilities with [`pytest`](https://docs.pytest.org/) test suites
- build a Typer CLI for running [Locust](https://locust.io/) load tests, distributed as a single-file executable with [uv](https://docs.astral.sh/uv/)
- author and maintain [`config-ninja`](https://github.com/config-ninja/config-ninja), an open-source Python agent published to [PyPI](https://pypi.org/project/config-ninja/) and built for Elucid's platform, which renders [Jinja2](https://jinja.palletsprojects.com/) configuration-file templates from [AWS AppConfig](https://docs.aws.amazon.com/appconfig/) data and runs as a `systemd` service
- set up an internal PyPI registry and publish the platform's health-check monitor Django application to it
