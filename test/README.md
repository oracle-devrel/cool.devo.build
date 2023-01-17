# Staging your content in a local container

If you want to see how things will render _while_ you're working on them, you can run the <cool.devo.build> staging site in a Docker container on your local machine.

## Build the docker image

In order to build the image, run:

```shell
docker build -f jekyll.dockerfile . -t cool.devo.build:latest
```

In general, it's not required for you to rebuild the image on each testing session. When you run start the container it will pull the latest version of this repo and then run the Jekyll server.
However if you still want to rebuild the image, you can run:

```shell
docker build --no-cache -f jekyll.dockerfile . -t cool.devo.build:latest 
```

## Run the staging site

In order to start the staging site and test your changes to _devo.tutorials_  in real time you have to start the container, run the below command, replacing _<local_path_to_devo.tutorial>_  with the content path on your machine.

```shell
docker run -it --rm -p 4000:4000 -p 35729:35729 \
  -v <LOCAL_TUTORIALS_PATH>:/cool.devo.build/tutorials \
  --name cool.devo.build cool.devo.build:latest
```

Now you can open a browser to http://localhost:4000

The staging site run with live reload and incremental builds turned on. So as you edit your content the web browser should automatically refresh when you save the document. Only pages being modified are rendered again, so if you change a title and it doesn't show up properly on an index page, you need to `touch` the index page to regenerate it.

If you want to force the entire site to rebuild you should stop and start the container.

## Stop the staging site

To stop the staging site run:

```shell
docker stop cool.devo.build
```
