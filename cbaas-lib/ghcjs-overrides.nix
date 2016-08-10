{ reflex-platform, ... }:
let

  dontCheck = (import <nixpkgs> {}).pkgs.haskell.lib.dontCheck;
  cabal2nixResult = reflex-platform.cabal2nixResult;
  nixpkgs = (import <nixpkgs> {});
in
reflex-platform.ghcjs.override {
  overrides = self: super: { 
     # inherit (nixpkgs.haskellPackages) lens clock lens-aeson wreq HUnit;
     #servant-snap        = dontCheck (self.callPackage (cabal2nixResult ../deps/servant-snap) {});
     #hspec-snap          = dontCheck (self.callPackage (cabal2nixResult ../deps/servant-snap/deps/hspec-snap) {});
     #groundhog-th        = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog/groundhog-th) {}); 
     #roundhog-postgresql = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog/groundhog-postgresql) {});
     groundhog = dontCheck (self.callPackage (cabal2nixResult ../../throwaway/groundhog/groundhog) {});
     groundhog-th = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog-ghcjs) {});
     groundhog-postgresql = dontCheck (self.callPackage (cabal2nixResult ../deps/groundhog-ghcjs) {});
     #groundhog-postgresql = dontCheck (self.callPackage (cabal2nixResult ../../throwaway/groundhog/groundhog-postgresql) {});
  };
}
