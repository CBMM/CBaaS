{ reflex-platform, ... }:
let
  dontCheck = reflex-platform.lib.dontCheck;
  cabal2nixResult = reflex-platform.cabal2nixResult;
in
reflex-platform.ghc.override {
  overrides = self: super: { 

     cbaas-lib            = dontCheck (self.callPackage (cabal2nixResult ../cbaas-lib) {});
     #cbaas-lib            = dontCheck (self.callPackage ../cbaas-lib {});

     servant-snap         = dontCheck (self.callPackage (cabal2nixResult ../deps/servant-snap) {});
     groundhog-th         = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog/groundhog-th) {} );
     groundhog            = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog/groundhog) {} );
     groundhog-postgresql = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog/groundhog-postgresql) {} );

     websockets-snap = (self.callPackage (reflex-platform.cabal2nixResult ../deps/websockets-snap) {});

     snaplet-postgresql-simple = (self.callPackage (reflex-platform.cabal2nixResult ../deps/snaplet-postgresql-simple) {});

     # Until reflex-platform is on a nixpkgs with snap1.0
     snap                = dontCheck (self.callPackage (cabal2nixResult ../deps/snap) {});
     io-streams          = dontCheck (self.callPackage (cabal2nixResult ../deps/snap/deps/io-streams) {});
     io-streams-haproxy  = dontCheck (self.callPackage (cabal2nixResult ../deps/snap/deps/io-streams-haproxy) {});
     heist               = dontCheck (self.callPackage (cabal2nixResult ../deps/snap/deps/heist) {});
     xmlhtml             = dontCheck (self.callPackage (cabal2nixResult ../deps/snap/deps/xmlhtml) {});
     snap-core           = dontCheck (self.callPackage (cabal2nixResult ../deps/snap/deps/snap-core) {});
     snap-server         = dontCheck (self.callPackage (cabal2nixResult ../deps/snap/deps/snap-server) {});
     snap-loader-static  = dontCheck (self.callPackage (cabal2nixResult ../deps/snap-loader-static) {});
     snap-loader-dynamic = dontCheck (self.callPackage (cabal2nixResult ../deps/snap-loader-dynamic) {});

     servant             = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant) {});
     servant-foreign     = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant-foreign) {});
     servant-js          = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant-js) {});
     servant-docs        = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant-docs) {});
     http-api-data       = dontCheck (self.callPackage (cabal2nixResult ../deps/http-api-data) {});
     Glob                = dontCheck (self.callPackage (cabal2nixResult ../deps/glob) {});
  };
}
