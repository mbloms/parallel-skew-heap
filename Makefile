all: tutorial-exe.eventlog


EXE = .stack-work/install/x86_64-linux/lts-13.14/8.6.4/bin/tutorial-exe

# Symlink för kompatibilitet
.stack-work/install/x86_64-linux:
	ln -sfT x86_64-linux-tinfo6 .stack-work/install/x86_64-linux

%.eventlog: tutorial-exe.eventlog
	cp tutorial-exe.eventlog $*.eventlog

tutorial-exe.eventlog: $(EXE) .stack-work/install/x86_64-linux
	$(EXE)  +RTS -N3 -ls

$(EXE): app/Main.hs src
	stack build --force-dirty --ghc-options="-O2 -threaded -rtsopts -eventlog -feager-blackholing"

# Få stack att sluta klaga på att src inte finns:
src:
	mkdir -p src

unlimited:
	ulimit -Sv unlimited