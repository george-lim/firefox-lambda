# Firefox Lambda

[![releases](https://img.shields.io/github/v/release/george-lim/firefox-lambda)](https://github.com/george-lim/firefox-lambda/releases)
[![ci](https://github.com/george-lim/firefox-lambda/workflows/CI/badge.svg)](https://github.com/george-lim/firefox-lambda/actions)
[![license](https://img.shields.io/github/license/george-lim/firefox-lambda)](https://github.com/george-lim/firefox-lambda/blob/main/LICENSE)

## [Usage](#usage) | [Features](#features) | [Examples](#examples) | [CI/CD](#cicd)

Firefox Lambda is a [Lambda container image](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html) that provides a [Playwright](https://playwright.dev)-patched version of Firefox. The image is built for the Python 3.8 runtime, and allows Firefox to be run both headfully or headlessly.

## Usage

```text
Amazon ECR Public:         public.ecr.aws/george-lim/firefox-lambda
GitHub Container Registry: ghcr.io/george-lim/firefox-lambda
```

Firefox Lambda is published to Amazon ECR Public and GitHub Container Registry.

### Supported tags

Tags are provided in the repository's [releases](https://github.com/george-lim/firefox-lambda/releases).

### Installation

In your Lambda function code, modify the executable path of the `firefox.launch` call to the environment variable `FIREFOX_PATH`. Then, `COPY` the code into the Firefox Lambda image as usual - that's it!

To optionally configure the screen size of Xvfb, set the environment variable `XVFB_WHD` in your `Dockerfile`. The default value is `1280x720x16`.

## Features

Playwright requires capabilities from Firefox that are not exposed natively without a [build patch](https://github.com/microsoft/playwright/tree/master/browser_patches). Thus, Firefox needs to be specifically built and patched in Amazon Linux 2 in order to work with Playwright.

Firefox Lambda builds Firefox from the AWS base image for Lambda, without any optional Firefox dependencies. The final production image copies the `/opt/firefox/` folder into a Python 3.8 Lambda container image and installs all necessary Firefox and Playwright dependencies.

Additionally, [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml) is installed and configured in the production image so that Firefox can run headfully.

## Examples

### Start Playwright inside a Lambda function

These snippets show how to start Playwright inside a Lambda function.

`Dockerfile`

```dockerfile
FROM public.ecr.aws/george-lim/firefox-lambda:1.1.0

# Optional
ENV XVFB_WHD=1280x720x16

COPY app.py $LAMBDA_TASK_ROOT
CMD ["app.handler"]
```

`app.py`

```python
import os

from playwright.sync_api import sync_playwright


def run(playwright):
    firefox_path = os.environ.get("FIREFOX_PATH")
    browser = None

    try:
        browser = playwright.firefox.launch(
            executable_path=firefox_path, headless=False
        )

        page = browser.new_page()
        page.goto("https://www.mozilla.org")

        browser.close()
    except Exception:
        if browser:
            browser.close()

        raise


def handler(event, context):
    with sync_playwright() as playwright:
        run(playwright)
```

## CI/CD

### Local image building

Building Firefox Lambda during CI/CD takes too long. Thus, image building for CI/CD is done locally, and cached to `ghcr.io/george-lim/firefox-lambda:latest-dev`. The `CD` workflow will then build the image from cache, and push production tags to the respective registries.

```bash
docker login ghcr.io -u george-lim --password-stdin

docker buildx build \
    --tag ghcr.io/george-lim/firefox-lambda:latest-dev \
    --cache-to=type=registry,ref=ghcr.io/george-lim/firefox-lambda:latest-dev,mode=max \
    .
```

This will build Firefox Lambda and push the caches to GitHub Container Registry.

You will need to create a [Personal Access Token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) on GitHub with `write:packages` and `read:packages` scopes in order to push the caches. Supply the Personal Access Token as the password when logging in.

### Secrets

```yaml
AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

CR_PAT: "********"
```

These secrets must exist in the repository for the `CD` workflow to publish the image.
