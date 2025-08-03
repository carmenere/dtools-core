divert(-1)dnl
# Parameters for *.sql templates
divert(0)dnl
define(`M4_PORT', ifelse(esyscmd(`printf %s $M4_PORT'), `', `5432', esyscmd(`printf %s $M4_PORT')))dnl
