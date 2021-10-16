---
title: Resume
layout: single-no-bar
permalink: /resume/
toc: true
---

{% assign tags = "ierus rmci uah-ra uah-pass" | split: " " %}

{% for tag in tags %}

## {{site.data.employers[tag].name}}

<div class="row">

<div class="left-col" markdown=1>

<table>
<colgroup>
<col width="30%" />
<col width="70%" />
</colgroup>
<thead><th/><th/></thead>
<tbody>
{% include trow.html label='name' employer=tag %}
{% include trow.html label='title' employer=tag %}
{% include trow.html label='start' employer=tag %}
{% include trow.html label='end' employer=tag %}
{% include trow.html label='site' employer=tag %}
</tbody>
</table>

</div>
<div class="right-col" markdown=1>

{% assign docs = site.resume | sort: "i_order" | where: "resume_tag", tag %}
{% for doc in docs reversed %}

### [{{doc.title}}]({{site.baseurl}}/{{doc.url}})

{{doc.content}}

{% endfor %}

</div>
</div>

{% endfor %}