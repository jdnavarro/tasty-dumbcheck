{-# LANGUAGE CPP #-}
#if __GLASGOW_HASKELL__ <= 710
{-# LANGUAGE DeriveDataTypeable #-}
#endif
module Test.DumbCheck where

#if !MIN_VERSION_base(4,8,0)
import Control.Applicative (Applicative, (<$>), (<*>), pure)
#endif
import Control.Applicative (liftA2, liftA3)
import Control.Monad (replicateM)
import Data.Char (isAlphaNum)
import Data.Foldable (find)
import Data.List (elemIndex)
import Data.Monoid (Product(..), Sum(..))

type Series a = [a]

type Property a = a -> Bool

class Serial a where
    series :: Series a

instance Serial () where
    series = pure ()

instance Serial Bool where
    series = [True,False]

instance Serial Int where
    -- No `Monad` for `ZipList`
    series = (0:) . concat $ zipWith
             (\x y -> [x,y]) [1 .. maxBound] [-1, -2 .. minBound]

instance Serial Integer where
    -- No `Monad` for `ZipList`
    series = (0:) . concat $ zipWith
             (\x y -> [x,y]) [1 .. ] [-1, -2 .. ]

instance Serial Float where
    series = zipWith encodeFloat series series

newtype Positive = Positive { unPositive :: Int }

instance Serial Positive where
    series = Positive <$> [1..maxBound]

newtype Negative = Negative { unNegative :: Int }

instance Serial Negative where
    series = Negative <$> [-1,-2 .. minBound]

instance Serial a => Serial (Sum a) where
    series = Sum <$> series

instance Serial a => Serial (Product a) where
    series = Product <$> series

instance Serial Char where
    series = ['\NUL'..]

data AlphaNum = AlphaNum { unAlphaNum :: Char }
                deriving (Eq,Show)

instance Serial AlphaNum where
    series = AlphaNum <$> filter isAlphaNum ['\0'..'\128']

instance Serial a => Serial (Maybe a) where
    series = Nothing : (Just <$> series)

instance Serial a => Serial [a] where
    series = concatMap (\n -> replicateM n $ take n series) [0..]

instance (Serial a, Serial b) => Serial (a,b) where
    series = (,) <$> series <*> series

instance (Serial a, Serial b, Serial c) => Serial (a,b,c) where
    series = (,,) <$> series <*> series <*> series

instance (Serial a, Serial b, Serial c, Serial d) => Serial (a,b,c,d) where
    series = (,,,) <$> series <*> series <*> series <*> series

instance Serial b => Serial (a -> b) where
    series = const <$> series

-- * Raw testing

-- TODO: return number of tests taken
checkBools :: Series Bool -> Int -> Maybe Int
checkBools ss n = (elemIndex False . take n) ss

-- TODO: return number of tests taken
checkSeries :: Property a -> Series a -> Int -> Either a Int
checkSeries p ss n = maybe (Right n) Left $ find (not . p) (take n ss)

-- * Utils

uncurry3 :: (a -> b -> c -> d) -> (a, b, c) -> d
uncurry3 f (x,y,z) = f x y z

zipA2 :: Applicative f => f a -> f b -> f (a,b)
zipA2 = liftA2 (,)

zipA3 :: Applicative f => f a -> f b -> f c -> f (a,b,c)
zipA3 = liftA3 (,,)
