{-# OPTIONS --without-K #-}

open import lib.Base
open import lib.NType
open import lib.Relation
open import lib.types.Bool
open import lib.types.Int

module lib.types.List where

infixr 80 _::_

data List {i} (A : Type i) : Type i where
  nil : List A
  _::_ : A → List A → List A

data HList {i} : List (Type i) → Type (lsucc i) where
  nil : HList nil
  _::_ : {A : Type i} {L : List (Type i)} → A → HList L → HList (A :: L)

hlist-curry-type : ∀ {i j} (L : List (Type i))
  (B : HList L → Type (lmax i j)) → Type (lmax i j)
hlist-curry-type nil B = B nil
hlist-curry-type {j = j} (A :: L) B =
  (x : A) → hlist-curry-type {j = j} L (λ xs → B (x :: xs))

hlist-curry : ∀ {i j} {L : List (Type i)} {B : HList L → Type (lmax i j)}
  (f : Π (HList L) B) → hlist-curry-type {j = j} L B
hlist-curry {L = nil} f = f nil
hlist-curry {L = A :: _} f = λ x → hlist-curry (λ xs → f (x :: xs))

infixr 80 _++_
_++_ : ∀ {i} {A : Type i} → List A → List A → List A
nil ++ l = l
(x :: l₁) ++ l₂ = x :: (l₁ ++ l₂)

++-nil-r : ∀ {i} {A : Type i} (l : List A) → l ++ nil == l
++-nil-r nil      = idp
++-nil-r (a :: l) = ap (a ::_) $ ++-nil-r l

-- [any] in Haskell
data Any {i j} {A : Type i} (P : A → Type j) : List A → Type (lmax i j) where
  here : ∀ {a} {l} → P a → Any P (a :: l)
  there : ∀ {a} {l} → Any P l → Any P (a :: l)

infix 80 _∈_
_∈_ : ∀ {i} {A : Type i} → A → List A → Type i
a ∈ l = Any (_== a) l

Any-dec : ∀ {i j} {A : Type i} (P : A → Type j) → (∀ a → Dec (P a)) → (∀ l → Dec (Any P l))
Any-dec P _   nil       = inr λ{()}
Any-dec P dec (a :: l) with dec a
... | inl p = inl $ here p
... | inr p⊥ with Any-dec P dec l
...   | inl ∃p = inl $ there ∃p
...   | inr ∃p⊥ = inr λ{(here p) → p⊥ p; (there ∃p) → ∃p⊥ ∃p}

∈-dec : ∀ {i} {A : Type i} → has-dec-eq A → ∀ a l → Dec (a ∈ l)
∈-dec dec a l = Any-dec (_== a) (λ a' → dec a' a) l

Any-++-l : ∀ {i j} {A : Type i} (P : A → Type j)
  → ∀ l₁ l₂ → Any P l₁ → Any P (l₁ ++ l₂)
Any-++-l P _ _ (here p)   = here p
Any-++-l P _ _ (there ∃p) = there (Any-++-l P _ _ ∃p)

∈-++-l : ∀ {i} {A : Type i} (a : A) → ∀ l₁ l₂ → a ∈ l₁ → a ∈ (l₁ ++ l₂)
∈-++-l a = Any-++-l (_== a)

Any-++-r : ∀ {i j} {A : Type i} (P : A → Type j)
  → ∀ l₁ l₂ → Any P l₂ → Any P (l₁ ++ l₂)
Any-++-r P nil      _ ∃p = ∃p
Any-++-r P (a :: l) _ ∃p = there (Any-++-r P l _ ∃p)

∈-++-r : ∀ {i} {A : Type i} (a : A) → ∀ l₁ l₂ → a ∈ l₂ → a ∈ (l₁ ++ l₂)
∈-++-r a = Any-++-r (_== a)

Any-++ : ∀ {i j} {A : Type i} (P : A → Type j)
  → ∀ l₁ l₂ → Any P (l₁ ++ l₂) → (Any P l₁) ⊔ (Any P l₂)
Any-++ P nil       l₂ ∃p         = inr ∃p
Any-++ P (a :: l₁) l₂ (here p)   = inl (here p)
Any-++ P (a :: l₁) l₂ (there ∃p) with Any-++ P l₁ l₂ ∃p
... | inl ∃p₁ = inl (there ∃p₁)
... | inr ∃p₂ = inr ∃p₂

∈-++ : ∀ {i} {A : Type i} (a : A) → ∀ l₁ l₂ → a ∈ (l₁ ++ l₂) → (a ∈ l₁) ⊔ (a ∈ l₂)
∈-++ a = Any-++ (_== a)

-- [map] in Haskell
map : ∀ {i j} {A : Type i} {B : Type j} → (A → B) → (List A → List B)
map f nil = nil
map f (a :: l) = f a :: map f l

-- [foldr] in Haskell
foldr : ∀ {i j} {A : Type i} {B : Type j} → (A → B → B) → B → List A → B
foldr f b nil = b
foldr f b (a :: l) = f a (foldr f b l)

-- [concat] in Haskell
concat : ∀ {i} {A : Type i} → List (List A) → List A
concat l = foldr _++_ nil l

ℤsum = foldr _ℤ+_ 0

-- [filter] in Haskell
-- Note that [Bool] is currently defined as a coproduct.
filter : ∀ {i j k} {A : Type i} {Keep : A → Type j} {Drop : A → Type k}
  → ((a : A) → Keep a ⊔ Drop a) → List A → List A
filter p nil = nil
filter p (a :: l) with p a
... | inl _ = a :: filter p l
... | inr _ = filter p l
