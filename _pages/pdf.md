---
layout: single-no-bar
title: Bryant Finney
permalink: /pdf/
date: 2023-09-02
js:
  - https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js
  - https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js
---

With more than 10 years of engineering experience across multiple industries, I bring positivity and
a growth mindset to every team I join. My passion for learning, collaboration, knowledge sharing,
and technology has equipped me to lead engineering teams to success.

---

## Skills

![docker](https://img.shields.io/badge/docker-4902ff?style=for-the-badge)
![python](https://img.shields.io/badge/python-4902ff?style=for-the-badge)
![terraform](https://img.shields.io/badge/terraform-4902ff?style=for-the-badge)
![java](https://img.shields.io/badge/java-4902ff?style=for-the-badge)
![C](https://img.shields.io/badge/c-4902ff?style=for-the-badge)
![javascript](https://img.shields.io/badge/javascript-4902ff?style=for-the-badge)
![Amazon Web Services (AWS)](https://img.shields.io/badge/Amazon_Web_Services_%28AWS%29-4902ff?style=for-the-badge)
![software architecture](https://img.shields.io/badge/software_architecture-4902ff?style=for-the-badge)
![REST](https://img.shields.io/badge/REST-4902ff?style=for-the-badge)
![graphql](https://img.shields.io/badge/graphql-4902ff?style=for-the-badge)
![microservices](https://img.shields.io/badge/microservices-4902ff?style=for-the-badge)
![networking](https://img.shields.io/badge/networking-4902ff?style=for-the-badge)
![CI/CD](https://img.shields.io/badge/CI/CD-4902ff?style=for-the-badge)
![agile](https://img.shields.io/badge/agile-4902ff?style=for-the-badge)
![database design](https://img.shields.io/badge/database_design-4902ff?style=for-the-badge)
![django](https://img.shields.io/badge/django-4902ff?style=for-the-badge)
![celery](https://img.shields.io/badge/celery-4902ff?style=for-the-badge)
![redis](https://img.shields.io/badge/redis-4902ff?style=for-the-badge)
![fastapi](https://img.shields.io/badge/fastapi-4902ff?style=for-the-badge)
![mysql](https://img.shields.io/badge/mysql-4902ff?style=for-the-badge)
![postgres](https://img.shields.io/badge/postgres-4902ff?style=for-the-badge)
![cybersecurity](https://img.shields.io/badge/cybersecurity-4902ff?style=for-the-badge)
![automation](https://img.shields.io/badge/automation-4902ff?style=for-the-badge)
![linux](https://img.shields.io/badge/linux-4902ff?style=for-the-badge)
![git](https://img.shields.io/badge/git-4902ff?style=for-the-badge)
![shell scripting](https://img.shields.io/badge/shell_scripting-4902ff?style=for-the-badge)
![systems administration](https://img.shields.io/badge/systems_administration-4902ff?style=for-the-badge)
![react](https://img.shields.io/badge/react-4902ff?style=for-the-badge)
![html](https://img.shields.io/badge/html-4902ff?style=for-the-badge)
![css](https://img.shields.io/badge/css-4902ff?style=for-the-badge)

## Work Experience

{% assign tags = "hometap morse odl-consult odl" | split: " " %}

{% for tag in tags %}

{% include tsum.html employer=tag %}

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

## Education

{% include_relative summaries/education.md h='80pt' %}

{% include_relative summaries/securityplus.md %}
