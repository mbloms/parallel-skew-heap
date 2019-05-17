import Control.Parallel

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

peak :: Ord a => SkewHeap a -> a
peak (Node x _ _) = x

pop :: Ord a => SkewHeap a -> SkewHeap a
pop Empty = Empty
pop (Node _ l r) = merge l r
