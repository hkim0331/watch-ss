all:
	@echo make isc
	@echo do not forget checking DEBUG flag.

isc:
	sed -i.bak 's/DEBUG *= *true/DEBUG = false/' watch-ss.rb
	install -m 0755 watch-ss.rb /edu/bin/watch-ss
	install -m 0644 warn.jpg /edu/lib/watch-ss/warn.jpg

clean:
	${RM} *~


