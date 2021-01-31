# Basic Template

[![releases](https://img.shields.io/github/v/release/george-lim/basic-template)](https://github.com/george-lim/basic-template/releases)
[![ci](https://github.com/george-lim/basic-template/workflows/CI/badge.svg)](https://github.com/george-lim/basic-template/actions)
[![license](https://img.shields.io/github/license/george-lim/basic-template)](https://github.com/george-lim/basic-template/blob/main/LICENSE)

## [Usage](#usage) | [Features](#features) | [Examples](#examples) | [CI/CD](#cicd)

Basic Template is a template repository that provides basic CI/CD workflows.

## Usage

Choose `george-lim/basic-template` as the template when creating a new repository.

## Features

Basic Template provides a `README.md`, `LICENSE` and two workflows for GitHub Actions.

## Examples

There are no examples to provide for Basic Template.

## CI/CD

### Pipeline

There are two workflows in this repository. Each workflow supports manual triggering.

The `CI` workflow is automatically triggered whenever there is push activity in `main` or pull request activity towards `main`. It has one job:

1. Lint the codebase with GitHub's [Super-Linter](https://github.com/github/super-linter).

The `CD` workflow is automatically triggered whenever there is a tag pushed to the repository. It has one job:

1. Create a GitHub release with the tag.
