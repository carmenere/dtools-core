divert(-1)dnl
# Parameters for *.sql templates
divert(0)dnl
define(`M4_PORT', ifelse(esyscmd(`printf %s "$M4_PORT"'), `', `5432', esyscmd(`printf %s "$M4_PORT"')))dnl
define(`M4_HBA_CONF', ifelse(esyscmd(`printf %s "$M4_HBA_CONF"'), `', `xxx', esyscmd(`printf %s "$M4_HBA_CONF"')))dnl
define(`M4_PG_DATA_DIRECTORY', ifelse(esyscmd(`printf %s "$M4_PG_DATA_DIRECTORY"'), `', `xxx', esyscmd(`printf %s "$M4_PG_DATA_DIRECTORY"')))dnl
