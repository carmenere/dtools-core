divert(-1)dnl
# Parameters for *.sql templates
divert(0)dnl
define(`M4_USER', ifelse(esyscmd(`printf %s $M4_USER'), `', `postgres', esyscmd(`printf %s $M4_USER')))dnl
define(`M4_PASSWORD', ifelse(esyscmd(`printf %s $M4_PASSWORD'), `', `postgres', esyscmd(`printf %s $M4_PASSWORD')))dnl
