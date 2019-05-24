import Control.Parallel
import Data.List (foldl', unfoldr)

data SkewHeap a = Empty
                | Node a (SkewHeap a) (SkewHeap a)
                deriving Show

singleton :: Ord a => a -> SkewHeap a
singleton x = Node x Empty Empty

merge :: Ord a => SkewHeap a -> SkewHeap a -> SkewHeap a
merge Empty t2 = t2
merge t1 Empty = t1
merge t1@(Node x1 l1 r1) t2@(Node x2 l2 r2)
    | x1 <= x2  = Node x1 (t2 `merge` r1) l1
    | otherwise = Node x2 (t1 `merge` r2) l2

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

