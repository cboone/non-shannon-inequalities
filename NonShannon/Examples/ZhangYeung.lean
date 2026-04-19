import NonShannon.Catalog

namespace NonShannon

private def x : VariableSubset := { vars := [0] }
private def y : VariableSubset := { vars := [1] }
private def z : VariableSubset := { vars := [2] }
private def u : VariableSubset := { vars := [3] }
private def xy : VariableSubset := { vars := [0, 1] }
private def xz : VariableSubset := { vars := [0, 2] }
private def xu : VariableSubset := { vars := [0, 3] }
private def yz : VariableSubset := { vars := [1, 2] }
private def yu : VariableSubset := { vars := [1, 3] }
private def zu : VariableSubset := { vars := [2, 3] }
private def xzu : VariableSubset := { vars := [0, 2, 3] }
private def yzu : VariableSubset := { vars := [1, 2, 3] }

/-- The averaged Zhang-Yeung inequality in the joint-entropy basis, scaled by 4 to keep integer coefficients. -/
def zhangYeungAveragedScaled : CandidateInequality :=
  { id := "zhang-yeung-averaged-scaled"
    label := "Zhang-Yeung averaged inequality (scaled by 4)"
    vector :=
      { variableCount := 4
        basis := .jointEntropy
        terms :=
          [ { subset := x, coefficient := (-1 : Rat) }
          , { subset := y, coefficient := (-1 : Rat) }
          , { subset := z, coefficient := (-4 : Rat) }
          , { subset := u, coefficient := (-4 : Rat) }
          , { subset := xy, coefficient := (-2 : Rat) }
          , { subset := xz, coefficient := (4 : Rat) }
          , { subset := xu, coefficient := (4 : Rat) }
          , { subset := yz, coefficient := (4 : Rat) }
          , { subset := yu, coefficient := (4 : Rat) }
          , { subset := zu, coefficient := (6 : Rat) }
          , { subset := xzu, coefficient := (-5 : Rat) }
          , { subset := yzu, coefficient := (-5 : Rat) } ] }
    provenance :=
      { source := "Zhang and Yeung (1998), eq. 23"
        note := "Reference fixture imported during bootstrap from the sibling formalization project." }
    status := .reference }

/-- Catalog entry for the bootstrap Zhang-Yeung reference fixture. -/
def zhangYeungCatalogEntry : CatalogEntry :=
  { candidate := zhangYeungAveragedScaled
    notes := ["Bootstrap reference fixture for schema, API, and canonicalization smoke tests."] }

end NonShannon
