---
title: Backend Application Development
date: 2026-09-17
collection: resume
resume_tag: elucid
i_order: 135
---

Responsibilities:

- build [Django](https://www.djangoproject.com/) applications for managing [RabbitMQ](https://www.rabbitmq.com/) message-broker configuration
- implement a distributed lock coordinating [Django ORM](https://docs.djangoproject.com/en/stable/topics/migrations/) database migrations, unblocking autoscaling, redundancy, and deployment process features that would otherwise have produced migration collisions — surfaced by collisions in the nightly `dev` environment, most often on bulk data migrations, where [`RunPython`](https://docs.djangoproject.com/en/stable/ref/migration-operations/#django.db.migrations.operations.RunPython) operations are not wrapped in a database transaction by default
- develop a continuous health-check monitor built on [`django-health-check`](https://github.com/codingjoe/django-health-check/), running its full set of built-in checks alongside custom checks for DICOM service availability (C-ECHO) and for external API availability via [`requests`](https://requests.readthedocs.io/)
