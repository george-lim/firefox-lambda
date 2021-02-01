FROM public.ecr.aws/lambda/provided:al2 AS dev

# Add local lib64 folder to LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH

# Add NodeSource repo
RUN curl -sLO https://rpm.nodesource.com/setup_12.x \
  && bash setup_12.x \
  && rm setup_12.x

# Install dependencies
RUN yum install -y \
    amazon-linux-extras-1.6.13-1.amzn2 \
    clang-7.0.1-1.amzn2.0.2 \
    git-2.23.3-1.amzn2.0.1 \
    nodejs-12.20.1-1nodesource \
    python-devel-2.7.18-1.amzn2.0.2 \
    python3-devel-3.7.9-1.amzn2.0.1 \
  && yum groupinstall -y "Development Tools" \
  && amazon-linux-extras install -y \
    epel=stable \
    rust1=stable \
  && yum install -y \
    dbus-glib-devel-0.100-7.2.amzn2 \
    gtk2-devel-2.24.31-1.amzn2.0.2 \
    gtk3-devel-3.22.30-3.amzn2 \
    libXt-devel-1.1.5-3.amzn2.0.2 \
    llvm-devel-7.0.1-1.amzn2.0.1 \
    pango-devel-1.42.4-4.amzn2 \
    pulseaudio-libs-devel-10.0-3.amzn2.0.3 \
    yasm-devel-1.2.0-4.el7 \
  && yum clean all

# Build NSS 3.55
RUN curl -sLO https://ftp.mozilla.org/pub/security/nss/releases/NSS_3_55_RTM/src/nss-3.55-with-nspr-4.27.tar.gz \
  && tar -xf nss-3.55-with-nspr-4.27.tar.gz \
  && make -C nss-3.55/nss nss_build_all BUILD_OPT=1 USE_64=1 \
  && cp -RL nss-3.55/dist/"$(cat nss-3.55/dist/latest)"/lib/* /usr/local/lib64 \
  && rm -R nss-3.55 nss-3.55-with-nspr-4.27.tar.gz

# Link missing library in Firefox archive script
RUN mkdir -p /usr/lib/x86_64-linux-gnu \
  && ln -s /lib64/libstdc++.so.6.0.24 /usr/lib/x86_64-linux-gnu/libstdc++.so.6

# Build and archive Firefox from Playwright repo
RUN git config --global user.email you@example.com \
  && git clone https://github.com/microsoft/playwright.git \
  && ./playwright/browser_patches/prepare_checkout.sh firefox \
  && ./playwright/browser_patches/firefox/build.sh \
  && ./playwright/browser_patches/firefox/archive.sh "$PWD"/firefox.zip \
  && unzip firefox.zip -d /opt \
  && rm -R playwright firefox.zip

FROM public.ecr.aws/lambda/python:3.8 AS prod

# Copy Firefox
COPY --from=dev /opt/firefox /opt/firefox

# Install dependencies
RUN yum install -y \
    dbus-glib-0.100-7.2.amzn2 \
    gtk3-3.22.30-3.amzn2 \
    libXt-1.1.5-3.amzn2.0.2 \
  && yum clean all \
  && python3 -m pip install --no-cache-dir playwright==0.171.1

FROM prod AS test

# Copy test
COPY tests/test_goto_website.py .

# Run test
RUN python3 test_goto_website.py

FROM prod
