# publish-gem-to-rubygems

A GitHub Action to publish a RubyGem to RubyGems.org.

This Action has been heavily influenced by [Jstastny's Publish-Gem-to-Github Action](https://github.com/jstastny/publish-gem-to-github).

## Usage

See [RubyGems API Key scopes][key] on how to obtain an API key.

We recommend using [ruby/setup-ruby](https://github.com/ruby/setup-ruby) to set up your Ruby environment.

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '4.0' # Default to Ruby 4.0

      - name: Build and publish to RubyGems
        uses: actionshub/publish-gem-to-rubygems@main
        with:
          token: ${{ secrets.RUBY_GEMS_API_KEY }}
```

[key]: https://guides.rubygems.org/api-key-scopes/
