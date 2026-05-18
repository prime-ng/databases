# Installation Prime-AI App (on Web & on Mobile)
================================================

## Installation on Mac
======================
I need you to set up a complete React Native development environment on my Mac. Execute the following steps in order, verifying each one before proceeding to the next.
 
**STEP 1: Verify & Install Homebrew**
- Check if `brew` exists. If not, install it with: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Run `brew doctor` and fix any warnings
 
**STEP 2: Install Node.js 22 (LTS) via fnm**
- Check if `fnm` exists. If not, install: `curl -fsSL https://fnm.vercel.app/install | bash`
- Install Node 22: `fnm install 22 && fnm use 22 && fnm default 22`
- Verify: `node --version` must return v22.x
 
**STEP 3: Install Watchman**
- Run: `brew install watchman`
- Verify: `watchman --version`
 
**STEP 4: Install JDK 17**
- Run: `brew install --cask zulu@17`
- Add to `~/.zshrc`: `export JAVA_HOME=$(/usr/libexec/java_home -v 17)`
- Reload shell config and verify: `java -version`
 
**STEP 5: Install Xcode Command Line Tools**
- Run: `xcode-select --install` (if not already installed)
- Verify: `xcode-select --print-path` returns `/Applications/Xcode.app/Contents/Developer`
- If wrong path, run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

(since I was having macOS Sequoia 15.7.7, I downoaded older version of xcode-16)


**STEP 6: Install CocoaPods**
- Run: `sudo gem install cocoapods`
- If permission denied, install rbenv first: `brew install rbenv && rbenv install 3.2.2 && rbenv global 3.2.2 && gem install cocoapods`
- Verify: `pod --version`
 
**STEP 7: Install Android Studio & SDK**
- Run: `brew install --cask android-studio`
- Add to `~/.zshrc`:

-------------------------------------------------------------------------------------------
Get Application from Git in different Repositories (Different Folder for Web & Mobile apps in Local)

set local IP address & Port in .env file of both Mobile app folders
like in my case - 192.168.29.100:8000

Use below command to get IP address on Mac:
ipconfig getifaddr en0

For first time only :
Open Terminal on mobile_student and run below commands:
