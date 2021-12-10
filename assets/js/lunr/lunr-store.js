---
layout: none
---

var store = [
  {%- for doc in site.pages -%}
  {%- if doc.title != null -%}
  {%- assign author = doc.author | default: doc.authors[0] | default: doc.author -%}
  {%- assign author = site.data.authors[author] | default: author -%}
    {%- if forloop.last -%}
      {%- assign l = true -%}
    {%- endif -%}

      {%- if doc.header.teaser -%}
        {%- capture teaser -%}{{ doc.header.teaser }}{%- endcapture -%}
      {%- else -%}
        {%- assign teaser = site.teaser -%}
      {%- endif -%}
      {
        "title": {{ doc.title | jsonify }},
        "excerpt":
          {%- if site.search_full_content == true -%}
            {{ doc.content | append_author: author.name | newline_to_br |
              replace:"<br />", " " |
              replace:"</p>", " " |
              replace:"</h1>", " " |
              replace:"</h2>", " " |
              replace:"</h3>", " " |
              replace:"</h4>", " " |
              replace:"</h5>", " " |
              replace:"</h6>", " "|
              strip_markdown |
            strip_html | strip_newlines | compress_spaces | jsonify }},
          {%- else -%}
            {{ doc.content | prepend_author: author.name | newline_to_br |
              replace:"<br />", " " |
              replace:"</p>", " " |
              replace:"</h1>", " " |
              replace:"</h2>", " " |
              replace:"</h3>", " " |
              replace:"</h4>", " " |
              replace:"</h5>", " " |
              replace:"</h6>", " "|
              strip_markdown |
            strip_html | strip_newlines | compress_spaces | truncatewords: 50 | jsonify }},
          {%- endif -%}
        "categories": {{ doc.categories | jsonify }},
        "tags": {{ doc.tags | jsonify }},
        "url": {{ doc.url | relative_url | replace: '//', '/' | jsonify }},
        "teaser": {{ teaser | relative_url | replace: '//', '/' | jsonify }}
      }{%- unless forloop.last and l -%},{%- endunless -%}
  {%- endif -%}
  {%- endfor -%}]
