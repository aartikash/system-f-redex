# System F in Redex

This is an implementation of a Church-style (explicitly typed-annotated) System F (polymorphic) lambda calculus with definitions (let-expression) in Redex. Included are:

### System F

* Type synthesis
* Head normal form reduction and normal form reduction (both call-by-value)
* Church encodings of numerals and arithmetic (in progress)

### ANF-Restricted System F
* Type synthesis
* Head normal form and normal form reduction
* Continuation-plugging
* Compiler from System F to ANF-restricted System F

## TODOs
* Add tests for ANF translation (type-preservation and correctness)
* "Uncurry" functions and definitions into multi-parameter/multi-binding syntactic forms
* Implement System F with closures and abstract closure conversion from F-ANF to F-ACC
* Fix ambiguity of ANF evaluation context
* Add evaluation context for call-by-name evaluation
* Finish Church encodings
* Add inventory of metafunctions to this README
