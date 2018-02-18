module Data.Dependency.Sort ( sortDeps
                            ) where

import           Data.Dependency.Type
import           Data.Graph
import           Lens.Micro
import           Lens.Micro.Extras

asGraph :: [Dependency] -> (Graph, Vertex -> Dependency)
asGraph ds = (f triple, keys)
    where triple = graphFromEdges (zip3 ds (_libName <$> ds) (fmap fst . _libDependencies <$> ds))
          f = view _1
          s = view _2
          keys = view _1 . s triple

sortDeps :: [Dependency] -> [Dependency]
sortDeps ds = fmap find . topSort $ g
    where (g, find) = asGraph ds
