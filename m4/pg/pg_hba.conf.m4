divert(-1)dnl
# Parameters for *.sql templates
divert(0)dnl
define(`M4_HBA_POLICY', ifelse(esyscmd(`printf %s "$M4_HBA_POLICY"'), `', `', esyscmd(`printf %s "$M4_HBA_POLICY"')))dnl
