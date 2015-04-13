all:
	@echo make isc

isc:
	install -m 0755 watch-ss.rb /edu/bin/watch-ss
	install -m 0644 warn.jpg /edu/lib/watch-ss/warn.jpg

clean:
	${RM} *~


