
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



## Method
1. Implement a skew sequential heap in Haskell
2. Implement a parallel skew heap in Haskell, either by Strategies
or par/pseq
3. Use Threadscope to benchmark the two data structures when they both do a
heap sort with a large amount of random numbers.
4. Measure the speedup and reflect on it.
