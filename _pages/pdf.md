---
layout: single-no-bar
title: ""
permalink: /resume/pdf/
date: 2026-05-29
---

<header class="resume-header">
  <h1>Bryant Finney</h1>
  <p class="resume-title">Principal Engineer</p>
  <p class="resume-contact">
    <a href="mailto:finneybp@gmail.com">finneybp@gmail.com</a>
    <span>Boston, MA</span>
    <a href="https://www.linkedin.com/in/bryant-finney/">LinkedIn</a>
    <a href="https://github.com/bryant-finney">GitHub</a>
  </p>
</header>

---

With more than 14 years of engineering experience across multiple industries, I bring positivity and
a growth mindset to every team I join. My passion for learning, collaboration, knowledge sharing,
and technology has equipped me to lead engineering teams to success.

---

## Skills

<div class="skill-badges" markdown="1">
{% include_relative summaries/skills.md badge-style='for-the-badge' color='8ce1ff' %}
</div>

## Work Experience

<!--
  `tags` is the full ordered employer list. `detailed` selects which of those
  also render their individual role entries (full bullets) below the summary;
  every other employer shows the summary only. To shorten or lengthen this PDF
  without touching the `/resume/` page or any role files, move tags in or out
  of `detailed`.
-->

{% assign tags = "elucid hometap morse odl-consult odl ierus rmci uah-ra uah-pass" | split: " " %}
{% assign detailed = "elucid" | split: " " %}

{% for tag in tags %}

{% include tsum.html employer=tag %}

---

{% if site.data.employers[tag].summary_file %}

{% capture summary_file %}{{ site.data.employers[tag].summary_file }}{% endcapture %}

{% include_relative {{ summary_file }} %}

{% endif %}

<!--
  `odl` (Outdoorlink, Lead Software Engineer) has no `summary_file` in
  employers.yml because the `/resume/` page renders its role entries in full.
  Include its summary here only, so the condensed PDF shows context for the
  role without adding a summary block to the `/resume/` page.
-->
{% if tag == "odl" %}

{% include_relative summaries/odl.md %}

{% endif %}

{% if detailed contains tag %}

{% assign docs = site.resume | sort: "i_order" | where: "resume_tag", tag %}
{% for doc in docs reversed %}

#### [{{doc.title}}]({{site.baseurl}}/{{doc.url}})

{{doc.content}}

{% endfor %}

{% endif %}

{% endfor %}

## Education

{% include_relative summaries/education.md h='40pt' %}

{% include_relative summaries/securityplus.md %}
