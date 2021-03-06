-- ------ language="Haskell" file="test/Spec.hs"
{-# LANGUAGE DuplicateRecordFields #-}

import Test.Hspec
import Data.Complex
import Control.Applicative (liftA2)

import Data.Vector.Unboxed (Vector)
import qualified Data.Vector.Unboxed as V

import Array
import Lib
import TwiddleFactors

-- ------ begin <<test-predicates>>[0]
class Approx a where
    closeTo :: a -> a -> Bool

instance Approx Float where
    closeTo a b = abs (a - b) < 1e-5

instance Approx Double where
    closeTo a b = abs (a - b) < 1e-10

instance Approx a => Approx (Complex a) where
    closeTo (a :+ b) (c :+ d) = a `closeTo` c && b `closeTo` d

instance Approx a => Approx [a] where
    closeTo [] [] = True
    closeTo (a:as) (b:bs) = a `closeTo` b && as `closeTo` bs
    closeTo _ _ = False

-- instance (Approx a, Applicative m, Foldable m) => Approx (m a) where
--    closeTo x y = and $ liftA2 closeTo x y

instance {-# OVERLAPPING #-} (Approx a, V.Unbox a) => Approx (Vector a) where
    closeTo x y = V.and $ V.zipWith closeTo x y
-- ------ end

testTwiddleFactors :: Spec
testTwiddleFactors = do
    -- ------ begin <<test-twiddle-factors>>[0]
    describe "TwiddleFactors.indices" $
        it "creates an index list" $ do
            indices [2, 2] `shouldBe` [[0, 0], [1, 0], [0, 1], [1, 1]]
            indices [3, 1] `shouldBe` [[0, 0], [1, 0], [2, 0]]

    describe "TwiddleFactors.makeTwiddle" $
        it "Generates twiddle factors" $ do
            makeTwiddle [2, 2] `shouldSatisfy` closeTo
                (V.fromList [ 1.0, 0.0 :+ 1.0 ])
            makeTwiddle [4] `shouldSatisfy` closeTo
                (V.fromList [ 0.0 :+ 1.0, -1.0, 0.0 :+ (-1.0) ])
    -- ------ end

main :: IO ()
main = hspec $ do
    describe "Strides.fromShape" $
        it "computes strides from shapes" $ do
            fromShape [3, 3, 3] 1 `shouldBe` [1, 3, 9]
            fromShape [2, 3, 5] 1 `shouldBe` [1, 2, 6]

    describe "Strides.remove" $
        it "drops indexed entry from list" $ do
            remove [1, 2, 3, 4 :: Int] 0 `shouldBe` [2, 3, 4]
            remove [1, 2, 3, 4 :: Int] 2 `shouldBe` [1, 2, 4]

    describe "Strides.replace" $
        it "replaces entry at index" $ do
            replace [1, 2, 3, 4 :: Int] 0 7 `shouldBe` [7, 2, 3, 4]
            replace [1, 2, 3, 4 :: Int] 2 7 `shouldBe` [1, 2, 7, 4]

    describe "Strides.insert" $
        it "inserts entry at index" $ do
            insert [1, 2, 3, 4 :: Int] 0 7 `shouldBe` [7, 1, 2, 3, 4]
            insert [1, 2, 3, 4 :: Int] 2 7 `shouldBe` [1, 2, 7, 3, 4]

    let a1 = floatArray "test" [4, 5]
    describe "Strides.select" $
        it "selects sub-array" $ do
            let a103 = select 0 3 a1
            let a112 = select 1 2 a1
            (shape <$> a103) `shouldBe` Right [5]
            (stride <$> a103) `shouldBe` Right [4]
            (offset <$> a103) `shouldBe` Right 3
            (shape <$> a112) `shouldBe` Right [4]
            (stride <$> a112) `shouldBe` Right [1]
            (offset <$> a112) `shouldBe` Right 8

    testTwiddleFactors
-- ------ end
