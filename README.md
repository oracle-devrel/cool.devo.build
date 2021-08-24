[Special Tags]: LINK_TBD

## Repos

The root devo.build site is fairly spartan. Most content in it is provided by external GitHub repositories that are added as submodules and imported when rendering the site.

A content repository should contain an `index.md`, any markdown pages (optionally sorted into subdirectories), and an `assets` folder which contains any media assets used in the pages (images, PDFs, videos, audio).

- projects/REPO_SUBMODULE
- index.md (see below)
- /Markdown pages (see below)
- /assets/* 

### Project index.md

Each project must contain an `index.md` file in its root. This file serves as the project overview. In addition to the required front matter, any content in this page will be displayed above a listing of its sub-pages.

#### Project front matter

The index.md file should have the following front matter. Uppercase values must be customized, lowercase values must not be modified.

```yaml
---
layout: project
title: PROJECT_TITLE
project: PROJECT_TAG
description: ONE_LINE_SUMMARY
thumbnail: RELATIVE_PATH_TO_THUMBNAIL_IMAGE
---
```

The thumbnail should be a minimum of 250x150px. It will be resized and cropped (if needed to fit the aspect ratio) when displayed.

## Pages

Each project repo (and the root repo) can contain pages written in Markdown. The only technical requirement for a page is that it contain the appropriate front matter. There are stylistic guidelines that will be enforced in the content, but any text file with an `.md` extension and front matter will render as part of the site.

Within a project repo, directories become parts of the url (permalink) for the page. Submodule repos are created within the `/projects` directory, and the base URL for any project is `devo.build/projects/PROJECT-SLUG`. The slug will be assigned by the maintainers when the submodule is added.

## Posts

Posts must be placed in the `_posts` directory of the main repository. When a new page is added to a project, a blog post should be created to announce and link to it. This will allow a date-based way to surface/spotlight new content.

Jekyll requires blog post files to be named according to the following format:

`YEAR-MONTH-DAY-title.md`

Where `YEAR` is a four-digit number, `MONTH` and `DAY` are both two-digit numbers. After that, include the necessary front matter.

Required front matter:

- `layout: posts`
- `date: YYYY-MM-DD HH:MM TZ`
- `categories: [CATEGORIES]`
- `tags: [TAGS]`

Available Categories, use all that apply. Only include the short version (after the colon below):

- Build & Run Cloud Native Apps: build
- Cloud Development on OCI: oci
- Build, Move & Modernize Applications: modernize
- AI/ML and Data Science: ai
- Java, including GraalVM and Helidon: java
- Enterprise Cloud Native Development: enterprise
- Personal Cloud Services: personal
- Video Games, Servers & Development: games

Available Tags, use all that apply:

Language:

- java
- python
- oci
- javascript
- typescript
- go
- ruby
- terraform

Frameworks:

- tensorflow
- pytorch
- micronaut
- nodejs
- spark
- flask

Persona:

- fullstack
- frontend
- devops
- backend
- architect
- robotics
- ar
- vr
- datascience
- gaming
- dbre

Topic:

- hardware


## Assets

Assets are stored in an `assets` directory in each repository. All links to these assets should be relative to the location of the linking page. If your page is at `/project/page-1.md`, your link to an image in that page would look like:

    ![](../assets/my_image.jpg)

### Images

Images should be sized to appropriate dimensions for retina presentation. If the image is to be displayed at 800x600 and only one asset is being provided, the asset should be 1600x1200 at 72dpi.

Ideally, though, multiple versions of the image should be available. The 1x version should have the base name, e.g. `image1.jpg`. A 2x version should be provided using the same base name with `@2x` appended, i.e. `image1@2x.jpg`. If webp versions with the same base name are provided, they will be offered as sources to compatible browsers (`image1.webp`, `image1@2x.webp`). Webp images can greatly reduce file size and render time for image-heavy pages.

When providing multiple versions of the same image, please use the liquid tag `{% img BASE_NAME{.jpg,@2x.jpg,.webp,@2x.webp} %}`, which will allow our Jekyll plugins to build out a picture tag with multiple sources.

See [Special Tags][] for more info on the img tag.

### Video/Animated GIF

Animated gifs can be used in your Markdown, but instead of embedding them with `![](movie.gif)` Markdown formatting, please use the `{% gif movie.gif %}` Liquid tag. See [Special Tags][].

In general, videos over one minute in length should be linked to from an external hosting platform like YouTube or Vimeo. Maintaining repositories with large video files is not ideal.

Short, silent videos can be used instead of animated GIFS, and in most cases take up significantly less space than a GIF. These can be embedded with the gif tag using `{% gif FILENAME{.mp4,.webm} %}`, which will detect the movie format and generate an appropriate video tag, replicating the autoplay/looping of an animated GIF. At minimum an mp4 version must be provided, additional formats (webm, ogv) with the same base name and different extensions are optional.

