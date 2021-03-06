let LibDep = https://raw.githubusercontent.com/vmchale/atspkg/master/dhall/types/LibDep.dhall
in

let dep =
  { dir = ".atspkg/contrib"
  , libVersion = [0,1,0]
  , libDeps = []
    : List LibDep
  , libBldDeps = []
    : List LibDep
  , description = []
    : Optional Text
  }
in dep
