---
title: Resume
layout: single-no-bar
permalink: /resume/
toc: true
date: 2023-09-02
---

<a href="/about/assets/pdf/{{page.date}}-resume.pdf" download="{{page.date}}-finney-resume.pdf">
  <button class="btn"><i class="fa fa-download"></i> Download: PDF ({{page.date}})</button>
</a>

# Skills

{% include_relative summaries/skills.md badge-style='for-the-badge' color='000d63' %}

# Work Experience

{% assign tags = "hometap morse odl-consult odl ierus rmci uah-ra uah-pass" | split: " " %}

{% for tag in tags %}

{{site.data.employers[tag].name}}

<div class="row">

<div class="left-col" markdown=1>

<table>
<colgroup>
<col width="30%" />
<col width="70%" />
</colgroup>
<thead>{{site.data.employers[tag].logo}}</thead>
<tbody>
{% include trow.html label='title' employer=tag %}
{% include trow.html label='start' employer=tag %}
{% include trow.html label='end' employer=tag %}
{% include trow.html label='site' employer=tag %}
</tbody>
</table>

</div>
<div class="right-col" markdown=1>

{% if site.data.employers[tag].summary_file %}
{% capture summary_file %}{{ site.data.employers[tag].summary_file }}{% endcapture %}

### Summary

{% include_relative {{ summary_file }} %}
{% endif %}

{% assign docs = site.resume | sort: "i_order" | where: "resume_tag", tag %}
{% for doc in docs reversed %}

### [{{doc.title}}]({{site.baseurl}}/{{doc.url}})

{{doc.content}}

{% endfor %}

</div>
</div>

{% endfor %}

# Education

{% include_relative summaries/education.md h='80pt' %}

{% include_relative summaries/securityplus.md %}
