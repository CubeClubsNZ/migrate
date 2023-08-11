SELECT setval(pg_get_serial_sequence('"User"', 'id'), coalesce(max(id)+1, 1), false) FROM "User";
SELECT setval(pg_get_serial_sequence('"Meetup"', 'id'), coalesce(max(id)+1, 1), false) FROM "Meetup";
SELECT setval(pg_get_serial_sequence('"Club"', 'id'), coalesce(max(id)+1, 1), false) FROM "Club";
SELECT setval(pg_get_serial_sequence('"Result"', 'id'), coalesce(max(id)+1, 1), false) FROM "Result";
SELECT setval(pg_get_serial_sequence('"Round"', 'id'), coalesce(max(id)+1, 1), false) FROM "Round";

UPDATE "User" SET "isClubOrganiser"=true WHERE id IN (1,27,5,34,55,50,92,147,268,287,591);

DELETE FROM "User" WHERE id IN (530, 563, 596, 419, 574);

UPDATE "User" 
    SET name = CASE id
                WHEN 619 THEN 'Raymond Du'
                WHEN 260 THEN 'Rachel Gu'
                WHEN 313 THEN 'Paratene Te Akonga Mohi'
                WHEN 472 THEN 'James Jameson'
                WHEN 546 THEN 'Alika Feaver'
                WHEN 459 THEN 'Bertie'
                WHEN 562 THEN 'Blake Webber'
                WHEN 456 THEN 'Matthew'
                WHEN 455 THEN 'Jim'
                END
    WHERE id IN (619, 260, 313, 472);
