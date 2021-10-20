---
title: Resume
layout: single-no-bar
permalink: /resume/
toc: true
---

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">

<a href="/about/assets/pdf/resume.pdf" download="2021-10-19-finney-resume.pdf">
  <button class="btn"><i class="fa fa-download"></i> Download</button>
</a>

{% assign tags = "odl ierus rmci uah-ra uah-pass" | split: " " %}

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
