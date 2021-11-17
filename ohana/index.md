---
layout: archive
title: Ohana
---
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

{% assign ohana_pages = site.pages | where_exp: "item", "item.layout == 'use-case'" %}

{% for use_case in ohana_pages %}
<div>
	<h2><a href="{{ use_case.url }}">{{ use_case.title }}</a></h2>
</div>
{% endfor %}
