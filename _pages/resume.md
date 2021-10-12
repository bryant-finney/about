---
title: Resume
layout: single
permalink: /resume/
toc: true
---

{% for doc in site.documents reversed %}
{% if doc.collection == "resume" %}

## {{doc.title}}

{{doc.content}}

{% endif %}
{% endfor %}
