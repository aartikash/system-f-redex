#lang racket

(require (rename-in (prefix-in F. "./system-f.rkt")
                    [F.λF λF])
         (rename-in redex/reduction-semantics
                    [define-judgment-form          define-judgement-form]
                    [define-extended-judgment-form define-extended-judgement-form]
                    [judgment-holds                judgement-holds]))

(module+ test
  (require (rename-in redex-chk
                      [redex-judgment-holds-chk redex-judgement-holds-chk])))

(provide (all-defined-out))

;; SYSTEM Fω ;;

;; Syntax

(define-extended-language λFω λF
  (κ ι ::= * (⇒ κ κ)) ;; Kinds
  (τ σ ::= .... (∀ (α : κ) τ) (Λ (α : κ) τ) (τ τ)) ;; Types
  (e   ::= .... (Λ (α : κ) e)) ;; Terms
  (Δ   ::= · (Δ (α : κ))) ;; Type contexts

  (v   ::= .... (Λ (α : κ) e)) ;; Term values
  (F   ::= .... (Λ (α : κ) F)) ;; Evaluation contexts (normal form)

  (w   ::= α (→ w w) (∀ (α : κ) w) (Λ (α : κ) τ)) ;; Type values
  (G   ::= hole (→ G τ) (→ w G) (∀ (α : κ) G) (G τ) (w G)) ;; Evaluation contexts (types)

  #:binding-forms
  (∀ (α : κ) τ #:refers-to α)
  (Λ (α : κ) e #:refers-to α))

(default-language λFω)

;; Unroll (λ* ([a_1 : b_1] ... [a_n : b_n]) e) into (L [a_1 : b_1] ... (L [a_n : b_n] e))
;; where (L ::= λ Λ) (a ::= [x : τ] [α : κ])
(define-metafunction λFω
  λ* : ([any : any] ...) e -> e
  [(λ* () e) e]
  [(λ* ([x : τ] any ...) e)
   (λ (x : τ) (λ* (any ...) e))]
  [(λ* ([α : κ] any ...) e)
   (Λ (α : κ) (λ* (any ...) e))])

;; Unroll (@ e a_1 ... a_n) into ((e a_1) ... a_n)
;; where (a ::= e [τ])
(define-metafunction/extension F.@ λFω
  @ : any ... -> e)

;; Unroll (τ_1 → ... → τ_n) into (τ_1 → (... → τ_n))
(define-metafunction/extension F.→* λFω
  →* : τ ... τ -> τ)

;; Unroll (let* ([x_1 e_1] ... [x_n e_n]) e) into (let [x_1 e_1] ... (let [x_n e_n] e))
(define-metafunction/extension F.let* λFω
  let* : ([x e] ...) e -> e)

;; Unroll (Λ* ([α_1 : κ_1] ... [α_n : κ_n]) τ) into (Λ (α_1 : κ_1) ... (Λ (α_n : κ_n) τ))
(define-metafunction λFω
  Λ* : ([α : κ] ...) τ -> τ
  [(Λ* () τ) τ]
  [(Λ* ([α : κ] [α_r : κ_r] ...) τ)
   (Λ (α : κ) (Λ* ([α_r : κ_r] ...) τ))])

;; Unroll (@* τ τ_1 ... τ_n) into ((τ τ_1) ... τ_n)
(define-metafunction λFω
  @* : τ ... -> e
  [(@* τ) τ]
  [(@* τ_1 τ_2 any ...)
   (@* (τ_1 τ_2) any ...)])

;; Unroll (κ_1 ⇒ ... ⇒ κ_n) into (κ_1 ⇒ (... ⇒ κ_n))
(define-metafunction λFω
  ⇒* : κ ... κ -> κ
  [(⇒* κ) κ]
  [(⇒* κ κ_r ...)
   (⇒ κ (⇒* κ_r ...))])

;; Unroll (∀* ([α_1 : κ] ... [α_n : κ]) τ) as (∀ (α_1 : κ_1) ... (∀ (α_n : κ_n) τ))
(define-metafunction λFω
  ∀* : ([α : κ] ...) τ -> τ
  [(∀* () τ) τ]
  [(∀* ([α : κ] [α_r : κ_r] ...) τ)
   (∀ (α : κ) (∀* ([α_r : κ_r] ...) τ))])

;; Unroll ((x_1 : τ_1) ... (x_n : τ_n)) into ((· (x_1 : τ_1)) ... (x_n : τ_n))
(define-metafunction/extension F.Γ* λFω
  Γ* : (x : τ) ... -> Γ)

;; Unroll ([α_1 : κ] ... [α_n : κ]) into ((· (α_1 : κ_1)) ... (α_n : κ_n))
(define-metafunction λFω
  Δ* : (α : κ) ... -> Δ
  [(Δ*) ·]
  [(Δ* (α_r : κ_r) ... (α : κ))
   ((Δ* (α_r : κ_r) ...) (α : κ))])

(module+ test
  (redex-chk
   (λ* ([x : a] [b : *] [z : c] [d : (⇒ * *)]) x) (λ (x : a) (Λ (b : *) (λ (z : c) (Λ (d : (⇒ * *)) x))))
   (Λ* ([a : *] [b : (⇒ * *)]) (b a)) (Λ (a : *) (Λ (b : (⇒ * *)) (b a)))
   (@* a b c d) (((a b) c) d)
   (⇒* (⇒ * *) (⇒* * * *) *) (⇒ (⇒ * *) (⇒ (⇒ * (⇒ * *)) *))
   (∀* ([a : *] [b : (⇒ * *)]) (b a)) (∀ (a : *) (∀ (b : (⇒ * *)) (b a)))
   (Δ* [a : *] [b : (⇒ * *)]) ((· (a : *)) (b : (⇒ * *)))))


;; Static Semantics

;; (x : τ) ∈ Γ
(define-extended-judgement-form λFω F.∈Γ
  #:contract (∈Γ x τ Γ)
  #:mode (∈Γ I O I))

;; (α : κ) ∈ Δ
(define-judgement-form λFω
  #:contract (∈Δ α κ Δ)
  #:mode (∈Δ I O I)

  [--------------------- "Δ-car"
   (∈Δ α κ (Δ (α : κ)))]

  [(∈Δ α κ Δ)
   ------------------------- "Δ-cdr"
   (∈Δ α κ (Δ (α_0 : κ_0)))])

(module+ test
  (redex-judgement-holds-chk
   ∈Δ
   [#:f a * ·]
   [#:f a * (· (b : *))]
   [#:f a (⇒ * *) (· (a : *))]
   [a * (· (a : *))]
   [a (⇒ * *) (· (a : (⇒ * *)))]
   [a * (Δ* (a : *) (b : (⇒ * *)))]
   [b (⇒ * *) (Δ* (a : *) (b : (⇒ * *)))]
   [a * (Δ* (a : (⇒ * *)) (a : *))]))

;; Δ ⊢ τ : κ
(define-judgement-form λFω
  #:contract (⊢τ Δ τ κ)
  #:mode (⊢τ I I O)

  [(∈Δ α κ Δ)
   ----------- "τ-var"
   (⊢τ Δ α κ)]

  [(⊢τ (Δ (α : ι)) τ κ)
   ------------------------------ "τ-fun"
   (⊢τ Δ (Λ (α : ι) τ) (⇒ ι κ))]

  [(⊢τ Δ σ ι)
   (⊢τ Δ τ (⇒ ι κ))
   --------------- "τ-app"
   (⊢τ Δ (τ σ) κ)]

  [(⊢τ Δ σ *)
   (⊢τ Δ τ *)
   ----------------- "τ-arr"
   (⊢τ Δ (→ σ τ) *)]

  [(⊢τ (Δ (α : κ)) τ *)
   ------------------------ "τ-forall"
   (⊢τ Δ (∀ (α : κ) τ) *)])

(module+ test
  (redex-judgement-holds-chk
   (⊢τ (Δ* (a : *) (b : (⇒ * *))))
   [b (⇒ * *)]
   [(Λ (a : *) a) (⇒ * *)]
   [(Λ (a : (⇒ * *)) a) (⇒ (⇒ * *) (⇒ * *))]
   [(Λ (a : *) b) (⇒ * (⇒ * *))]
   [(b a) *]
   [((Λ (a : *) a) a) *]))

;; Δ Γ ⊢ e : τ
(define-judgement-form λFω
  #:contract (⊢ Δ Γ e τ)
  #:mode (⊢ I I I O)

  [(∈Γ x τ Γ)
   ------------ "var"
   (⊢ Δ Γ x τ)]
  
  [(⊢τ Δ σ *)
   (⊢ Δ (Γ (x : σ)) e τ)
   ------------------------------ "fun"
   (⊢ Δ Γ (λ (x : σ) e) (→ σ τ))]

  [(⊢ Δ Γ e_2 σ_2)
   (⊢ Δ Γ e_1 σ_1)
   (where (σ (→ σ τ)) ((reduce-type σ_2) (reduce-type σ_1)))
   -------------------- "app"
   (⊢ Δ Γ (e_1 e_2) τ)]

  [(⊢ (Δ (α : κ)) Γ e τ)
   ------------------------------------- "polyfun"
   (⊢ Δ Γ (Λ (α : κ) e) (∀ (α : κ) τ))]

  [(⊢τ Δ σ κ)
   (⊢ Δ Γ e τ_0)
   (where (∀ (α : κ) τ) (reduce-type τ_0))
   ----------------------------------- "polyapp"
   (⊢ Δ Γ (e [σ]) (substitute τ α σ))]

  [(⊢ Δ Γ e_x σ)
   (⊢ Δ (Γ (x : σ)) e τ)
   -------------------------- "let"
   (⊢ Δ Γ (let [x e_x] e) τ)])


;; Dynamic Semantics

;; Term reduction
(define ⟶
  (extend-reduction-relation
   F.⟶ λFω
   (--> ((Λ (α : κ) e) [τ])
        (substitute e α τ)
        "τ")))

;; Compatible closure of ⟶
(define ⟶*
  (context-closure ⟶ λFω E))

;; Reflexive, transitive closure of ⟶*
(define-metafunction λFω
  reduce : e -> v
  [(reduce e)
   ,(first (apply-reduction-relation* ⟶* (term e) #:cache-all? #t))])

;; Compatible closure of ⟶*
;; including under lambdas
(define ⇓
  (context-closure ⟶ λFω F))

;; Reflexive, transitive closure of ⇓
(define-metafunction λFω
  normalize : e -> v
  [(normalize e)
   ,(first (apply-reduction-relation* ⇓ (term e) #:cache-all? #t))])

;; Type reduction
(define ⟹
  (reduction-relation
   λFω
   (--> ((Λ (α : κ) τ) w)
        (substitute τ α w)
        "β")))

;; Compatible closure of ⟹
;; NOT under any lambdas
(define ⟹*
  (context-closure ⟹ λFω G))

;; Reflexive, transitive closure of ⟹
;; producing only types (no type operators)
(define-metafunction λFω
  reduce-type : τ -> w
  [(reduce-type τ)
   ,(first (apply-reduction-relation* ⟹* (term τ) #:cache-all? #t))])