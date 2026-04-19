import NonShannon

namespace NonShannonTest

open NonShannon

private def params : CopyParameters :=
  { variableCount := 4
    frozen := { vars := [0] }
    copied := { vars := [1] }
    conditioning := { vars := [2, 3] }
    copyCount := 2
    label := "two-copy bootstrap fixture" }

example : params.copyCount = 2 := rfl

example : parameterizedCopyLemma params := by
  simp [parameterizedCopyLemma, parameterizedCopyLemmaSpec, params]

end NonShannonTest
