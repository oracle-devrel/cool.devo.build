[Plugins]: LINK_TBD

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
layout: collection
title: PROJECT_TITLE
series: SERIES-SLUG
description: ONE_LINE_SUMMARY
thumbnail: RELATIVE_PATH_TO_THUMBNAIL_IMAGE
---
```

The thumbnail should be a minimum of 250x150px. It will be resized and cropped (if needed to fit the aspect ratio) when displayed.

## Pages

Each project repo (and the root repo) can contain pages written in Markdown. The only technical requirement for a page is that it contain the appropriate front matter. There are stylistic guidelines that will be enforced in the content, but any text file with an `.md` extension and front matter will render as part of the site.

Within a project repo, directories become parts of the url (permalink) for the page. Submodule repos are added within the `/collections` directory, and the base URL for any project is `devo.build/projects/PROJECT-SLUG`. The slug will be assigned by the maintainers when the submodule is added.

Required front matter:

```yaml
---
title: PAGE TITLE
parent: series-slug
tags: [TAGS]
thumbnail: https://via.placeholder.com/350x400?text=DevOps+Thumbnail
---
```

See [Tagging Posts and Pages](#tags)

Optional front matter:

- `author:` can be a block of YAML data, or if the author has been permanently added to the site, the author's slug can be used.
    
    To specify author data in the front matter, use a block like this. Other than "name" all fields are optional, fill out what's appropriate and leave out what's not:

    ```yaml
    author:
      name: Brett Terpstra
      bio: Oracle DevRel Writer, developer, blogger, podcaster
      home: https://brettterpstra.com
      twitter: ttscoff
      github: ttscoff
      gitlab: ttscoff
      bitbucket: ttscoff
      stackoverflow: ttscoff
      codepen: ttscoff
      youtube: BrettTerpstra
      facebook: ttscoff
      linkedin: brettterpstra
      instagram: ttscoff
      avatar: https://cdn3.brettterpstra.com/images/bt-mark.png
      location: Minnesota
      links:
        - label: Random Link
          url: https://example.com/one/
        - label: Second Link
          url: https://example.com/two/
      email: brett@example.com

    ```

- `toc: true` will enable a sidebar table of contents, automatically generated from headers in the page

- To disable either or both sidebars and make content wider:
    
    ```yaml
    toc: false
    author_profile: false
    ```

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


## Tagging Posts and Pages

Tags and categories should be chosen from available options. If you need a tag or category that does not exist yet, add it to your post but specify in the pull request that you'd like the new tag added to the site.

Available Categories, use all that apply. Only include the short version (after the colon below):

- __Build and Run Cloud Native Apps__
  
    slug: `cloudapps`
- __Cloud-Native Software Development on OCI__

    slug: `coulddev`
- __Build, Move, and Modernize Applications__

    slug: `modernize`
- __Java, GraalVM, and Helidon__

    slug: `java`
- __Enterprise Cloud Native Development__

    slug: `enterprise`
- __Personal Cloud Services__

    slug: `personal`
- __Video Games, Servers, and Development__

    slug: `games`
- __Top Frameworks for Top Languages__

    slug: `frameworks`

Available Tags, use at least one of each type. If no appropriate tag exists in a section, you can add a new tag to your post. In the pull request, please specify the new tag and to which type it belongs.

__personas:__

- fullstack
- frontend
- devops
- backend
- architect
- robotics
- arvr
- datascience
- gamedev
- dbre

__languages:__

- python
- javascript
- typescript
- go
- ruby
- terraform

__frameworks:__

- tensorflow
- micronaut
- nodejs
- spark
- flask

__topics:__ (optional, create new ones as needed)

- hardware
- oci
- pytorch



## Assets

Assets are stored in an `assets` directory in each repository. All links to these assets should be relative to the location of the linking page. If your page is at `/project/page-1.md`, your link to an image in that page would look like:

    ![](../assets/my_image.jpg)

### Images

Images should be sized to appropriate dimensions for retina presentation. If the image is to be displayed at 800x600 and only one asset is being provided, the asset should be 1600x1200 at 72dpi.

Ideally, though, multiple versions of the image should be available. The 1x version should have the base name, e.g. `image1.jpg`. A 2x version should be provided using the same base name with `@2x` appended, i.e. `image1@2x.jpg`. If webp versions with the same base name are provided, they will be offered as sources to compatible browsers (`image1.webp`, `image1@2x.webp`). Webp images can greatly reduce file size and render time for image-heavy pages.

When providing multiple versions of the same image, please use the liquid tag `{% img BASE_NAME{.jpg,@2x.jpg,.webp,@2x.webp} %}`, which will allow our Jekyll plugins to build out a picture tag with multiple sources.

See [Plugins][] for more info on the img tag.

### Video/Animated GIF

Animated gifs can be used in your Markdown, but instead of embedding them with `![](movie.gif)` Markdown formatting, please use the `{% gif movie.gif %}` Liquid tag. See [Plugins][].

In general, videos over one minute in length should be linked to from an external hosting platform like YouTube or Vimeo. Maintaining repositories with large video files is not ideal.

Short, silent videos can be used instead of animated GIFS, and in most cases take up significantly less space than a GIF. These can be embedded with the gif tag using `{% gif FILENAME{.mp4,.webm} %}`, which will detect the movie format and generate an appropriate video tag, replicating the autoplay/looping of an animated GIF. At minimum an mp4 version must be provided, additional formats (webm, ogv) with the same base name and different extensions are optional.

## Style

- The title front matter will be used as an h1 at the top of the page, don't repeat it in the content
- Avoid using "smart quotes" (curly quotes). Use straight single and double quotes
- Divide long pieces up with headers, starting with level two (`##`), and increasing for sub-sections in sequence
    - Don't jump from a level two to a level four
- Title case headlines (<https://brettterpstra.com/titlecase/test>)
- Use fenced code blocks for multi-line code, or commands that wrap to multiple lines (allows better formatting and syntax highlighting)
    - Start a code block with triple backticks (`\`\`\``)
    - include language specifier when possible, e.g. `\`\`\`ruby`. Use `sh` for shell commands
- Include a newline after headlines
- Use numbered lists when it represents a sequence
- First letter of items should be capitalized unless the list items each finish a sentence preceding the list
- One-sentence list items should not end in a period. If a list item contains multiple sentences, periods are optional. If you use a period on one, though, use a period on every item in that list
- When showing shell commands in fenced code, use a single `$` at the beginning of the line to represent the prompt
- File names, paths, and commands in paragraphs should be surrounded in backticks to mark them as code spans
- When showing an entire URL in the copy, it should either be self-linked (e.g. `<https://example.com>`) or marked as a code span
- Use 4 spaces to indent lists
- Each item of a numbered list must start with `1.` (or whatever number). List items do not have to be in order, as long as they start with a number and a dot. The numeric sequence will be corrected when rendering.
- Only use numbered lists for lists containing two or more items
- To include paragraphs in a list item, add a blank line before the paragraph and indent it four spaces (or one tab) beyond the indent of the parent list item
    - You can do the same with fenced code blocks, starting the fence four spaces/one tab from the parent
- Use italics for emphasis in prose copy (`I *emphasized* this`)
- Use bold for things like 
    - emphasizing a key word
    - product names
    - menu/button titles
- Use block quotes for quotes, starting each line with `> TEXT`. Add line breaks by including a double space at the end of the line. Attribution should start with `---` (em dash), and be linked if appropriate
- When linking text, make the content of the link actually describe where the link will go
    - __Bad:__ Click [here](http://example.com) for more details
    - __Good:__ Click here for [more details on Markdown formatting](http://example.com)
