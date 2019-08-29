# Virgo4 Pool EDS Web Service
A Virgo 4 Pool implementation for the EBSCO Discovery Service

---

Key gems include:
- [Cuba](https://github.com/soveran/cuba), a fast Ruby microframework
- [Virgo Parser](https://github.com/uvalib/virgo4-ruby-parser), uses generated Antlr parser in Java to process queries in a consistent way across virgo pools.

A Quick Tour:
Some Rails conventions are used where it made sense. Most things are simplified compared to a Rails app.
- `config/initializer.rb` Sets up the Rack app
- `app/router.rb` defines all entrypoints and responses
- `app/models/eds.rb` handles EDS login and session
- `app/models/eds/search.rb` handles eds requests
- `app/models/fields` contains dynamic field builders which are used in `app/views/_record.jbuilder`
- `app/views/` contains jbuilder templates for constructing json responses
- `config/locales` contains language files


To start:
- RVM install the version of jruby in `.ruby-version`
- `bundle`
- Set up environment variables in `.env`
- `./scripts/dev.sh` Dev Server
- `./scripts/test.sh` Tests using Rspec
