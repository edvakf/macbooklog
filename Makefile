.PHONY: all
all:
	clang macbooklog.m -o macbooklog -framework Cocoa

.PHONY: install
install:
	cp macbooklog /usr/sbin/macbooklog
	cp macbooklog.plist /Library/LaunchDaemons/

.PHONY: clean
clean:
	rm macbooklog
