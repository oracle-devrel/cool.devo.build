# OCM GitHub integration requirements

Oracle DevRel currently generates a site of tutorials and articles (cool.devo.build) using Jekyll and hosting on GitHub Pages. This setup allows contributors from inside and outside of Oracle to submit Markdown-formatted articles and tutorials via a Pull Request workflow, with our editorial staff using Git to request and make changes with a full audit trail. Once a PR is merged to the main branch, the site regenerates with the new content. 

It's a fast, agile, and customizable publishing platform for us. Our goal is to maintain the submission/editorial (Git) and the flexible markup (Markdown/Jekyll) sides of this platform, but publish the end result to OCM.

This document details what we believe are our most viable options, presented in the hope that the OCM team can work with us to achieve our goal.

1. OCM provides API endpoint to trigger page creation/update
    - Accepts a page identifier (slug)
    - Receives either 
        - HTML content 
        - or URL of HTML document (GitHub url or pushed to object storage)
    - Endpoint called via a GitHub action
        - Currently a push to main triggers Jekyll build
        - Jekyll builds the entire site, but we can extract only added/modified files from the commit and associate them with affected ids (slugs) so that only pages modified by the Jekyll build would be passed to the API call
2. Provided HTML parsed for meta and body content
    - We have complete control over the markup generated, and can adjust to meet the needs of OCM, assuming it allows ingestion of raw HTML
    - We could potentially submit Markdown, but we have Jekyll customized to handle some special tags that allow more flexibility in several areas. If we can let Jekyll (and our plugins) build the HTML, we won't have to make any requests for OCM to handle non-standard Markdown
    - Proposed HTML formatting
        - `<head>` contains metadata
            - title
            - description
            - publish date
            - updated date
            - tags
            - series info (I don't know how this plays out yet)
            - author info
                - bio
                - social links
            - (OCM-required metadata can be added as needed, and it's understood that some of the above may not be relevant to OCM)
        - `<body>` contains "naked" HTML content, which should be easily injected into a container template
            - no div/article/section tags, no tag links, no menus, related posts, etc.
            - paragraphs, lists, img/picture tags, code blocks, blockquotes
        - Styling would be inherited from the OCM template. The only considerations are some special classes which, if provided to us, would allow for things like callouts and syntax highlighting in code blocks without inlining CSS styles
            - Callouts are blockquotes with special classes (.notice, .alert, .warning) applied
            - pre/code blocks are syntax highlighted via class names (Pygments-compatible), so having those classes covered with an UX-approved color scheme would be ideal
3. Parsed data applied to create/update associated OCM page

## Image/Asset handling

Images and other assets that are not linked externally are currently stored in GitHub Pages hosting. So either the HTML provided to OCM has to have absolute URLs applied to those images, or the assets need to be ingested when a page is created/updated.

Options:

1. A GitHub action could be called when local images are detected in a commit (either added or modified). If there's a media API in OCM, those images could be automatically uploaded and the URLs replaced in the Markdown source, creating a new commit. This would ease the process on both authors and editors, and only images that were new or changed would ever be sent to the API. This would need to happen separate from the Jekyll build pipeline.
2. Authors could upload their assets to OCM and use the OCM-provided destination url in the Markdown source to begin with. This is fine for Oracle contributors who have access (I don't know if everybody will), but for outside contributors would require submitting images to someone for uploading and waiting for a response with URLs. The Technical Content team could be responsible for handling image uploading during the editorial process, but if this could be automated in any way, it would ease the workload of the editors.
