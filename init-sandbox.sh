#! /bin/sh

cabal sandbox init

cabal sandbox add-source deps/snaplet-postgresql-simple
cabal sandbox add-source deps/snap/deps/io-streams
cabal sandbox add-source deps/snap/deps/io-streams-haproxy
cabal sandbox add-source deps/snap/deps/snap-core
cabal sandbox add-source deps/snap/deps/snap-server
cabal sandbox add-source deps/snap/deps/xmlhtml
cabal sandbox add-source deps/snap/deps/heist
cabal sandbox add-source deps/snap
cabal sandbox add-source deps/servant-snap/deps/snap-loader-dynamic
cabal sandbox add-source deps/servant-snap/deps/snap-loader-static
cabal sandbox add-source deps/servant-snap/deps/hspec-snap

cabal sandbox add-source deps/servant-snap/deps/servant/servant
cabal sandbox add-source deps/servant-snap/deps/servant/servant-docs
cabal sandbox add-source deps/servant-snap/deps/servant/servant-client
cabal sandbox add-source deps/servant-snap/deps/servant/servant-blaze
cabal sandbox add-source deps/servant-snap/deps/servant/servant-foreign
cabal sandbox add-source deps/servant-snap/deps/servant/servant-js
cabal sandbox add-source deps/servant-snap/deps/servant/servant-lucid
cabal sandbox add-source deps/servant-snap/deps/servant/servant-mock
cabal sandbox add-source deps/servant-snap/deps/servant/servant-server

cabal sandbox add-source deps/websockets-snap

cabal sandbox add-source deps/servant-snap/

cabal sandbox add-source deps/servant-matlab/

cabal sandbox add-source ./cbaas-lib

cd cbaas-lib   && cabal sandbox init --sandbox=../.cabal-sandbox && cd ..
cd cbaas-server   && cabal sandbox init --sandbox=../.cabal-sandbox && cd ..
cd cbaas-frontend && cabal sandbox init --sandbox=../.cabal-sandbox && cd ..
