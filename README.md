# git-next-version
This GitHub Action determines the next version based on the last matching tag.


## Usage
```yaml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: rmeneely/git-next-version@v1
      with:
        tag_pattern: 'v[0-9]*' (optional)
        increment: 'minor' - options: major|minor|patch|none (optional)
        new_prefix: '' (optional)
        new_suffix: '' (optional)
        last_version: '' (optional)
        next_version: '' (optional)
```

## Output
```shell
LAST_VERSION=<last version>
NEXT_VERSION=<next version>
```

## License
The MIT License (MIT)
