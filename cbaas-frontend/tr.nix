{ reflex-platform, ... }:
let

  dontCheck = reflex-platform.lib.dontCheck;
  cabal2nixResult = reflex-platform.cabal2nixResult;
in
reflex-platform.ghcjs.override {
  overrides = self: super: { 
     reflex-dom-contrib   = dontCheck (self.callPackage (cabal2nixResult ../deps/reflex-dom-contrib) {});
     groundhog            = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog/groundhog) {});
     groundhog-th         = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog/groundhog-th) {});
     groundhog-ghcjs      = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog-ghcjs) {});
     groundhog-postgresql = null;
     cbaas-lib            = dontCheck (self.callPackage ../cbaas-lib {  });
     http-api-data        = dontCheck (self.callPackage (cabal2nixResult ../deps/http-api-data) {  });
     servant        = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant) {  });
     servant-js        = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant-js) {  });
     servant-foreign        = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant-foreign) {  });
     servant-docs        = dontCheck (self.callPackage (cabal2nixResult ../deps/servant/servant-docs) {  });
     reflex-dom-semui    = dontCheck (self.callPackage (cabal2nixResult ../deps/reflex-dom-semui){});
     # reflex-dom-semui    = dontCheck (self.callPackage (cabal2nixResult ../../reflex-dom-semui){});
  };
}
