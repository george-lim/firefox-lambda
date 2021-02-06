import os

from playwright.sync_api import sync_playwright


def run(playwright):
    firefox_binary_path_str = os.environ.get("FIREFOX_BINARY_PATH")

    browser = None

    try:
        browser = playwright.firefox.launch(firefox_binary_path_str)
        page = browser.new_page()

        page.goto("https://www.mozilla.org")

        browser.close()
    except Exception:
        if browser:
            browser.close()

        raise


with sync_playwright() as playwright:
    run(playwright)
