let dep = https://raw.githubusercontent.com/vmchale/atspkg/master/dhall/default-pkg.dhall
in
let prelude = https://raw.githubusercontent.com/vmchale/atspkg/master/dhall/atspkg-prelude.dhall

in dep //
  { libName = "atscntrb-hx-divideconquerpar"
  , dir = ".atspkg/contrib/atscntrb-bucs320-divideconquerpar"
  , url = "https://registry.npmjs.org/atscntrb-bucs320-divideconquerpar/-/atscntrb-bucs320-divideconquerpar-1.0.9.tgz"
  , libVersion = [1,0,9]
  , libDeps = prelude.mapPlainDeps [ "atscntrb-hx-divideconquer" ]
  }
