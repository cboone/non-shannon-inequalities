namespace NonShannon

/-- High-level lifecycle states for candidate inequalities and certificates. -/
inductive CertificateStatus where
  | planned
  | candidate
  | reference
  | redundant
  | validated
  | rejected
  deriving DecidableEq, Inhabited

end NonShannon
