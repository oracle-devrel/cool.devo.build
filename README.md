[Plugins]: LINK_TBD

## Staging your content

We don't have a good staging system right now. We'll be able to show you your work before it goes live, but if you want to see how things will render _while_ you're working on them, you have to options
1. run a staging site in a docker container on your local machine, as described [here](test/README.md)
2. download the main repo and run a local Jekyll server as described below.

To use the Jekyll setup, you'll need a Ruby setup with `bundler` installed. `gem install bundler` should do the trick.

- Clone this repo using `git clone --recursive https://github.com/oracle-devrel/cool.devo.build/`
- Add your content in the `tutorials` directory (which is actually a submodule)
- Run `bundle install` in the root of the repo
- Run `bundle exec jekyll serve -l`
- Open a web browser to `http://localhost:4000`

The `-l` flag turns on LiveReload and incremental builds, so as you edit your content the web browser should automatically refresh when you save the document. Only pages being modified are rendered again, so if you change a title and it doesn't show up properly on an index page, you need to `touch` the index page to regenerate it. Or kill the server (CTRL-C in your terminal) and run `jekyll build` to force the entire site to render.

## Where your content will exist on the web

Once it's edited and merged, your content will be available at `https://cool.devo.build/tutorials/...`. The `...` will be the directory path from the parent repo you contributed to. If you're creating in the Tutorials repo and your markdown file is called `my-cool-tutorial.md` in the root of that repository, the url would be `https://cool.devo.build/tutorials/my-cool-tutorial`. Once your content is converted to Oracle's content management system, a redirect will be added to point to its new location on developers.oracle.com.

## Content comes from repositories

The root devo.build site is fairly spartan. Most content in it is provided by external GitHub repositories that are added as submodules and imported when rendering the site. The primary location for content is the [tutorials repository](https://github.com/oracle-devrel/devo.tutorials/) where most new content should be added.

A content repository is a repository containing nothing but Markdown and image assets. It contains an `index.md`, Markdown pages for each piece of content (optionally sorted into subdirectories), and an `assets` folder which contains any media assets used in the pages (images, PDFs, videos, audio). Each of these types has a few specific requirements that need to be adhered to.

```console
/REPO_SUBMODULE/
    index.md (see below)
    Markdown.md (see below)
    assets/* 
```

### Collection index.md

Each collection repository _must_ contain an `index.md` file in its root. This file serves as the project overview. In addition to the required front matter, any content in this page will be displayed above a listing of the pages that comprise it. Only the front matter is required. If your content is a series and isn't in its own repo, create a subdirectory and include an `index.md` file in the root of the subdirectory.
 
A submodule repository can have more than one collection. The `index.md` file is what will be served if the url path to the parent directory is called, but additional `.md` files with the same front matter keys can also exist and will be displayed as additional collections. Each piece of content can only belong to one collection, though.

#### Project front matter

The index.md file (and all collection indexes) should have the following front matter. Uppercase values must be customized, lowercase values must not be modified.

```yaml
---
layout: collection
title: PROJECT_TITLE
series: SERIES-SLUG
description: ONE_LINE_SUMMARY
thumbnail: RELATIVE_PATH_TO_THUMBNAIL_IMAGE
sort: desc
---
```

The thumbnail should be a minimum of 250x150px. It will be resized and cropped (if needed to fit the aspect ratio) when displayed. At this time we're requesting that all collections and all submitted content have *at least one* image, even if it's simply a screenshot of a tutorial in action. These thumbnails are used to offer better visual navigation and help prevent a "wall of text."

The `series` key defines the slug you'll use to assign content to the collection, so it must be unique. We may eventually run into issues with name clashes, but we'll manually curate until we have a better solution.

The `sort` key determines in what order the child pages of the collection will be shown on the index page. If the collection represents a sequential series, you want to make sure that each article in the series has a more recent date than the one before it, so that when they're sorted by date they'll appear in order. In the case of a sequential series, you'd want to use `sort: asc` to cause the articles to appear starting with the oldest (first) article. If the collection should always surface the newest content at the top of the list, use `sort: desc` (default).

##### Multiple collections per repo

If you wanted to break a repository up into multiple collections, you would simply add a new index file with a different name.

For example, if the directory is "/collections/tutorials", the `index.md` file in that directory would be for "Tutorials." But if you wanted a "Getting Started" collection as well, you would create `getting-started.md` and add the appropriate front matter. As long as it has the `series` key, it will be viewed as a collection. 

The URL for the Getting Started collection would be "https://.../collections/tutorials/getting-started" but it would appear at the same level as all other collections in navigation.

## Pages

Each project repo (and the root repo) can contain as many pages written in Markdown as you like. The only technical requirement for a page is that it contain the appropriate front matter. There are stylistic guidelines that will be enforced in the content, but any text file with the `.md` extension and the requisite front matter will render as part of the site.

Within a project repo, directories become parts of the url (permalink) for the page. Submodule repos are added within the root directory, and the base URL for any collection is `cool.devo.build/PROJECT-SLUG`. The slug will be assigned by the maintainers when the submodule is added.

### Required front matter

```yaml
---
title: PAGE TITLE
parent: series-slug
tags: [TAGS]
thumbnail: RELATIVE_PATH_TO_THUMBNAIL_IMAGE
date: YYYY-MM-DD HH:MM
description: ONE_LINE_SUMMARY
---
```

The date should be the date you plan to publish. If there's any delay in publishing, we'll update the date for you. 

The thumbnail can be any image from your content that can represent it, no resizing necessary. If you want to generate a custom thumbnail, just make an image at least 800px x 800px and include it in the assets folder. Thumbnails are displayed cropped, and cropped differently in different views, so your image shouldn't try to convey vital information.

See [Tagging Pages](#tagging-pages)

### Optional front matter

- `modified`: If you update a post with new content (or corrections), you can add a `modified` key with a new date. Don't change the publish date, though. The modified key will be enough to let us surface updated content without disrupting the (mostly) chronological publishing system. (hint: there's [a script](https://github.com/oracle-devrel/cool.devo.build/blob/main/update_modified.rb) in the cool.devo.build repo that can use to update the modified key for all changed markdown files prior to doing a commit.)
- `categories:` is an array containing one or more category tags. See [Tagging Pages](#tagging-pages) for a list of available categories.
- `author:` can be a block of YAML data, or if the author has been permanently added to the site by the maintainers, a slug will be provided for the author to use.
    
    To specify author data in the front matter, use a block like this. Other than "name," all fields are optional; fill out what's appropriate and leave out what's not:

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

    If you fill all this out once and there's a good chance you'll write again in the future, we'll pull all of this info into the authors data file and assign you a slug. Once you have a slug, you're author section just looks like:

    ```yaml
    author: brett-terpstra
    ```

    Of course, once that happens you'll have to make pull requests to update your bio, but that should be manageable.

- `toc: true` will enable a sidebar table of contents, automatically generated from headers in the page

- You can manually add links to the left sidebar, below any author bio, using:
    
    ```yaml
    sidebar:
      - links:
        - url: https://developer.oracle.com/proximasafe-intro/
          title: Proxima Safe Part 1
        - url: https://developer.oracle.com/proximasafe-part-2/
          title: Proxima Safe Part 2
        - url: https://developer.oracle.com/proximasafe-part-3/
          title: Proxima Safe Part 3
    ```

- To disable either or both sidebars and make content wider:
    
    ```yaml
    toc: false
    author_profile: false
    ```

## Tagging Pages

Tags and categories should be chosen from available options. If you need a tag or category that does not exist yet, add it to your post but specify in the pull request (or open an Issue) that you'd like the new tag added to the site.

### Categories

The categories key is an array, surrounded by square brackets, with multiple values separated by a comma:

```yaml
categories: [cloudapps]
# or with multiple categories...
categories: [clouddev, java, games]
```

Available Categories, use all that apply. Only include the short version (slug):

- __Build and Run Cloud Native Apps__
  
    slug: `cloudapps`
- __Cloud-Native Software Development on OCI__

    slug: `clouddev`
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

These categories are based on the content goals for the DevRel program. New categories can be suggested as needed, but if you can fit your content into one of these, well, that's just excellent. Hats off to you.


### Tags

Available Tags are [listed here](https://github.com/oracle-devrel/cool.devo.build/blob/main/_data/topics.yml), try to use at least one of each type. If no appropriate tag exists in a section, you can add a new tag to your post. In the pull request, please specify the new tag and to which type it belongs.

I'm including the list --- as it exists at the time of this writing --- for reference, but it will definitely be changing faster than I'll remember to update, so please check the link above for the current list.

```yaml
topics:
  - always-free
  - apache
  - apex
  - get-started
  - hardware
  - iac
  - iot
  - jupyter
  - machine-learning
  - oci
  - oke
  - open-source
  - orm
  - pytorch
  - rpi
  - serverless
  - streaming
  - ubuntu
  - data-visualization
  - analytics
  - verrazzano
personas:
  - architect
  - arvr
  - back-end
  - community
  - data-management
  - data-science
  - dbre
  - devops
  - front-end
  - full-stack
  - game-dev
  - robotics
languages:
  - go
  - java
  - javascript
  - mysql
  - php
  - python
  - ruby
  - terraform
  - typescript
frameworks:
  - graalvm
  - express
  - flask
  - kubernetes
  - micronaut
  - nodejs
  - spark
  - spring
  - tensorflow
  - ansible
```

## Assets

Assets are stored in an `assets` directory in each repository. All links to these assets should be relative to the location of the linking page. If your page is at `/tutorials/page-1.md` and your assets folder is at `/tutorials/assets/`, then your link to an image from `page-1.md` would look like `assets/my_image.jpg`.

Please name assets with a prefix based on the page they're being used in. This is to avoid name clashes with other content. If you're writing a tutorial called "Node on OCI," any asset used should be named with the prefix `node-on-oci-*`.

### Images

Insert images using the Liquid tag:

    {% imgx [classes] assets/image.jpg [WIDTH HEIGHT] "CAPTION" "ALT TEXT" %}

This tag allows us to convert the asset to a proper `<picture>` tag with a `srcset`. Use only the base image and size in the tag. _If a matching @2x version is present in the same folder as the image, the generated tag will make it available to hi-res displays._

Classes are optional but can be used to align an image left, right, or center:

- `alignleft`: floats image left, text flows around
- `alignright`: floats image right, text flows around
- `aligncenter`: container becomes full width, image centered, text breaks above and below

WIDTH and HEIGHT are also optional but are encouraged. These should be numbers only, no `px` or other specifier. These should be the width and height of the 1x image, e.g. the size it will display on the page.

The last two strings are also optional but encouraged. If only one string is given, it's used as alt text. Alt text tells screen readers and content scrapers what the image is, and is important for accessibility. Please always include at least one quoted string in the tag.

If two quoted strings are provided, the first one becomes both an image caption, visible on the page. The second string is the alt tag.

Example:

    {% imgx alignright assets/my-tutorial-circuit.jpg 500 300 "Circuit diagram" %}

#### Image Sizes

Images can not be displayed at a width greater than 1200px. Your base image size should never be wider than 1200. Please size your images appropriately and optimize them for web.

If possible, please provide two images for every asset, one at the size you want it displayed, and one at exactly twice the pixel dimensions, named with @2x (image.jpg and image@2x.jpg). An 800x500px image.jpg would have a 1600x1000px image@2x.jpg counterpart.

<!--

### Video/Animated GIF

Animated gifs can be used in your Markdown, but instead of embedding them with `![](movie.gif)` Markdown formatting, please use the `{% gif movie.gif %}` Liquid tag. See [Plugins][].

In general, videos over one minute in length should be linked to from an external hosting platform like YouTube or Vimeo. Maintaining repositories with large video files is not ideal.
-->
To insert a YouTube video as a responsive embed, simply use:

    {% youtube VIDEOID %}

<!--
Short, silent videos can be used instead of animated GIFS, and in most cases take up significantly less space than a GIF. These can be embedded with the gif tag using `{% gif FILENAME{.mp4,.webm} %}`, which will detect the movie format and generate an appropriate video tag, replicating the autoplay/looping of an animated GIF. At minimum an mp4 version must be provided, additional formats (webm, ogv) with the same base name and different extensions are optional.
-->

## Callouts

Use block quotes to create callouts, with Kramdown IAL syntax to add formatting. There are two types available, notice and alert. The formatting works like:

    > This is my note.
    > It can have a couple of lines
    {:.notice}

    > This is an alert. It gets colored in yellow.
    {:.alert}

## Snippets

Fragments will be made available soon.

When linking the Oracle Always-Free Tier signup, please use this in place of the link: `{{ site.urls.always_free }}`. This will insert a tracking link for you.

    Oracle Cloud Infrastructure Free Tier account. [Start for Free]({{ site.urls.always_free }}).

## Style

These are very random notes I've collected while editing some of the initial copy, mostly syntax-related. They are not organized, and are definitely a bit rambly. I'm sure I'll have a bunch more in short order... I'll update with a cleaned up, official "style guide" soon. But please do give them a quick read and avoid some pitfalls we'll have to ask you to fix.

### Headers

- The title front matter will be used as an h1 at the top of the page, don't repeat it in the content
- Divide long pieces up with headers, starting with level two (`##`), and increasing for sub-sections in sequence, e.g. don't jump from a level two to a level four
- [Title case](https://brettterpstra.com/titlecase/test) lede headlines (the `title` key), but simply capitalize subheaders within the content
- Include an empty after headlines

### Code samples

- Use fenced code blocks for multi-line code, or commands that wrap to multiple lines (allows better formatting and syntax highlighting)
    - Start a code block with triple backticks (<code>\`\`\`</code>)
    - include language specifier when possible, e.g. <code>\`\`\`ruby</code>. You can use `console` for terminal instructions
- When showing shell commands in fenced code, use a single `$` at the beginning of the line to represent the prompt
- File names, paths, and commands in paragraphs should be surrounded in backticks to mark them as `code spans`

### Lists

- Use 4 spaces to indent lists. You can get away with 1 tab instead, but please do not indent lists with two spaces, it leads to trouble if we ever change the rendering engine we use. Four spaces will work _everywhere_
- Use numbered lists when it represents a sequence
    - As long as the first item in the list starts with "1.", it doesn't matter what numbers follow. Every line can be "1." or they can be out of order, they'll be automatically straightened out when it renders. Don't waste a lot of time tweaking the numbering if your list gets out of order
- First letter of list items should be capitalized unless the list items each finish a sentence preceding the list
- One-sentence list items should not end in a period. If a list item contains multiple sentences, periods are optional. If you use a period on one, though, use a period on every item in that list
- Don't, in general, use a list for a single item. If you're breaking up a long list by putting headers between groupings, a single-item list is fine
- To include paragraphs in a list item, add a blank line before the paragraph and indent it four spaces (or one tab) beyond the indent of the parent list item
    - You can do the same with fenced code blocks, starting the fence four spaces/one tab from the parent list item's indent level

### Emphasis

- Use italics for emphasis in prose copy (`I *emphasized* this`). Either asterisks (\*) or underscores (\_) are fine
- Use bold for things like 
    - emphasizing a key word
    - product names
    - menu/button titles

### Quotes

- Use block quotes for quotes, starting each line with `> TEXT`
- Quote styling will be handled automatically, so don't add emphasis (italics/bold) to entire lines
- Force line breaks by including a double space at the end of the line (or `<br>`, see General style/formatting)
- Attribution (source) should start with `---` (em dash), and be linked if appropriate

### Links

- When linking text, make the content of the link actually describe where the link will go
    - __Bad:__ Click [here](http://example.com) for more details
    - __Good:__ Check out our tips page for [more details on Markdown formatting](http://example.com)
- When showing an entire URL in the copy (as opposed to hyperlinked text), it should either be self-linked with angle brackets (e.g. `<https://example.com>`) or marked as a code span with single backticks
- Whenever representing a dummy URL in examples, use `https://example.com`. `example.com` is a ICANN protected url for this purpose and it avoids myriad potential security issues with using hijackable domains

### General style/formatting

- Avoid using "smart quotes" (curly quotes). Use straight single and double quotes
- If you're referring to a tool or product that is only ever lowercase, you don't have to capitalize it at the beginning of a sentence
- No one will yell at you if you include `<br>` tags to force line breaks. Different Markdown syntaxes allow for different formatting, but the standard is two spaces the end of a line. However, some text editors trim whitespace on every save and it's easy for them to disappear. A `<br>` will stick around. They'll be there for you. We won't begrudge you that
