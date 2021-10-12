---
layout: archive
title: "Sitemap"
permalink: /sitemap/
author_profile: false
---

A list of all the posts and pages found on the site. For you robots out there is an
[XML version]({{ "sitemap.xml" | relative_url }}) available for digesting as well.

## Pages

<hr>

{% assign pages = site.pages | sort: "title" %}

<ul class="articles-list">
{% for page in pages %}
    {% if page.title.size > 0 %}
        <li> <a href="{{site.baseurl}}{{page.url}}">{{page.title}}</a></li>
    {% endif %}
{% endfor %}
</ul>

## Posts

<hr>

{% assign posts = site.posts | sort: "date" %}

{% for post in posts %}

- [{{post.title}}]({{site.baseurl}}{{post.url}})

{% endfor %}

## Collections

<hr>

{% assign collections = site.collections | sort: "collection" %}
{% for collection in collections %}
{% if collection.output == false or collection.label == "posts" %}
{% continue %}
{% endif %}
{% capture label %}{{ collection.label }}{% endcapture %}
{% unless label == written_label %}

- ### [{{ label | capitalize }}]({{site.baseurl}}/{{label}})

{% capture written_label %}{{ label }}{% endcapture %}
{% endunless %}
{% assign docs = collection.docs | sort: "i_order" %}
{% for doc in collection.docs reversed %}
{% unless collection.output == false or collection.label == "posts" %}

    - [{{doc.title}}]({{site.baseurl}}{{doc.url}})

{% endunless %}
{% endfor %}

{% endfor %}
