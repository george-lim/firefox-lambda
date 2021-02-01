from pathlib import Path

from playwright import sync_playwright

firefox_binary_path = Path("/opt/firefox/firefox")

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
