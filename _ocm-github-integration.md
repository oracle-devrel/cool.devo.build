# OCM GitHub integration requirements

- OCM API endpoint to trigger page creation/update
    - Accepts a page identifier (slug)
    - Receives either 
        - HTML content 
        - or URL of HTML document (GitHub url or pushed to object storage)
    - Endpoint called via a GitHub action
        - Currently a push to main triggers Jekyll build
        - Jekyll builds the entire site, but we can extract only added/modified files from the commit and associate them with affected ids (slugs) so that only pages modified by the Jekyll build would be passed to the API call
- Provided HTML parsed for meta and body content
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
        - Callouts are blockquotes with special classes applied
        - pre/code blocks are syntax highlighted via class names, so having an Oracle-approved color scheme would be ideal, otherwise we'll have to add CSS inlining to the pipeline
        - Same with any unique CSS styles: Use approved classes where available (e.g. for callouts), inline where absolutely necessary
- Parsed data applied to create/update associated OCM page

## Image/Asset handling

Images and other assets that are not linked externally are currently stored in GitHub Pages hosting. So either the HTML provided to OCM has to have absolute URLs applied to those images, or the assets need to be ingested when a page is created/updated.

Options:

1. A GitHub action could be called when local images are detected in a commit (either added or modified). If there's a media API in OCM, those images could be automatically uploaded and the URLs replaced in the Markdown source, creating a new commit. This would ease the process on both authors and editors, and only images that were new or changed would ever be sent to the API. This would need to happen separate from the Jekyll build pipeline.
2. Authors could upload their assets to OCM and use the OCM-provided destination url in the Markdown source to begin with. This is fine for Oracle contributors who have access (I don't know if everybody will), but for outside contributors would require submitting images to someone for uploading and waiting for a response with URLs. The Technical Content team could be responsible for handling image uploading during the editorial process, but if this could be automated in any way, it would ease the workload of the editors.
