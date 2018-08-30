{-# LANGUAGE ScopedTypeVariables #-}
module Unison.Test.Typechecker.TypeError where

import           Data.Foldable                (toList)
import           Data.Maybe                   (isJust)
import           EasyTest
import qualified Unison.FileParsers           as FileParsers
import           Unison.Parser                (Ann)
import           Unison.Result                (Result (..))
import qualified Unison.Result                as Result
import           Unison.Symbol                (Symbol)
import qualified Unison.Typechecker.Context   as C
import           Unison.Typechecker.Extractor2 (NoteExtractor)
import qualified Unison.Typechecker.Extractor2 as Ex
import qualified Unison.Typechecker.TypeError as Err
import           Unison.Var                   (Var)

test :: Test ()
test = scope "extractor" . tests $
  [ y "and true 3" Err.and
  , y "or true 3" Err.or
  , y "if 3 then 1 else 2" Err.cond
  , y "if true then 1 else \"surprise\"" Err.ifBody
  , y "case 3 of 3 | 3 -> 3" Err.matchGuard
  , y "case 3 of\n 3 -> 3\n 4 -> \"surprise\"" Err.matchBody
  -- , y "case 3 of true -> true" Err.
  , y "[1, +1]" Err.vectorBody
  , n "and true ((x -> x + 1) true)" Err.and
  , n "or true ((x -> x + 1) true)" Err.or
  , n "if ((x -> x + 1) true) then 1 else 2" Err.cond
  , n "case 3 of 3 | 3 -> 3" Err.matchBody
  , y "1 1" Err.applyingNonFunction
  , y "1 Int64.+ 1" Err.applyingFunction
  ]
  where y, n :: String -> NoteExtractor Symbol Ann a -> Test ()
        y s ex = scope s $ expect $ yieldsError s ex
        n s ex = scope s $ expect $ noYieldsError s ex

noYieldsError :: Var v => String -> NoteExtractor v Ann a -> Bool
noYieldsError s ex = not $ yieldsError s ex

yieldsError :: forall v a. Var v => String -> NoteExtractor v Ann a -> Bool
yieldsError s ex = let
  Result notes (Just _) = FileParsers.parseAndSynthesizeAsFile "test" s
  notes' :: [C.Note v Ann]
  notes' = [ n | Result.Typechecking n <- toList notes ]
  in any (isJust . Ex.runNote ex) notes'
