{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

-- TODO export list

module Debug
  ( ppHieFile,
    ppParsedModule,
  )
where

import Control.Monad.RWS
import Data.Map qualified as M
import FastString qualified as GHC
import HieTypes hiding (nodeInfo)
import Module qualified as GHC
import Name
import Parse
import Printer
import SrcLoc

ppParsedModule :: Prints Module
ppParsedModule (Module name path decls imps) = do
  strLn $ name <> " " <> path
  indent $ mapM_ strLn imps

ppHieFile :: Prints HieFile
ppHieFile (HieFile path mdl _types (HieASTs asts) _exps _src) = do
  strLn path
  indent $ do
    strLn . showModuleName $ GHC.moduleName mdl
    forM_ (M.toList asts) $ \(fp, ast) -> do
      strLn $ GHC.unpackFS fp
      indent $ ppHieAst ast

ppHieAst :: Prints (HieAST a)
ppHieAst (Node (NodeInfo anns _types ids) srcSpan children) = do
  strLn $ "Node " <> showSpan srcSpan
  indent $ do
    forM_ anns $ strLn . show
    forM_ (M.toList ids) $ \(idn, IdentifierDetails _type ctxInfo) -> do
      strLn $ either showModuleName showName idn
      indent $ mapM_ (strLn . show) ctxInfo
    mapM_ ppHieAst children

showName :: Name -> String
showName = show . occNameString . nameOccName

showModuleName :: GHC.ModuleName -> String
showModuleName = flip mappend " (module)" . show . GHC.moduleNameString

showSpan :: RealSrcSpan -> String
showSpan s =
  mconcat
    [ show $ srcSpanStartLine s,
      ":",
      show $ srcSpanStartCol s,
      " - ",
      show $ srcSpanEndLine s,
      ":",
      show $ srcSpanEndCol s
    ]