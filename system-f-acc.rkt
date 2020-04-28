#lang racket

(require (rename-in (prefix-in F. "./system-f-anf.rkt")
                    [F.λF-ANF λF-ANF])
         (rename-in redex/reduction-semantics
                    [define-judgment-form          define-judgement-form]
                    [define-extended-judgment-form define-extended-judgement-form]
                    [judgment-holds                judgement-holds]))

(module+ test
  (require "./redex-chk.rkt"))

(provide (all-defined-out))

;; CLOSURE-CONVERTED SYSTEM F ;;

;; Syntax

(define-extended-language λF-ACC λF-ANF
  (y β ::= variable-not-otherwise-mentioned) ;; More variable nonterminals

  (τ σ ::= .... ;; Types
     (vcode (α ...) (τ ...) β σ)  ;; ∀ (α ...). τ → ... → ∀ α. τ
     (tcode (α ...) (τ ...) σ σ)) ;; ∀ (α ...). τ → ... → τ → τ

  (k ::= ;; Code
     (Λ (α ...) ([x : τ] ...) β e)        ;; Λ (α ...). λ (x:τ ...). Λ α.   e
     (λ (α ...) ([x : τ] ...) (y : σ) e)) ;; Λ (α ...). λ (x:τ ...). λ x:τ. e

  (v ::= x (⟨ k [σ ...] (v ...) ⟩)) ;; Values (incl. closures)

  (F ::= E ;; Evaluation contexts (under closures)
       (⟨ F [σ ...] (v ...) ⟩)
       (Λ (α ...) ([x : τ] ...) β F)
       (λ (α ...) ([x : τ] ...) (y : σ) F))

  ;; Redex complains about the colon being used at different depths in the following
  #;(λ (α ...)
    ([x : τ] ...) #:refers-to (shadow α ...)
    (y : σ) #:refers-to (shadow α ...)
    e #:refers-to (shadow α ... x ... y))
  ;; so instead we treat the bindings separately and export the variables

  (b ::= ([x : τ] ...)) ;; Bindings
  #:binding-forms
  ([x : τ] ...) #:exports (shadow x ...)
  (Λ (α ...)
     b #:refers-to (shadow α ...)
     β e #:refers-to (shadow α ... b β))
  (λ (α ...)
    b #:refers-to (shadow α ...)
    (y : σ) #:refers-to (shadow α ...)
    e #:refers-to (shadow α ... b y))
  (vcode
   (α ...) (τ ...) #:refers-to (shadow α ...)
   β σ #:refers-to (shadow α ... β))
  (tcode
   (α ...) (τ ...) #:refers-to (shadow α ...)
   σ_1 #:refers-to (shadow α ...)
   σ_2 #:refers-to (shadow α ...)))

(default-language λF-ACC)

;; Check that the bindings are working correctly
;; The following should therefore be alpha-equivalent
(module+ test
  (redex-chk
   #:eq (Λ (a b) ([x : a] [y : b]) c (y [c]))     (Λ (i j) ([u : i] [w : j]) k (w [k]))
   #:eq (λ (a b) ([x : a] [y : b]) (z : a) (y z)) (λ (i j) ([u : i] [v : j]) (w : i) (v w))
   #:eq (vcode (a b) (b a) c (→ a c))             (vcode (i j) (j i) k (→ i k))
   #:eq (tcode (a b) (b a) (→ a b) (→ b a))       (tcode (i j) (j i) (→ i j) (→ j i))
   #:f #:eq (Λ (a) ([x : a]) b (x [b]))           (Λ (b) ([x : b]) a (x [b]))))

;; Unroll (λ* (a_1 ... a_n) e) into (L a_1 ... (L a_n e))
;; where (L ::= λ Λ) (a ::= [x : τ] α)
(define-metafunction/extension F.λ* λF-ACC
  λ* : (any ...) e -> e)

;; Unroll (let* ([x_1 e_1] ... [x_n e_n]) e) into (let [x_1 e_1] ... (let [x_n e_n] e))
(define-metafunction/extension F.let* λF-ACC
  let* : ([x e] ...) e -> e)

;; Unroll (τ_1 → ... → τ_n) into (τ_1 → (... → τ_n))
(define-metafunction/extension F.→* λF-ACC
  →* : τ ... τ -> τ)

;; Unroll (∀* (α_1 ... a_n) τ) as (∀ α_1 ... (∀ α_n τ))
(define-metafunction/extension F.∀* λF-ACC
  ∀* : (α ...) τ -> τ)

;; Unroll ((x_1 : τ_1) ... (x_n : τ_n)) into ((· (x_1 : τ_1)) ... (x_n : τ_n))
(define-metafunction/extension F.Γ* λF-ACC
  Γ* : (x : τ) ... -> Γ)

;; Unroll (α_1 ... α_n) into ((· α_1) ... α_n)
(define-metafunction/extension F.Δ* λF-ACC
  Δ* : α ... -> Δ)

;; Unroll (Γ (x_1 : τ_1) ... (x_n : τ_n)) into ((Γ (x_1 : τ_1)) ... (x_n : τ_n))
(define-metafunction λF-ACC
  Γ+ : Γ (x : τ) ... -> Γ
  [(Γ+ Γ) Γ]
  [(Γ+ Γ (x_r : τ_r) ... (x : τ))
   ((Γ+ Γ (x_r : τ_r) ...) (x : τ))])

;; Unroll (Δ α_1 ... α_n) into ((Δ α_1) ... α_n)
(define-metafunction λF-ACC
  Δ+ : Δ α ... -> Δ
  [(Δ+ Δ) Δ]
  [(Δ+ Δ α_r ... α)
   ((Δ+ Δ α_r ...) α)])


;; Static Semantics

;; (x : τ) ∈ Γ
(define-extended-judgement-form λF-ACC F.∈Γ
  #:contract (∈Γ x τ Γ)
  #:mode (∈Γ I O I))

;; α ∈ Δ
(define-extended-judgement-form λF-ACC F.∈Δ
  #:contract (∈Δ α Δ)
  #:mode (∈Δ I I))

;; Δ ⊢ τ
(define-extended-judgement-form λF-ACC F.⊢τ
  #:contract (⊢τ Δ τ)
  #:mode (⊢τ I I)

  [(where Δ_0 (Δ+ Δ α ...))
   (⊢τ Δ_0 τ) ...
   (⊢τ (Δ_0 β) σ)
   ----------------------------------- "τ-vcode"
   (⊢τ Δ (vcode (α ...) (τ ...) β σ))]

  [(where Δ_0 (Δ+ Δ α ...))
   (⊢τ Δ_0 τ) ...
   (⊢τ Δ_0 σ_1)
   (⊢τ Δ_0 σ_2)
   --------------------------------------- "τ-tcode"
   (⊢τ Δ (tcode (α ...) (τ ...) σ_1 σ_2))])

(module+ test
  (redex-judgement-holds-chk
   (⊢τ ·)
   [(vcode (a b) (b a) c (→* a b c))]
   [(tcode (a b) (b a) (→ a b) (→ b a))]))

;; Δ Γ ⊢ k : τ
(define-judgement-form λF-ACC
  #:contract (⊢k Δ Γ k τ)
  #:mode (⊢k I I I O)

  [(where Δ_0 (Δ+ Δ α ...))
   (⊢τ Δ_0 τ) ...
   (⊢e (Δ_0 β) (Γ+ Γ (x : τ) ...) e σ)
   ------------------------------------------------------------------- "vcode"
   (⊢k Δ Γ (Λ (α ...) ([x : τ] ...) β e) (vcode (α ...) (τ ...) β σ))]

  [(where Δ_0 (Δ+ Δ α ...))
   (⊢τ Δ_0 τ) ...
   (⊢e Δ_0 (Γ+ Γ (x : τ) ... (y : σ_1)) e σ_2)
   ------------------------------------------------------------------------------- "tcode"
   (⊢k Δ Γ (λ (α ...) ([x : τ] ...) (y : σ_1) e) (tcode (α ...) (τ ...) σ_1 σ_2))])

(module+ test
  (redex-judgement-holds-chk
   (⊢k · ·)
   [(Λ (a b) ([x : a] [y : (∀ b b)]) c (y [c])) (vcode (α_1 β_1) (α_1 (∀ β_2 β_2)) α_2 α_2)]
   [(λ (a b) ([x : a] [y : (→ a b)]) (z : a) (y z)) (tcode (α β) (α (→ α β)) α β)]))

;; Δ Γ ⊢ v : τ
(define-extended-judgement-form λF-ACC F.⊢v
  #:contract (⊢v Δ Γ v τ)
  #:mode (⊢v I I I O)

  [(⊢k Δ Γ k (vcode (α ..._1) (τ ..._2) β σ_1))
   (⊢τ Δ σ) ...
   (where Δ_0 (Δ+ Δ α ...))
   (where (τ_0 ..._2) (substitute** (τ ...) (α ...) (σ ...)))
   (where σ_2 (substitute* σ_1 (α ...) (σ ...)))
   (⊢v Δ_0 Γ v τ_0) ...
   ----------------------------------------------- "fun"
   (⊢v Δ Γ (⟨ k [σ ..._1] (v ..._2) ⟩) (∀ β σ_2))]

  [(⊢k Δ Γ k (tcode (α ..._1) (τ ..._2) σ_1 σ_2))
   (⊢τ Δ σ) ...
   (where Δ_0 (Δ+ Δ α ...))
   (where (τ_0 ..._2) (substitute** (τ ...) (α ...) (σ ...)))
   (where σ_12 (substitute* (→ σ_1 σ_2) (α ...) (σ ...)))
   (⊢v Δ_0 Γ v τ_0) ...
   ----------------------------------------- "polyfun"
   (⊢v Δ Γ (⟨ k [σ ..._1] (v ..._2) ⟩) σ_12)])

(module+ test
  (redex-judgement-holds-chk
   (⊢v (· b) (Γ* (z : b) (y : (∀ b b))))
   [(⟨ (Λ (a) ([x : a]) c x) [(∀ b b)] (y) ⟩) (∀ α (∀ β β))])
  (redex-judgement-equals-chk
   (⊢v (· b) (Γ* (z : b) (y : (∀ b b))))
   [(⟨ (λ (a) ([x : a]) (y : (→ a a)) (y x)) [b] (z) ⟩) τ #:pat τ #:term (→ (→ b b) b)]))

;; Δ Γ ⊢ c : τ
(define-extended-judgement-form λF-ACC F.⊢c
  #:contract (⊢c Δ Γ c τ)
  #:mode (⊢c I I I O))

;; Δ Γ ⊢ e : τ
(define-extended-judgement-form λF-ACC F.⊢e
  #:contract (⊢e Δ Γ e τ)
  #:mode (⊢e I I I O))


;; Dynamic Semantics

(define-metafunction λF-ACC
  substitute** : (any ..._0) (x ..._1) (any ..._1) -> (any ..._0)
  [(substitute** (any ...) any_var any_val)
   ((substitute* any any_var any_val) ...)])

(define-metafunction λF-ACC
  substitute* : any (x ..._1) (any ..._1) -> any
  [(substitute* any () ()) any]
  [(substitute* any (x_0 x_r ...) (any_0 any_r ...))
   (substitute* (substitute any x_0 any_0) (x_r ...) (any_r ...))])

(define ⟶
  (extend-reduction-relation
   F.⟶ λF-ACC
   (--> ((⟨ (Λ (α ...) ([x : _] ...) β e) [σ ...] (v ...) ⟩) σ_1)
        () ;; TODO: e[σ/α]...[v/x]...[σ_1/β]
        "β")
   (--> ((⟨ (λ (α ...) ([x : _] ...) (y : _) e) [σ ...] (v ...) ⟩) v_1)
        () ;; TODO: e[σ/α]...[v/x][v_1/y]
        "τ")))

(define ⟶*
  (context-closure ⟶ λF-ACC E))

(define-metafunction λF-ACC
  reduce : e -> v
  [(reduce e)
   ,(first (apply-reduction-relation* ⟶* (term e) #:cache-all? #t))])

(define ⇓
  (context-closure ⟶ λF-ACC F))

(define-metafunction λF-ACC
  normalize : e -> v
  [(normalize e)
   ,(first (apply-reduction-relation* ⇓ (term e) #:cache-all? #t))])