---
layout: archive
title: Use Cases
---

{% assign case_pages = site.pages | where_exp: "item", "item.layout == 'category'" %}

{% for pg in case_pages %}
{% assign child_pages = site.pages | where_exp:"item", "item.categories contains pg.children" %}
 {% if child_pages.size > 0 %}
 - [{{ pg.title }}]({{ pg.url }}) ({{ child_pages | size }})
 {% endif %}

{% endfor %}
