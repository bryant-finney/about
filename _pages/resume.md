---
title: Resume
layout: single
permalink: /resume/
toc: true
---

{% assign tags = "ierus rmci uah" | split: " " %}

{% for tag in tags %}

## {{site.data.employers[tag].name}}

{% if tag == "ierus" %}

{%- comment -%} TODO: figure this heading out (it looks weird) {%- endcomment -%}

### _SBIRs / R&D_

{% endif %}

{% assign docs = site.resume | sort: "i_order" | where: "resume_tag", tag %}
{% for doc in docs reversed %}

{{doc.level}} [{{doc.title}}]({{site.baseurl}}/{{doc.url}})
{{doc.content}}

{% endfor %}
{% endfor %}
