all: tutorial-exe.eventlog

EXE = .stack-work/install/x86_64-linux-tinfo6/lts-13.14/8.6.4/bin/tutorial-exe

%.eventlog: tutorial-exe.eventlog
	cp tutorial-exe.eventlog $*.eventlog

tutorial-exe.eventlog: $(EXE)
	.stack-work/install/x86_64-linux-tinfo6/lts-13.14/8.6.4/bin/tutorial-exe  +RTS -N3 -ls

$(EXE): app/Main.hs
	stack build --force-dirty --ghc-options="-O2 -threaded -rtsopts -eventlog -feager-blackholing"

unlimited:
	ulimit -Sv unlimited