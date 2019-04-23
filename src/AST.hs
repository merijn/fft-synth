-- ------ language="Haskell" file="src/AST.hs"
{-# LANGUAGE GADTs #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE FlexibleInstances,UndecidableInstances #-}

module AST where

import Data.Proxy
import Data.Text (Text)
import qualified Data.Text as T

-- import Data.Complex
import Array
import Lib

class (Show a) => Declarable a where
  typename :: proxy a -> Text

data Pointer a = Pointer deriving (Show)
newtype Function a b = Function Text deriving (Show)
newtype Variable a = Variable Text deriving (Show)
newtype Constant a = Constant Text deriving (Show)

instance Declarable Int where
  typename _ = "int"
instance Declarable Double where
  typename _ = "R"
instance Declarable a => Declarable (Pointer a) where
  typename _ = typename (Proxy :: Proxy a) <> "*"

data Range = Range
    { start :: Int
    , end   :: Int
    , step  :: Int } deriving (Show)

data Expr a where
    Literal        :: (Show a) => a -> Expr a
    IntegerValue   :: Int -> Expr Int
    RealValue      :: Double -> Expr Double
    -- ComplexValue   :: Complex Double -> Expr (Complex Double)
    ArrayRef       :: Array a -> Expr (Pointer a)
    VarReference   :: Variable a -> Expr a
    ConstReference :: Constant a -> Expr a
    ArrayIndex     :: Array a -> [Expr Int] -> Expr a
    TNull          :: Expr ()
    TCons          :: (Show a, Show b) => Expr a -> Expr b -> Expr (a, b)
    FunctionCall   :: (Show b) => Function a b -> Expr b -> Expr a

deriving instance Show a => Show (Expr a)

data Stmt where
    VarDeclaration   :: (Declarable a, Show a) => Variable a -> Stmt
    ConstDeclaration :: (Declarable a, Show a) => Constant a -> Stmt
    Expression       :: Expr () -> Stmt
    ParallelFor      :: Variable Int -> Range -> [Stmt] -> Stmt
    Assignment       :: (Show a) => Variable a -> Expr a -> Stmt

deriving instance Show Stmt

data FunctionDecl a b = FunctionDecl
  { functionName :: Text
  , argNames     :: [Text]
  , functionBody :: [Stmt] }

class Syntax a where
  generate :: a -> Text

instance Syntax (Expr a) where
  generate (Literal x) = tshow x
  generate (IntegerValue x) = tshow x
  generate (RealValue x) = tshow x
  generate (ArrayRef x) = name x <> " + " <> tshow (offset x)
  generate (VarReference (Variable x)) = x
  generate (ConstReference (Constant x)) = x
  generate (ArrayIndex a i) = name a <> "[<index expression>]"
  generate (FunctionCall (Function f) a) = ""
  generate (TCons a TNull) = generate a
  generate (TCons a b) = generate a <> ", " <> generate b
  generate TNull = ""

instance Syntax Stmt where
  generate (VarDeclaration v@(Variable x)) = typename v <> " " <> x <> ";"
  generate (ConstDeclaration v@(Constant x)) = typename v <> " const " <> x <> ";"
  generate (Expression e) = generate e <> ";"
  generate (ParallelFor (Variable v) (Range a b s) body) =
    "for (int " <> v <> "=" <> tshow a <> ";" <> v <> "<"
    <> tshow b <> ";" <> v <> "+=" <> tshow s <> ") {\n"
    <> T.unlines (map generate body) <> "\n}"
  generate (Assignment (Variable v) e) = v <> " = " <> generate e <> ";"
-- ------ end
