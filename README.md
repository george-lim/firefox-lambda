# Firefox Lambda

[![releases](https://img.shields.io/github/v/release/george-lim/firefox-lambda)](https://github.com/george-lim/firefox-lambda/releases)
[![ci](https://github.com/george-lim/firefox-lambda/workflows/CI/badge.svg)](https://github.com/george-lim/firefox-lambda/actions)
[![license](https://img.shields.io/github/license/george-lim/firefox-lambda)](https://github.com/george-lim/firefox-lambda/blob/main/LICENSE)

## [Usage](#usage) | [Features](#features) | [Examples](#examples) | [CI/CD](#cicd)

Firefox Lambda is a [Lambda container image](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html) that builds a Playwright-patched version of Firefox. It guarantees that Firefox will function properly with [Playwright](https://playwright.dev) on AWS Lambda.

## Usage

```text
Amazon ECR Public:         public.ecr.aws/l3g5a8a0/firefox-lambda
GitHub Container Registry: ghcr.io/george-lim/firefox-lambda
```

Firefox Lambda is published to Amazon ECR Public and GitHub Container Registry. The production image is configured to work with the Python 3.8 runtime out of the box.

### Supported tags

Tags are provided in the repository's [releases](https://github.com/george-lim/firefox-lambda/releases).

### Installation

To use Firefox Lambda directly, copy your Playwright python script to the image and modify the `executablePath` parameter in `firefox.launch(...)` to `/opt/firefox/firefox`.

To add Firefox to an existing image, you will need to additionally add a few build steps to your image:

1. Copy the `/opt/firefox` folder from Firefox Lambda.
2. Install `dbus-glib`, `gtk3`, and `libXt` packages with Yum.
3. Install Playwright in a supported runtime.

## Features

Playwright requires capabilities from Firefox that are not exposed natively without a [build patch](https://github.com/microsoft/playwright/tree/master/browser_patches). Thus, Firefox needs to be built with the patch applied in Amazon Linux 2 in order to work with Playwright.

Firefox Lambda builds Firefox from the AWS base image for Lambda, without any optional Firefox dependencies. The final production image copies the `/opt/firefox` folder into a Python 3.8 Lambda container image and installs all necessary Firefox and Playwright dependencies.

## Examples

### Add Firefox Lambda to an existing image

These snippets add Firefox Lambda to an existing Python Lambda container image.

`Dockerfile`

```dockerfile
FROM public.ecr.aws/l3g5a8a0/firefox-lambda:1.0.0 as firefox

FROM public.ecr.aws/lambda/python:3.8

# Copy Firefox
COPY --from=firefox /opt/firefox /opt/firefox

# Install dependencies
RUN yum install -y \
    dbus-glib-0.100-7.2.amzn2 \
    gtk3-3.22.30-3.amzn2 \
    libXt-1.1.5-3.amzn2.0.2 \
  && yum clean all \
  && python3 -m pip install --no-cache-dir playwright==0.171.1

COPY app.py /
CMD ["app.handler"]
```

`app.py`

```python
from pathlib import Path

from playwright import sync_playwright

firefox_binary_path = Path("/opt/firefox/firefox")


def handler(event, context):
    with sync_playwright() as api:
        browser = None

        try:
            browser = api.firefox.launch(firefox_binary_path)
            page = browser.newPage()

            page.goto("https://www.mozilla.org")

            browser.close()
        except Exception:
            if browser:
                browser.close()

            raise
```

## CI/CD

### Local image building

Because Firefox Lambda takes a very long time to build, it does not make sense to have GitHub Actions build the image. Instead, image building for CI/CD is done locally, and pushed to `ghcr.io/george-lim/firefox-lambda:latest-dev`. The `CD` workflow will then build the image from cache, and push the production tags to their respective registries.

```bash
docker buildx build \
    --tag ghcr.io/george-lim/firefox-lambda:latest-dev \
    --cache-to=type=registry,ref=ghcr.io/george-lim/firefox-lambda:latest-dev,mode=max \
    .
```

This will build Firefox Lambda and push the caches to GitHub Container Registry.

### Secrets

```yaml
AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

CR_PAT: "********"
```

These secrets must exist in the repository for the `CD` workflow to publish the image.
