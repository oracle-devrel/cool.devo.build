An OHANA use case is a directory containing 7 files, 1 index and 6 paths (3 paths with and without CI/CD option). 

At this time the main index page is generated from all index files in these directories. This may be converted to a YAML list in order to better control ordering and presentation, but this will have no effect on the requirements outlined here.

The directory should be a slugified (lowercase, no punctuation, hyphens instead of spaces) version of the use case name, e.g. "Web Application" would be "web-application".

Each directory must contain an `index.md` file. The `index.md` for the use case should contain the following front matter:

```yaml
---
layout: use-case
title: Web Application
description: Lorem ipsum dolor sit amet...
---
```

No content is necessary, and a nav menu will be built automatically. All it needs is the layout `use-case`, a title, and a description.

Each use case is expected to have the following markdown files (henceforth referred to as "paths") in its directory:

- diy.md
- diy-ci.md
- mix.md
- mix-ci.md
- managed.md
- managed-ci.md

The nav menu that gets inserted in each page assumes the existence of files with these names.

Each path has front matter that defines its attributes, and its content is used to build the example tutorial. If you want the content presented in slide format, be sure to include `{% slides %}...{% endslides %}` liquid tags around content containing level two headers as step breaks. 

The front matter that must be included for each path:

```yaml
---
layout: use-case-path
pattern: Web Apps on K8s
icon: compass
how_it_works: https://source.unsplash.com/1200x600/?cloud
deploy: https://example.com/deploy
github: https://github.com/example/repo
download: https://example.com/download
resources:
  - title: Sign in in to Oracle Cloud
    url: https://www.oracle.com/uk/cloud/sign-in.html
    icon: cloud
  - title: Signing in to My Oracle Support Portal
    url: https://support.oracle.com/portal
    icon: portal
services: [available, autoscaling, integration, iaas, paas, automated, database]
---
```

- `layout` should always be `use-case-path`
- `pattern` is the title of this path
- `icon` is a fontawesome icon used when displaying this path in the nav menu
- `how_it_works` should be a url or relative path to an image. Images may be included in the use case's directory and referenced without any leading directory
- `deploy`, `github`, and `download` are urls that will create buttons if they exist. All are optional.
- `resources` is an array of mappings containing a title and url which are used to generate an "additional resources" section at the end of the page. An `icon` key can be assigned to include a fontawesome icon in the button for the resource.
- `services` is a list of tags. This taxonomy is still being generated. If you don't see an applicable tag in the examples, you can create a new one and we'll incorporate it. Lower case, no spaces (hyphens ok), single words preferred.

As mentioned previously, the content below the front matter will be displayed in a "Let's Build This" section. If the content is to be displayed as a step-by-step tutorial, separate each step with a level 2 header and surround the content with the `{% slides %}` liquid tag:

```
---
[front matter...]
---
{% slides %}
## Step 1

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 

## Step 2

Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 

## Step 3

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
{% endslides %}
```
