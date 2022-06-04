# git-next-version
This GitHub Action determines the next version based on the last matching tag.


## Usage
```yaml
    - uses: rmeneely/git-next-version@v1
      with:
        # Tag pattern. The filter to use when searching for the LAST_VERSION tag
        # Optional
        # Default: 'v[0-9]*'
        tag_pattern: 'v[0-9]*'

        # The version increment - major, minor, patch, none
        # Optional
        # Default: minor
        increment: 'minor'

        # A prefix to use on the NEXT_VERSION. If not specified the existing LAST_VERSION prefix will be used.
        # Optional
        # Default: ''
        new_prefix: ''

        # A suffix to use on the NEXT_VERSION. If not specified the existing LAST_VERSION suffix will be used.
        # Optional
        # Default: ''
        new_suffix: ''

        # Specifies the LAST_VERSION instead of seaching for the last matching tag
        # Optional
        # Default: ''
        last_version: ''

        # Specifies the NEXT_VERSION instead of incrementing it.
        # Optional
        # Default: ''
        next_version: ''

        # Add repository path as safe.directory for Git global config by running:
        # `git config --global --add safe.directory <path>`
        # Required to allow action to execute git commands
        # Default: true
        set-safe-directory: ''
```

## Example
```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next increment
    - uses: rmeneely/git-next-version@v1.0.2 >> $GITHUB_ENV
```

## Output
```shell
LAST_VERSION=<last version>
NEXT_VERSION=<next version>
```

## License
The MIT License (MIT)
