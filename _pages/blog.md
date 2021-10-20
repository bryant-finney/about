---
title: Blog Posts
layout: single
permalink: /blog/
category: blog
classes: wide
author_profile: true
categories:
  - fun
  - tech
---

{% if paginator %}
{% assign posts = paginator.posts %}
{% else %}
{% assign posts = site.posts %}
{% endif %}

{% assign entries_layout = page.entries_layout | default: 'list' %}
{% assign fun_posts = posts | where:"categories","fun" %}
{% assign tech_posts = posts | where:"categories","tech" %}

## Technical

<div class="entries-{{ entries_layout }}">
  {% for post in tech_posts %}
    {% include archive-single.html type=entries_layout %}
  {% endfor %}
</div>

## Fun

<div class="entries-{{ entries_layout }}">
  {% for post in fun_posts %}
    {% include archive-single.html type=entries_layout %}
  {% endfor %}
</div>

{% include paginator.html %}
