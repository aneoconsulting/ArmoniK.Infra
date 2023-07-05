# Contributing to ArmoniK Infrastructure

Thanks for helping to make ArmoniK better!

## Conventional pull request commit rules

It is important to note that this repository [ArmoniK Infrastructure](https://github.com/aneoconsulting/ArmoniK.Infra)
adheres to semantic releases. Familiarity with conventional commit rules is imperative and make it easier to
find and understand commits of the main branch. In addition, failure to follow the conventional commit guidelines may result
in rejection of the pull requests.

Conventional Commits rules is a convention for structuring pull request commit messages to describe changes. A pull request
message format must be as follows:

```text
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

such that each PR commit message consists of a `header`, a `body` and a `footer`, all separated by blank lines.

The header of a PR commit message has a special format that includes a `type`, a `scope` and a `subject`. The type indicates
the nature of the change. Commonly used types include:

- `feat`: for a new feature.
- `fix`: for a bug fix.
- `docs`: documentation changes.
- `style`: for code style changes (formatting, indentation, etc.).
- `refactor`: code changes that neither fix a bug nor add a feature.
- `perf`: for performance improvements.
- `test`: adding or modifying tests.
- `chore`: maintenance or organizational tasks.
- `build`: changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)

Hereafter, two examples of a conventional pull request commits:

```text
docs(changelog): update changelog to beta.5
```

and:

```text
fix(release): need to depend on latest rxjs and zone.js

The version in our package.json gets copied to the one we publish, and users need the latest of these.
```

In addition, both `fix` and `feat` types of the header have the following effects:

- `fix`: a commit of this type patches a bug in your codebase (this correlates with PATCH in Semantic Versioning).
- `feat`: a commit of this type introduces a new feature to the codebase (this correlates with MINOR in Semantic Versioning)
  .

For more details about conventional commit rules, please refer
to [Conventional commits](https://www.conventionalcommits.org/en/v1.0.0/). 
  


