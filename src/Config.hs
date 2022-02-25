module Config
  ( RenderConfig (..),
    SearchConfig (..),
    OutputConfig (..),
    DebugConfig (..),
    AppConfig (..),
    pConfig,
    Filter,
    match,
  )
where

import Options.Applicative

newtype Filter = Filter String

match :: [Filter] -> [Filter] -> String -> Bool
match [] [] str = True
match [] exes str = not (any (flip matchOne str) exes)
match ins exes str = any (flip matchOne str) ins && not (any (flip matchOne str) exes)

matchOne :: Filter -> String -> Bool
matchOne (Filter matcher) = go False matcher
  where
    go _ ('*' : ms) cs = go True ms cs
    go _ (m : ms) (c : cs) | m == c = go False ms cs || go True (m : ms) cs
    go True ms (_ : cs) = go True ms cs
    go _ [] [] = True
    go _ _ _ = False

data AppConfig = AppConfig
  { searchConfig :: SearchConfig,
    renderConfig :: RenderConfig,
    outputConfig :: OutputConfig,
    debugConfig :: DebugConfig
  }

data SearchConfig = SearchConfig
  { searchDotPaths :: Bool,
    searchRoots :: [FilePath],
    includeFilters :: [Filter], -- TODO this should be a Maybe NonEmpty
    excludeFilters :: [Filter] -- TODO this should be a Maybe NonEmpty
  }

-- TODO no clusters
-- TODO sourceLocs
-- TODO qualified names
-- TODO LR rankdir
-- TODO move to Render module
-- TODO these are mostly "filtering" options, with the exception of splines
data RenderConfig = RenderConfig
  { showCalls :: Bool,
    splines :: Bool,
    reverseDependencyRank :: Bool
  }

data OutputConfig
  = OutputStdOut
  | OutputFile FilePath
  | OutputPng FilePath

pConfig :: Parser AppConfig
pConfig = AppConfig <$> pSearchConfig <*> pRenderConfig <*> pOutputConfig <*> pDebugConfig

pSearchConfig :: Parser SearchConfig
pSearchConfig =
  SearchConfig
    <$> switch
      ( long "hidden"
          <> help "Search paths with a leading period. Disabled by default."
      )
    <*> many
      ( strOption
          ( long "input"
              <> short 'i'
              <> help "Filepaths to search. If passed a file, it will be processed as is. If passed a directory, the directory will be searched recursively. Can be specified multiple times. Defaults to ./."
          )
      )
    <*> many
      ( Filter
          <$> strOption
            ( long "module"
                <> short 'm'
                <> help "Only include modules that match the specified pattern. Can contain '*' wildcards. Can be specified multiple times"
            )
      )
    <*> many
      ( Filter
          <$> strOption
            ( long "exclude"
                <> short 'e'
                <> help "Exclude modules that match the specified pattern. Can contain '*' wildcards. Can be specified multiple times"
            )
      )

pRenderConfig :: Parser RenderConfig
pRenderConfig =
  RenderConfig
    <$> flag True False (long "hide-calls" <> help "Don't show function call arrows")
    <*> flag True False (long "no-splines" <> help "Render arrows as straight lines instead of splines")
    <*> flag False True (long "reverse-dependency-rank" <> short 'r' <> help "Make dependencies have lower rank than the dependee, i.e. show dependencies above their parent.")

-- TODO allow output to multiple places
pOutputConfig :: Parser OutputConfig
pOutputConfig =
  OutputFile <$> strOption (long "output-dot")
    <|> OutputPng <$> strOption (long "output-png")
    <|> pure OutputStdOut

data DebugConfig = DebugConfig
  { dumpHie :: Bool,
    dumpParseTree :: Bool
  }

pDebugConfig :: Parser DebugConfig
pDebugConfig =
  DebugConfig
    <$> switch (long "dump-hie")
    <*> switch (long "dump-parse-tree")
