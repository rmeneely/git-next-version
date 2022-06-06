# git-next-version
This GitHub Action determines the next version based on the last matching tag.


## Usage
```yaml
    - uses: rmeneely/git-next-version@v1.0.11
      with:
        # Tag pattern. The filter to use when searching for the LAST_VERSION tag
        # Optional
        # Default: 'v[0-9]*.[0-9]*.[0-9]*'
        tag_pattern: 'v[0-9]*.[0-9]*.[0-9]*'

        # The version increment - major, minor, patch, none
        # Optional
        # Default: patch
        increment: 'patch'

        # Auto increment - true, false
        # Determines NEXT_VERSION based on matching commit messages
        # defined by auto_increment_major_version_pattern and auto_increment_minor_version_pattern options
        # Optional
        # Default: 'false'
        auto_increment: 'false'

        # Defines a pattern for matching major version commit
        # Optional
        # Default: '*major*'
        auto_increment_major_version_pattern: 'major|breaking|incompatible'

        # Defines a pattern for matching minor version commit
        # Optional
        # Default: '*minor*'
        auto_increment_minor_version_pattern: 'minor|feature'

        # Defines an auto version increment limit commit
        # If a major version commit is matched, but the increment
        # limit is set to 'minor' then NEXT_VERSION will be a 
        # minor version increment instead of a major version increment.
        # Optional
        # Default: 'minor'
        auto_increment_minor_version_pattern: 'minor'

        # A prefix to use on the NEXT_VERSION. If not specified the existing LAST_VERSION prefix will be used.
        # Optional
        # Default: ''
        new_prefix: ''

        # A suffix to use on the NEXT_VERSION. If not specified the existing LAST_VERSION suffix will be used.
        # Optional
        # Default: ''
        new_suffix: ''

        # Removes the LAST_VERSION prefix when defining NEXT_VERSION
        # Optional
        # Default: 'false'
        remove_prefix: 'false'

        # Removes the LAST_VERSION suffix when defining NEXT_VERSION
        # Optional
        # Default: 'false'
        remove_suffix: 'false'

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
        set_next_version_tag: 'true'
```

## Example
```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next minor increment
    - uses: rmeneely/git-next-version@v1.0.11
      with:
        increment: 'minor'
```

```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next increment based upon commit messages. Default matches 'major|breaking|incompatible' for a major change, and matching 'minor|feature' for a minor change.
    - uses: rmeneely/git-next-version@v1.0.11
      with:
        auto_increment: 'true'
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
