import Control.Parallel
import Data.List (foldl', unfoldr)
import System.Random

data SkewHeap a = Empty
                | Node a (SkewHeap a) (SkewHeap a)
                deriving Show

singleton :: Ord a => a -> SkewHeap a
singleton x = Node x Empty Empty

merge :: Ord a => SkewHeap a -> SkewHeap a -> SkewHeap a
merge Empty t2 = t2
merge t1 Empty = t1
merge t1@(Node x1 l1 r1) t2@(Node x2 l2 r2)
    | x1 <= x2  = (peak l1) `par` Node x1 (t2 `merge` r1) l1
    | otherwise = (peak l2) `par` Node x2 (t1 `merge` r2) l2

insert :: Ord a => a -> SkewHeap a -> SkewHeap a
insert x heap = singleton x `merge` heap

peak :: Ord a => SkewHeap a -> Maybe a
peak (Node x _ _) = Just x
peak Empty = Nothing

delete_min :: Ord a => SkewHeap a -> Maybe (SkewHeap a)
delete_min (Node _ l r) = Just $ merge l r
delete_min Empty = Nothing

pop :: Ord a => SkewHeap a -> Maybe (a, SkewHeap a)
pop heap = do
    min <- peak heap
    rest <- delete_min heap
    return (min, rest)

heapsort :: Ord a => [a] -> [a]
heapsort = unfoldr pop . foldl' (flip insert) Empty

main = do
    rng <- getStdGen
    let list = take 2500000 $ randoms rng :: [Int]
    print $ (!! (2500000 `div` 2)) $ heapsort list
