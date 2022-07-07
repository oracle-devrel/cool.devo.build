FROM ruby:3.0.2-alpine3.14 as jekyll-setup

RUN apk add git build-base &&\
    git clone https://github.com/oracle-devrel/cool.devo.build.git

WORKDIR /cool.devo.build
RUN bundle install

#####

FROM ruby:3.0.2-alpine3.14 as jekyll
COPY --from=jekyll-setup /usr/local/bundle /usr/local/bundle
COPY --from=jekyll-setup /cool.devo.build /cool.devo.build
WORKDIR /cool.devo.build
RUN apk add git
ENTRYPOINT git pull && bundle exec jekyll serve --livereload --host 0.0.0.0

EXPOSE 4000
EXPOSE 35729
