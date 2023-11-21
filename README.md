# publish-gem-to-rubygems

A GitHub Action to publish a RubyGem to RubyGems.org

This Action has been heavily influenced by [Jstastny's Publish-Gem-to-Github Action](https://github.com/jstastny/publish-gem-to-github).

## Usage

See [RubyGems API Key scopes][key] on how to obtain an api key

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
      - name: Checkout
        uses: actions/checkout@v2

      - name: Build and publish to RubyGems
        uses: actionshub/publish-gem-to-rubygems@main
        with:
          token: ${{ secrets.RUBY_GEMS_API_KEY }}
```

[key]: https://guides.rubygems.org/api-key-scopes/
