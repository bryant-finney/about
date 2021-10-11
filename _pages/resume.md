---
title: Resume
layout: single
permalink: /resume/
toc: true
---

{% for doc in site.documents %}
{% if doc.collection == "resume" %}

## {{doc.title}}

{{doc}}

{% endif %}
{% endfor %}
