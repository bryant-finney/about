---
title: Resume
layout: single
permalink: /resume/
toc: true
---

{% assign tags = "ierus rmci uah" | split: " " %}

{% for tag in tags %}

## {{site.data.employers[tag].name}}

{% assign docs = site.resume | sort: "i_order" | where: "resume_tag", tag %}
{% for doc in docs reversed %}

{{doc.position}}

### {{doc.title}}

{{doc.content}}

{% endfor %}
{% endfor %}
