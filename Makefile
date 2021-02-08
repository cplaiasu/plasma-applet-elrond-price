.PHONY: install
install:
	kpackagetool5 -t Plasma/Applet --install ./package/

.PHONY: run
run:
	plasmoidviewer --applet ./package/

.PHONY: zip
zip:
	zip -r elrondprice-1.0.plasmoid ./package/
