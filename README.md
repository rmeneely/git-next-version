# git-next-version
This GitHub Action determines the next version based on the last matching tag.


## Usage
```yaml
    - uses: rmeneely/git-next-version@v1.0.4
      with:
        # Tag pattern. The filter to use when searching for the LAST_VERSION tag
        # Optional
        # Default: 'v[0-9]*'
        tag_pattern: 'v[0-9]*'

        # The version increment - major, minor, patch, none
        # Optional
        # Default: patch
        increment: 'patch'

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

        # Create a version tag of NEXT_VERSION
        # Optional
        # Default: 'true'
        set_next_version: 'true'
```

## Example
```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next increment
    - uses: rmeneely/git-next-version@v1.0.4
      with:
        increment: 'minor'
```

## Output
```shell
# If run as GitHub Action - sets the following $GITHUB_ENV variables
# If run as script - prints the following variables 
LAST_VERSION=<last version>
NEXT_VERSION=<next version>
```

## License
The MIT License (MIT)
