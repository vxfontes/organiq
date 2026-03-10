-- ajustes de timezone
update inbota.users set timezone = 'America/Sao_Paulo' where timezone in ('-03', '-3', 'UTC-3', 'GMT-3');