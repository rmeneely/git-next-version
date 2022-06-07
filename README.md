# git-next-version
This GitHub Action determines the next version based on the last matching tag. It will perform a search for the most recent git tag matching *tag_pattern* setting the ${{ env.LAST_VERSION }} environment variable. 

It will then increment the LAST_VERSION by either a specified INCREMENT or by matching git commit messsages if *auto_increment* is set to 'true', setting the ${{ env.NEXT_VERSION }} environment variable.

The *set_next_version_tag* if set to 'false' will still set the NEXT_VERSION variable, but will not create a matching git tag. Additional options can override the default behavior as specified below.


## Usage
```yaml
    - uses: rmeneely/git-next-version@v1
      with:
        # Tag pattern. The filter to use when searching for the LAST_VERSION tag
        # Optional
        # Default: 'v[0-9]*.[0-9]*.[0-9]*'
        tag_pattern: 'v[0-9]*.[0-9]*.[0-9]*'

        # The version increment - major, minor, patch, suffix, none
        # major - v1.2.3 -> v2.0.0
        # minor - v1.2.3 -> v1.3.0
        # patch - v1.2.3 -> v1.2.4
        # suffix - v1.2.3-rc.1 -> v1.2.3-rc.2
        # none - v1.2.3 -> v1.2.3
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
        # Default: 'major|breaking|incompatible'
        auto_increment_major_version_pattern: 'major|breaking|incompatible'

        # Defines a pattern for matching minor version commit
        # Optional
        # Default: 'minor|feature'
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

## Examples
```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next default increment (patch)
    # Example: v1.2.3 -> v1.2.4
    - uses: rmeneely/git-next-version@v1
```

```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next minor increment
    # Example: v1.2.3 -> v1.3.0
    - uses: rmeneely/git-next-version@v1
      with:
        increment: 'minor'
```

```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next major increment
    # Example: v1.2.3 -> v2.0.0
    - uses: rmeneely/git-next-version@v1
      with:
        increment: 'major'
```

```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next increment based upon commit messages. Default matches 'major|breaking|incompatible' for a major change, and matching 'minor|feature' for a minor change. If neither matching major or minor commit message changes are found then it will perform a patch increment.
    # Note that the *auto_increment_limit* option can limit the increment. For example if *auto_increment_limit='minor'* then only a minor increment will be performed if matching major (or minor) commit messages are found.
    - uses: rmeneely/git-next-version@v1
      with:
        auto_increment: 'true'
```

```yaml
    # Sets LAST_VERSION environment variable to last matching tag
    # Sets NEXT_VERSION environment variable to the next increment based upon commit messages. Default matches 'major|breaking|incompatible' for a major change, and matching 'minor|feature' for a minor change.
    # Sets NEXT_VERSION suffix to be '-rc' so v1.2.3 would become v1.2.3-rc
    - uses: rmeneely/git-next-version@v1
      with:
        auto_increment: 'true'
        new_suffix: '-rc'
```

```yaml
    # Sets LAST_VERSION environment variable 'v1.2.3' instead of searching for a matching the version tag
    # Sets NEXT_VERSION environment variable to the next default increment (patch)
    # Does not create a NEXT_VERSION git tag
    - uses: rmeneely/git-next-version@v1
      with:
        last_version: 'v1.2.3'
        set_next_version_tag: 'false'
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
