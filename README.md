# macbooklog

A key & mouse logger for mac.

I wrote this software so that I can monitor my macbook usage on Kibana. It sends key & mouse logs to syslog.

_PLEASE DO NOT USE THIS SOFTWARE UNLESS YOU KNOW WHAT YOU ARE DOING!!_

## Usage

### Build

```
$ make
```

### Install

```
$ sudo make install
```

You need to do this for the first time you use this.

```
$ sudo launchctl load /Library/LaunchDaemons/macbooklog.plist
```

Next time you `make install` you need to do:

```
$ sudo launchctl stop macbooklog
$ sudo launchctl start macbooklog # somehow, doing `stop` does the `start` too, so this may not be needed
```

To make sure it's working

```
$ sudo tail -f /var/log/macbooklog.log
```

### Uninstall

```
$ sudo launchctl unload /Library/LaunchDaemons/macbooklog.plist
$ rm /Library/LaunchDaemons/macbooklog.plist
$ rm /usr/sbin/macbooklog
```

## Monitor logs on Kibana

Below settings are not needed to use this to just run the code.

### /etc/asl.conf

By default, identical syslog lines within 20 seconds or so are coalesced like

```
--- last message repeated 17 times ---
```

so write macbooklog's log to another file and set coalesce to false.

Add this line to the bottom.

```
? [= Facility macbooklog] file macbooklog.log file_max=1M all_max=5M coalesce=false
```

Then restart syslogd.

```
$ sudo launchctl stop com.apple.syslogd
$ sudo launchctl start com.apple.syslogd
```

### /etc/td-agent/td-agent.conf

Install [td-agent](http://docs.fluentd.org/articles/install-by-dmg).
(You can just use fluentd instead, but I thought using td-agent is easier when you daemonize it as root)

Install gems

 * `sudo /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-elasticsearch` (you need the Command Line Tool of XCode)
 * `sudo /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-sampling-filter`

```
<source>
  type tail
  path /var/log/macbooklog.log
  pos_file /tmp/macbooklog.pos
  tag macbooklog
  format syslog
</source>

<match macbooklog>
  type rewrite_tag_filter
  rewriterule1 message ^kCGEventKey             macbooklog.key
  rewriterule2 message ^kCGEventScrollWheel$    raw_macbooklog.mouse.scroll
  rewriterule3 message ^kCGEventMouseMoved$     raw_macbooklog.mouse.move
  rewriterule4 message ^kCGEventLeftMouseDown$  macbooklog.mouse.click
  rewriterule5 message ^kCGEventRightMouseDown$ macbooklog.mouse.click
</match>

<match raw_macbooklog.**>
  type sampling_filter
  interval 10
  remove_prefix raw_macbooklog
  add_prefix macbooklog
</match>

<match macbooklog.**>
  type elasticsearch
  host localhost
  port 9200
  logstash_format true
  logstash_prefix macbooklog
  include_tag_key true
  tag_key event
</match>
```

Then restart td-agent.

```
sudo launchctl stop td-agent
sudo launchctl start td-agent
```

### DANGEROUS: if you enable key code logging

BEWARE THAT ANYONE WHO HAS ACCESS TO YOUR COMPUTER CAN SEE YOUR PASSWORD.

You need fluent-plugin-sampling-filter as well.

 * `sudo /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-sampling-filter`

```
<source>
  type tail
  path /var/log/macbooklog.log
  pos_file /tmp/macbooklog.pos
  tag macbooklog
  format syslog
</source>

<match macbooklog>
  type rewrite_tag_filter
  rewriterule1 message ^kCGEventKey             raw.macbooklog.key
  rewriterule2 message ^kCGEventScrollWheel$    raw_macbooklog.mouse.scroll
  rewriterule3 message ^kCGEventMouseMoved$     raw_macbooklog.mouse.move
  rewriterule4 message ^kCGEventLeftMouseDown$  macbooklog.mouse.click
  rewriterule5 message ^kCGEventRightMouseDown$ macbooklog.mouse.click
</match>

<match raw_macbooklog.key>
  type parser
  remove_prefix raw_macbooklog
  add_prefix macbooklog
  format /^(?<message>kCGEventKey):(?<keycode>\\d+)$/
  key_name message
</match>

<match raw_macbooklog.mouse.*>
  type sampling_filter
  interval 10
  remove_prefix raw_macbooklog
  add_prefix macbooklog
</match>

<match macbooklog.**>
  type elasticsearch
  host localhost
  port 9200
  logstash_format true
  logstash_prefix macbooklog
  include_tag_key true
  tag_key event
</match>
```
