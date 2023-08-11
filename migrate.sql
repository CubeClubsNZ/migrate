SELECT setval(pg_get_serial_sequence('"User"', 'id'), coalesce(max(id)+1, 1), false) FROM "User";
SELECT setval(pg_get_serial_sequence('"Meetup"', 'id'), coalesce(max(id)+1, 1), false) FROM "Meetup";
SELECT setval(pg_get_serial_sequence('"Club"', 'id'), coalesce(max(id)+1, 1), false) FROM "Club";
SELECT setval(pg_get_serial_sequence('"Result"', 'id'), coalesce(max(id)+1, 1), false) FROM "Result";
SELECT setval(pg_get_serial_sequence('"Round"', 'id'), coalesce(max(id)+1, 1), false) FROM "Round";

UPDATE "User" SET "isClubOrganiser"=true WHERE id IN (1,27,5,34,55,50,92,147,268,287,591);
