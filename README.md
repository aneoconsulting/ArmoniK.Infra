# Table of contents

- [Introduction](#introduction)
- [PR_ConventionalCommit](#PR-conventional-commits-rules)
- [Bugs/Support](#bugssupport)

# Introduction

In this project contains Terraform modules for the different resources and components of ArmoniK.
# Conventional PULL REQUEST Commits Rules

This GitHub repository follows the "Conventional Commits" rules for managing PR commits and releases, making it easier to find and understand commits of the main branch. "Conventional Commits" is a convention for structuring PR commit messages to describe changes.

- **PULL REQUEST Message Format**:

Each PR commit message consists of a **header**, a **body** and a **footer**.  The header has a special
format that includes a **type**, a **scope** and a **subject**:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

- **Type**: Indicates the nature of the change. Commonly used types include:
  - `feat`: for a new feature.
  - `fix`: for a bug fix.
  - `docs`:  documentation changes.
  - `style`: for code style changes (formatting, indentation, etc.).
  - `refactor`:  code changes that neither fix a bug nor add a feature.
  - `perf`: for performance improvements.
  - `test`: adding or modifying tests.
  - `chore`: maintenance or organizational tasks.
  - `build`: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)

Example of a Conventional Commit of PULL REQUEST:

```
docs(changelog): update changelog to beta.5
```
```
fix(release): need to depend on latest rxjs and zone.js

The version in our package.json gets copied to the one we publish, and users need the latest of these.
```

- `fix`: a commit of the type fix patches a bug in your codebase (this correlates with PATCH in Semantic Versioning).
- `feat`: a commit of the type feat introduces a new feature to the codebase (this correlates with MINOR in Semantic Versioning).


**For more details, please refer to these links:** [link1](https://www.conventionalcommits.org/en/v1.0.0/), [link2](https://github.com/angular/angular/blob/22b96b96902e1a42ee8c5e807720424abad3082a/CONTRIBUTING.md).
It's important to note that this repository adheres to semantic releases. Familiarity with conventional commit rules is imperative. Failure to follow the conventional commit guidelines may result in rejection of the pull request.

# Bugs/Support

Please direct enquiries about ArmoniK to the public mailing
list [armonik-support@aneo.fr](mailto:armonik-support@aneo.fr).

See also [Issues](https://github.com/aneoconsulting/ArmoniK/issues) of ArmoniK project.

To report a bug or request a feature, please use and follow the instructions in one of
the [issue templates](https://github.com/aneoconsulting/ArmoniK/issues/new/choose). Don't forget to include the version of
ArmoniK you are using.
