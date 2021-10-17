---
title: Blog Posts
layout: single
permalink: /blog/
category: blog
entries_layout: grid
classes: wide
author_profile: true
---

{% if paginator %}
{% assign posts = paginator.posts %}
{% else %}
{% assign posts = site.posts %}
{% endif %}

## Fun

{% assign entries_layout = page.entries_layout | default: 'list' %}
{% assign fun_posts = posts | where:"categories","fun" %}

<div class="entries-{{ entries_layout }}">
  {% for post in fun_posts %}
    {% include archive-single.html type=entries_layout %}
  {% endfor %}
</div>

{% include paginator.html %}
