To test this out, you'll need to get Jekyll up and running, which will require Ruby 3 and ruby gems to be available. 

Clone <https://github.com/oracle-devrel/cool.devo.build> and check out the `cec-integration` branch. Then run `bundle install` to apply the necessary Ruby gems.

The script expects an installation of the cec-toolkit in the directory `_cec` off of the root of the jekyll directory. This is hardcoded, but can be modified in the #cec method of `_plugins/cec_hooks.rb`. The majority of the script's functionality can be [found in that file](https://github.com/oracle-devrel/cool.devo.build/blob/cec-integration/_plugins/cec_hooks.rb).

Repository and server names are hardcoded in constants at the top of `_plugins/cec_hooks.rb`. By default it expects a repo named 'DevO_QA' with a server set up in the cec toolkit named 'ost'. These can be altered as needed.

The cec-integration branch includes a subdirectory called `temp_content` which provides a single Tech Content article and assets for testing. Normally this repo would be checked out recursively and include the `devo.tutorials` submodule containing all tech content in a `tutorials` subdirectory, but that's excessive for testing. Additional content can be added to the `temp_content` directory as needed for testing, but note that any content added must adhere to the front matter requirements of the [devo.tutorials repo](https://github.com/oracle-devrel/devo.tutorials/).

To run the jekyll build with CEC integration and render all included articles to OCM:

	CEC_DEPLOY=1 DEBUG_CEC=3 bundle exec jekyll build

Because this is required to use the CEC Toolkit, which in turn reuqires redundant uploading and downloading of all assets for simple operations like checking if an asset already exists, running it on a repository of 100+ articles can take multiple hours. (Running with the one included test article with multiple assets should take around 1m45s.) I would love to see a more direct integration, but for security reasons we've been required to use cec-toolkit, which means we deal with the very long render times necessary.

For a detailed list of the steps taken by the script, see the Notes at the end of [`_plugins/cec_hooks.rb`](https://github.com/oracle-devrel/cool.devo.build/blob/cec-integration/_plugins/cec_hooks.rb#L973).