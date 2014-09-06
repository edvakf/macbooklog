.PHONY: all
all:
	clang macbooklog.m -o macbooklog -framework Cocoa

.PHONY: install
install:
	cp macbooklog /usr/sbin/macbooklog
	cp macbooklog.plist /Library/LaunchDaemons/macbooklog.plist
	launchctl load /Library/LaunchDaemons/macbooklog.plist
	launchctl stop macbooklog
	launchctl start macbooklog
	cp macbooklog.asl.conf /etc/asl/macbooklog
	launchctl stop com.apple.syslogd
	launchctl start com.apple.syslogd

.PHONY: uninstall
uninstall:
	rm /usr/sbin/macbooklog
	launchctl unload /Library/LaunchDaemons/macbooklog.plist
	rm /Library/LaunchDaemons/macbooklog.plist
	rm /etc/asl/macbooklog
	launchctl stop com.apple.syslogd
	launchctl start com.apple.syslogd

.PHONY: clean
clean:
	rm macbooklog
