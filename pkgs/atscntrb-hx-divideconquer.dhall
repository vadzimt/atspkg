let dep = https://raw.githubusercontent.com/vmchale/atspkg/master/dhall/default-pkg.dhall

in dep //
  { libName = "atscntrb-hx-divideconquer"
  , dir = ".atspkg/contrib/atscntrb-bucs320-divideconquer"
  , url = "https://registry.npmjs.org/atscntrb-bucs320-divideconquer/-/atscntrb-bucs320-divideconquer-1.0.5.tgz"
  , libVersion = [1,0,5]
  , libDeps = [ "atscntrb-hx-fworkshop", "atscntrb-hx-threadkit" ]
  }
