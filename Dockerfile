FROM circleci/node:8

# install java 8
#
RUN if grep -q Debian /etc/os-release && grep -q jessie /etc/os-release; then \
    echo "deb http://http.us.debian.org/debian/ jessie-backports main" | sudo tee -a /etc/apt/sources.list \
    && echo "deb-src http://http.us.debian.org/debian/ jessie-backports main" | sudo tee -a /etc/apt/sources.list \
    && sudo apt-get update; sudo apt-get install -y -t jessie-backports openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; elif grep -q Ubuntu /etc/os-release && grep -q Trusty /etc/os-release; then \
    echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" | sudo tee -a /etc/apt/sources.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" | sudo tee -a /etc/apt/sources.list \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key DA1A4A13543B466853BAF164EB9B1D8886F44E2A \
    && sudo apt-get update; sudo apt-get install -y openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; else \
    sudo apt-get update; sudo apt-get install -y openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; fi

# install chrome
# Note: Revert back to https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# after browser testing works in google-chrome-stable 65.0.x.y

RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_64.0.3282.186-1_amd64.deb \
      && (sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb || sudo apt-get -fy install)  \
      && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
      && sudo sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' \
           "/opt/google/chrome/google-chrome" \
      && google-chrome --version

# RUN export CHROMEDRIVER_RELEASE=$(curl --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
#       && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
#       && cd /tmp \
#       && unzip chromedriver_linux64.zip \
#       && rm -rf chromedriver_linux64.zip \
#       && sudo mv chromedriver /usr/local/bin/chromedriver \
#       && sudo chmod +x /usr/local/bin/chromedriver \
#       && chromedriver --version

# install firefox

# If you are upgrading to any version newer than 47.0.1, you must check the compatibility with
# selenium. See https://github.com/SeleniumHQ/selenium/issues/2559#issuecomment-237079591

# RUN FIREFOX_URL="https://s3.amazonaws.com/circle-downloads/firefox-mozilla-build_47.0.1-0ubuntu1_amd64.deb" \
#   && curl --silent --show-error --location --fail --retry 3 --output /tmp/firefox.deb $FIREFOX_URL \
#   && echo 'ef016febe5ec4eaf7d455a34579834bcde7703cb0818c80044f4d148df8473bb  /tmp/firefox.deb' | sha256sum -c \
#   && sudo dpkg -i /tmp/firefox.deb || sudo apt-get -f install  \
#   && sudo apt-get install -y libgtk3.0-cil-dev libasound2 libasound2 libdbus-glib-1-2 libdbus-1-3 \
#   && rm -rf /tmp/firefox.deb \
#   && firefox --version

# Using the latest version of Firefox.

RUN FIREFOX_URL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/58.0/linux-x86_64/en-US/firefox-58.0.tar.bz2" \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/firefox.tar.bz2 $FIREFOX_URL \
  && echo '134fec04819eb56fa7b644cdd6d89623b21f4020bbedc3bd122db2a2caa4e434  /tmp/firefox.tar.bz2' | sha256sum -c \
  && sudo apt-get install -y libgtk3.0-cil-dev libasound2 libasound2 libdbus-glib-1-2 libdbus-1-3 \
  && cd /tmp \
  && tar xjf firefox.tar.bz2 \
  && rm -rf firefox.tar.bz2 \
  && sudo mv firefox /opt/firefox \
  && sudo ln -s /opt/firefox/firefox /usr/bin/firefox \
  && firefox --version

# install geckodriver—disabling this temporarily, we will likely want this code in the future, but until we're ready to upgrade our version of firefox to 53+, geckodriver wont' be compatible...

# RUN export GECKODRIVER_LATEST_RELEASE_URL=$(curl https://api.github.com/repos/mozilla/geckodriver/releases/latest | jq -r ".assets[] | select(.name | test(\"linux64\")) | .browser_download_url") \
#      && curl --silent --show-error --location --fail --retry 3 --output /tmp/geckodriver_linux64.tar.gz "$GECKODRIVER_LATEST_RELEASE_URL" \
#      && cd /tmp \
#      && tar xf geckodriver_linux64.tar.gz \
#      && rm -rf geckodriver_linux64.tar.gz \
#      && sudo mv geckodriver /usr/local/bin/geckodriver \
#      && sudo chmod +x /usr/local/bin/geckodriver \
#      && geckodriver --version

# start xvfb automatically to avoid needing to express in circle.yml
ENV DISPLAY :99
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
  && chmod +x /tmp/entrypoint \
        && sudo mv /tmp/entrypoint /docker-entrypoint.sh

# ensure that the build agent doesn't override the entrypoint
LABEL com.circleci.preserve-entrypoint=true

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/sh"]