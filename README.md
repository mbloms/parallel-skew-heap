
# Parallelizing a skew heap using Haskell Sparks

## Background

A skew heap is a simple binary heap which is self balancing
by trying to maintain the invariant that the path following the right
subtrees all the way to the bottom is shorter than the depth of the left
subtree. In other words it tries to be a leftist, but does less checking.

A skew heap is very easy to implement in a language like Haskell and is
easily implemented as a persistent data structure. All operations on a skew
heap operates only on the right subtrees, and because of its implementation,
the next right subtree is the previous left subtree. This means that a new insert
or merge operation could be evaluated in parallel before a previous one
finishes. This gives huge potential for parallelizing.



A Skew Heap manges to be efficient and have a relatively simple
implementation by allowing it's operations (except for find-min)
to have a worst case time complexity of *O(n)*.

The probability that an operation will take that long is however,
quite small, and the real magick is that if a worst case would turn up,
the skew heap compensates by making the next operation blazingly fast.
On average, all operations run in logarithmic time, exept for find-min,
which is always constant.

Our skew heap implementation supports the following operations:

* merge
* insert
* peak (find-min)
* delete_min

and also *Empty* and *singleton* for construction.

Merge is the most important function. It merges two skew heaps into a single one.
All other functions are implemented in terms of merge.
We'll get back to how it's implemented.

```haskell
merge :: Ord a => SkewHeap a -> SkewHeap a -> SkewHeap a
```

Worst case: *O(n)*
Amortized: *O(log n)*

`insert` inserts a single element into a skew heap. It's implementation is simply:

```haskell
insert :: Ord a => a -> SkewHeap a -> SkewHeap a
insert x heap = singleton x `merge` heap
```

Worst case: *O(n)*
Amortized: *O(log n)*

`peak` returns the top (smallest) element in the heap.

```haskell
peak :: Ord a => SkewHeap a -> Maybe a
peak (Node x _ _) = Just x
peak Empty = Nothing
```

Worst case: *O(1)*

`delete_min` removes the top element from the heap and merges
the two subtrees to generate a new heap

```haskell
delete_min :: Ord a => SkewHeap a -> Maybe (SkewHeap a)
delete_min (Node _ l r) = Just $ merge l r
delete_min Empty = Nothing
```

Worst case: *O(n)*
Amortized: *O(log n)*

As seen above, all operations have a simple and straight forward implementation.
Except for `peak`, all operations are implemented in terms of `merge`.
`merge` is a bit harder.

It's implemented by taking the largest of two heaps and merging it recursively
into the smaller heaps right subtree.

The base cases are easiest:

```haskell
merge Empty t2 = t2
merge t1 Empty = t1
```

Merging the larger heap into the smallers right subtree looks like this:

```haskell
merge t1@(Node x1 l1 r1) t2@(Node x2 l2 r2)
    | x1 <= x2  = Node x1 l1 (t2 `merge` r1)
    | otherwise = Node x2 l2 (t1 `merge` r2)
```

Doing this makes the right path at least one element longer.
To mitigate this, the subtrees of the new heap is swapped so that the next time
an operation inserts elements into the heap, it will be into the other subtree,
keeping it balanced.

```haskell
merge t1@(Node x1 l1 r1) t2@(Node x2 l2 r2)
    | x1 <= x2  = Node x1 (t2 `merge` r1) l1
    | otherwise = Node x2 (t1 `merge` r2) l2
```

Putting it all together we get this:

```haskell
merge :: Ord a => SkewHeap a -> SkewHeap a -> SkewHeap a
merge Empty t2 = t2
merge t1 Empty = t1
merge t1@(Node x1 l1 r1) t2@(Node x2 l2 r2)
    | x1 <= x2  = Node x1 (t2 `merge` r1) l1
    | otherwise = Node x2 (t1 `merge` r2) l2
```

### Paralellizing

One intresting observation is that merge never touches the left subtree,
it only promotes it to the new right subtree.

Inserting 8 into the following tree will insert it along the
right path and then shift the elements:

          1
        /   \
      2       3
     / \     / \
    4   5   6   7

After insertion:

          1
        /   \
      2       3
     / \     / \
    4   5   6   7
                 \
                  8

After swapping:

            1
          /   \      
        3       2     
       / \     / \    
      7   6   4   5   
     /              
    8

If we only look at the third "level" of subtrees it's easy to
see that it takes at least 4 merge operations before a
subtree comes back to the right path, where all the action happen.

If we start merging of a subtree at level n in paralell,
it will take at least 2^(n-1) operations before we need the result
of that merge. Making sure that every call to merge is evaluated
in paralell is therefore a quite good optimization.

Using the `par` function from *Control.Parallel*, we can do this quite
simply by writing:

```haskell
merge :: Ord a => SkewHeap a -> SkewHeap a -> SkewHeap a
merge Empty t2 = t2
merge t1 Empty = t1
merge t1@(Node x1 l1 r1) t2@(Node x2 l2 r2)
    | x1 <= x2  =   let r = (t2 `merge` r1) in (peak r) `par` Node x1 r l1
    | otherwise =   let r = (t1 `merge` r2) in (peak r) `par` Node x2 r l2
```

`(peak r)` will force evalutaion of the recursive call to merge.
```(peak r) `par` Node x1 r l1``` will make sure that evaluation of
the recursive call is started in paralell before returning.

### Bench

Running this on three threads on a laptop with the following specs:

* OS: Manjaro 18.0.4 Illyria
* Kernel: x86_64 Linux 5.0.9-2-MANJARO
* Shell: fish 3.0.2
* CPU: Intel Core i5-5200U @ 4x 2.7GHz [68.0°C]
* GPU: Mesa DRI Intel(R) HD Graphics 5500 (Broadwell GT2)
* RAM: 11707MiB

...we can see a speedup from 24.25s for the sequential version
to 13.73s for our new paralell version.

The benchmarking was done by heapsorting 2500000 elements and
evaluating the last one.

eventlogs:
* sequential.eventlog
* par-right.eventlog