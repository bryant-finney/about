---
layout: single-no-bar
title: ""
permalink: /resume/pdf/
date: 2023-09-20
---

With more than 10 years of engineering experience across multiple industries, I bring positivity and
a growth mindset to every team I join. My passion for learning, collaboration, knowledge sharing,
and technology has equipped me to lead engineering teams to success.

---

## Skills

{% include_relative summaries/skills.md badge-style='for-the-badge' color='8ce1ff' %}

## Work Experience

{% assign tags = "hometap morse odl-consult odl" | split: " " %}

{% for tag in tags %}

{% include tsum.html employer=tag %}

---

{% if site.data.employers[tag].summary_file %}

{% capture summary_file %}{{ site.data.employers[tag].summary_file }}{% endcapture %}

{% include_relative {{ summary_file }} %}

{% endif %}

{% assign docs = site.resume | sort: "i_order" | where: "resume_tag", tag %}
{% for doc in docs reversed %}

#### [{{doc.title}}]({{site.baseurl}}/{{doc.url}})

{{doc.content}}

{% endfor %}

{% endfor %}

{% assign tags = "ierus rmci uah-ra uah-pass" | split: " " %}

{% for tag in tags %}

{% if tag == 'rmci' %}
<br/>
<br/>
<br/>
{% endif %}

{% include tsum.html employer=tag %}

---

{% if site.data.employers[tag].summary_file %}

{% capture summary_file %}{{ site.data.employers[tag].summary_file }}{% endcapture %}

{% include_relative {{ summary_file }} %}

{% endif %}

{% endfor %}

## Education

{% include_relative summaries/education.md h='80pt' %}

{% include_relative summaries/securityplus.md %}
