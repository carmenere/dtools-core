SELECT
    $$ ALTER ROLE "M4_USER" WITH PASSWORD '' $$
WHERE
    EXISTS (SELECT true FROM pg_roles WHERE rolname = 'M4_USER')
\gexec