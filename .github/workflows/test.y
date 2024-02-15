name: "UI-Test"
on:
    pull_request:
        paths-ignore:
            - 'LICENSE'
            - 'docs/**'
    push:
        tags-ignore:
            - 'v*'
        paths-ignore:
            - '.txt'
            - '*.MD'
            - '*.md'
            - 'LICENSE'
            - 'docs/**'

jobs:
    build:
        runs-on: ubuntu-latest
        # display name of the job
        name: "Robot framework test"
        steps:
            # Uses an default action to checkout the code
            -   uses: actions/checkout@v3
            # Uses an action to add Python to the VM
            -   name: Setup Pyton
                uses: actions/setup-python@v4
                with:
                    python-version: '3.7'
                    architecture: x64
            # Uses an action to add JDK 17 to the VM (and mvn?)
            -   name: set up JDK 17
                uses: actions/setup-java@v3
                with:
                    distribution: 'temurin'
                    java-version: 17
                    architecture: x64
            #Uses an action to set up a cache using a certain key based on the hash of the dependencies
            -   name: Cache Maven packages
                uses: actions/cache@v3.3.1
                with:
                    path: ~/.m2
                    key: ubuntu-latest-m2-${{ hashFiles('**/pom.xml') }}
                    restore-keys: ubuntu-latest-m2-
            -   uses: BSFishy/pip-action@v1
                with:
                    packages: |
                        robotframework
                        robotframework-SeleniumLibrary
                        webdriver-manager
                        selenium==4.9.1
                    # TODO https://github.com/robotframework/SeleniumLibrary/issues/1835
            -   name: Run with Maven
                run: mvn --no-transfer-progress spring-boot:run &
            -   name: Wait to start
                uses: ifaxity/wait-on-action@v1
                with:
                    resource: http://127.0.0.1:8080/WebGoat
            -   name: Test with Robotframework
                run: python3 -m robot --variable HEADLESS:"1" --outputdir robotreport robot/goat.robot
            # send report to forks only due to limits on permission tokens
            -   name: Send report to commit
                if: github.repository != 'WebGoat/WebGoat' && github.event_name == 'push'
                uses: joonvena/robotframework-reporter-action@v2.2
                with:
                    gh_access_token: ${{ secrets.GITHUB_TOKEN }}
                    report_path: 'robotreport'
