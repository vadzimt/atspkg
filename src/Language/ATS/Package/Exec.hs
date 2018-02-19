{-# LANGUAGE OverloadedStrings #-}

module Language.ATS.Package.Exec ( exec
                                 ) where

import           Control.Composition
import           Control.Lens               hiding (List, argument)
import           Data.Bool                  (bool)
import           Data.Maybe                 (fromMaybe)
import           Data.Semigroup             (Semigroup (..))
import qualified Data.Text.Lazy             as TL
import           Data.Version               hiding (Version (..))
import           Development.Shake.ATS
import           Development.Shake.FilePath
import           Language.ATS.Package
import           Options.Applicative        hiding (auto)
import qualified Paths_ats_pkg              as P
import           System.Directory
import           System.IO.Temp             (withSystemTempDirectory)

-- TODO command to list available packages.
wrapper :: ParserInfo Command
wrapper = info (helper <*> versionInfo <*> command')
    (fullDesc
    <> progDesc "The atspkg build tool for ATS-Postiats."
    <> header "atspkg - a build tool for ATS\nsee 'man atspkg' for more detailed help")

versionInfo :: Parser (a -> a)
versionInfo = infoOption ("atspkg version: " ++ showVersion P.version) (short 'V' <> long "version" <> help "Show version")

data Command = Install
             | Build { _targets    :: [String]
                     , _recache    :: Bool
                     , _archTarget :: Maybe String
                     , _rebuildAll :: Bool
                     , _verbosity  :: Int
                     , _lint       :: Bool
                     }
             | Clean
             | Test { _targets :: [String], _lint :: Bool }
             | Fetch { _url :: String }
             | Nuke
             | Upgrade
             | Valgrind { _targets :: [String] }
             | Run { _targets :: [String] }
             | Check { _filePath :: String, _details :: Bool }
             | List

command' :: Parser Command
command' = hsubparser
    (command "install" (info (pure Install) (progDesc "Install all binaries to $HOME/.local/bin"))
    <> command "clean" (info (pure Clean) (progDesc "Clean current project directory"))
    <> command "remote" (info fetch (progDesc "Fetch and install a binary package"))
    <> command "build" (info build' (progDesc "Build current package targets"))
    <> command "test" (info test' (progDesc "Test current package"))
    <> command "nuke" (info (pure Nuke) (progDesc "Uninstall all globally installed libraries"))
    <> command "upgrade" (info (pure Upgrade) (progDesc "Upgrade to the latest version of atspkg"))
    <> command "valgrind" (info valgrind (progDesc "Run generated binaries through valgrind"))
    <> command "run" (info run' (progDesc "Run generated binaries"))
    <> command "check" (info check' (progDesc "Check pkg.dhall file to ensure it is well-typed."))
    <> command "list" (info (pure List) (progDesc "List available packages"))
    )

check' :: Parser Command
check' = Check
    <$> targetP dhallCompletions id "check"
    <*> switch
    (long "detailed"
    <> short 'd'
    <> help "Enable detailed error messages")

ftypeCompletions :: String -> Mod ArgumentFields a
ftypeCompletions ext = completer . bashCompleter $ "file -X '!*." ++ ext ++ "' -o plusdirs"

dhallCompletions :: Mod ArgumentFields a
dhallCompletions = ftypeCompletions "dhall"

run' :: Parser Command
run' = Run <$> targets "run"

test' :: Parser Command
test' = Test <$> targets "test" <*> noLint

valgrind :: Parser Command
valgrind = Valgrind <$> targets "run with valgrind"

targets :: String -> Parser [String]
targets = targetP mempty many

targetP :: Mod ArgumentFields String -> (Parser String -> a) -> String -> a
targetP completions f s = f
    (argument str
    (metavar "TARGET"
    <> help ("Targets to " <> s)
    <> completions))

build' :: Parser Command
build' = Build
    <$> targets "build"
    <*> switch
        (long "no-cache"
        <> short 'c'
        <> help "Turn off configuration caching")
    <*> optional
        (strOption
        (long "target"
        <> short 't'
        <> help "Set target by using its triple"))
    <*> switch
        (long "rebuild"
        <> short 'r'
        <> help "Force rebuild of all targets")
    <*> (length <$>
        many (flag' () (short 'v' <> long "verbose" <> help "Turn up verbosity")))
    <*> noLint

noLint :: Parser Bool
noLint = fmap not
    (switch
    (long "no-lint"
    <> short 'l'
    <> help "Disable the shake linter"))

fetch :: Parser Command
fetch = Fetch <$>
    argument str
    (metavar "URL"
    <> help "URL pointing to a tarball containing the package to be installed.")

fetchPkg :: String -> IO ()
fetchPkg pkg = withSystemTempDirectory "atspkg" $ \p -> do
    let (lib, dirName, url') = (mempty, p, pkg) & each %~ TL.pack
    buildHelper True (ATSDependency lib dirName url' undefined mempty)
    ps <- getSubdirs p
    pkgDir <- fromMaybe p <$> findFile (p:ps) "atspkg.dhall"
    let a = withCurrentDirectory (takeDirectory pkgDir) (mkPkg False False False mempty ["install"] Nothing 0)
    bool (buildAll (Just pkgDir) >> a) a =<< check (Just pkgDir)

exec :: IO ()
exec = execParser wrapper >>= run

runHelper :: Bool -> Bool -> Bool -> [String] -> Maybe String -> Int -> IO ()
runHelper rb rba lint rs tgt v = bool
    (mkPkg rb rba lint [buildAll Nothing] rs tgt v)
    (mkPkg rb rba lint mempty rs tgt v)
    =<< check Nothing

run :: Command -> IO ()
run List = displayList "https://raw.githubusercontent.com/vmchale/atspkg/master/pkgs/pkg-set.dhall"
run (Check p b) = print =<< checkPkg p b
run Upgrade = upgradeAtsPkg
run Nuke = cleanAll
run (Fetch u) = fetchPkg u
run Clean = mkPkg False False True mempty ["clean"] Nothing 0
run (Build rs rb tgt rba v lint) = runHelper rb rba lint rs tgt v
run (Test ts lint) = runHelper False False lint ("test" : ts) Nothing 0
run c = runHelper False False True rs Nothing 0
    where rs = g c
          g Install       = ["install"]
          g (Valgrind ts) = "valgrind" : ts
          g (Run ts)      = "run" : ts
          g _             = undefined
