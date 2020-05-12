# System F in Redex

This is an implementation of a Church-style (explicitly typed-annotated) System F (polymorphic) lambda calculus with definitions (let-expressions) in Redex. Included are:

### System F
* Type synthesis, CBV small-step semantics
* Church encodings of numerals and arithmetic (in progress)

### ANF-Restricted System F
* Type synthesis, CBV small-step semantics (does NOT preserve ANF!)
* Uses Redex's `in-hole` contexts for continuations used during compilation
* Compiler from System F to ANF-restricted System F (defined with an ambient continuation)

### (ANF-Restricted) System F with Closures
* Type synthesis, CBV small-step semantics that evaluate closures during application
* Compiler from ANF-restricted System F to closure-converted System F (defined over System F-ANF's typing rules)

### (ANF-Restricted) Hoisted System F (with Closures)
* Type synthesis, CBV big-step semantics (implemented as a judgement rather than a reduction-relation)
* Compiler from closure-converted System F to hoisted System F (not yet)

### System Fω (extends System F)
* Why? I don't know.
* Higher-kinded polymorphic lambda calculus with NO let-expressions
* Type synthesis, term evaluation, type evaluation

### `redex-chk`, but Better
* Renames `judgment` to `judgement`
* Adds `redex-judgement-equals-chk` to test for equivalence between judgement output term and a provided term

### Reduction Strategies
* This doesn't belong here

## TODOs
* Write tests for hoisting pass
* Add booleans and if statements (this is of interest for ANF)
* Consider adding fixpoints (this might be of interest for ACC... or not)
* Reduction in ANF doesn't preserve ANF: fix that (keyword: hereditary substitution)
* Fix ambiguity of ANF let-evaluation context after compilation
* Finish Church encodings (F)
* Add inventory of metafunctions and how to run things to this README
* Fix `redex-judgement-equals-chk` macro so that when check-true fails, the highlight goes over the failed branch, not over the macro itself (redex-chk)
* Consider a heap allocation pass. This is primarily to concretize what a closure would look like at low level. I'm guessing the free types and terms would each be an array.
* This isn't very relevant to this little project, but I want to see if a single syntactic pass is possible for each compiler.
  * Since ANF requires an ambient continuation, we'll have to switch to continuation-passing style, or monadic normal form.
  * Typed closure conversion requires the types of the free variables. Either annotated terms will be needed, or we compile an untyped calculus instead.
  * Hoisting progressively adds code definitions to the global let. I'm not sure if this affects things.
