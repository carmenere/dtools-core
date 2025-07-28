divert(-1)dnl
# Parameters for *.sql templates
divert(0)dnl
define(`M4_HBA_POLICY', ifelse(esyscmd(`printf %s $M4_HBA_POLICY'), `', `host all all 0.0.0.0/0 md5', esyscmd(`printf %s $M4_HBA_POLICY')))dnl
