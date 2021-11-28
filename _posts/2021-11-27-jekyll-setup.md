---
layout: single
title: Jekyll Setup
date: 2021-11-27
categories:
  - blog
  - tech
tags:
  - jekyll
  - blog
  - markdown
  - ruby
---

For this post, I wanted to document the installation steps to setup `macOS` for
[Jekyll](https://jekyllrb.com/) development.

## Installation

First, install and initialize [`rbenv`](https://github.com/rbenv/rbenv):

```zsh
❯ brew install rbenv
[ ... ]

❯ rbenv init
# Load rbenv automatically by appending
# the following to ~/.zshrc:

eval "$(rbenv init - zsh)"
```

After following the prompt and appending the line to `~/.zshrc`, install `ruby 3.0.3`:

```zsh
❯ rbenv install 3.0.3
Downloading openssl-1.1.1l.tar.gz...
-> https://dqw8nmjcqpjn7.cloudfront.net/0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1
Installing openssl-1.1.1l...
Installed openssl-1.1.1l to /Users/bfinney/.rbenv/versions/3.0.3

Downloading ruby-3.0.3.tar.gz...
-> https://cache.ruby-lang.org/pub/ruby/3.0/ruby-3.0.3.tar.gz
Installing ruby-3.0.3...
ruby-build: using readline from homebrew
```

And finally, setup the project:

```zsh
❯ rbenv global 3.0.3

❯ gem -v
3.2.32

❯ gem install jekyll bundler
[ ... ]

❯ bundle install
Fetching gem metadata from https://rubygems.org/.........
Resolving dependencies...
Using concurrent-ruby 1.1.9
[ ... ]
Please ensure that your Gemfiles and .gemspecs are suitably restrictive
to avoid an unexpected breakage when 3.0 is released (e.g. ~> 2.3.0).
See https://github.com/rubyzip/rubyzip for details. The Changelog also
lists other enhancements and bugfixes that have been implemented since
version 2.3.0.

❯ bundle exec jekyll serve --livereload
Configuration file: /Users/bfinney/projects/github/about/_config.yml
            Source: /Users/bfinney/projects/github/about
       Destination: /Users/bfinney/projects/github/about/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
      Remote Theme: Using theme mmistakes/minimal-mistakes
       Jekyll Feed: Generating feed for posts
   GitHub Metadata: No GitHub API authentication could be found. Some fields may be missing or have incorrect data.
                    done in 3.326 seconds.
 Auto-regeneration: enabled for '/Users/bfinney/projects/github/about'
LiveReload address: http://127.0.0.1:35729
    Server address: http://127.0.0.1:4000/about/
  Server running... press ctrl-c to stop.
```
