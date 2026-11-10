# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

~/.automated_script.sh

# Start the installer once on the first console. Quitting it leaves this shell,
# where `soninstall` starts it again.
if [[ $(tty) == /dev/tty1 && ! -e /run/soninstall-started ]]; then
    touch /run/soninstall-started
    soninstall
fi
