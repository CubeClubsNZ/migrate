#!/usr/bin/env bash

psql nzclubs -c "\copy (SELECT 
    accounts_cuberprofile.id,
    accounts_cuberprofile.email,
    password AS \"passHash\",
    full_name AS name,
    region
FROM accounts_cuberprofile 
INNER JOIN accounts_account 
    ON accounts_cuberprofile.id=accounts_account.id
) TO 'User.csv' DELIMITER ',' CSV HEADER;"


psql nzclubs -c "\copy (SELECT 
    id,
    name,
    venue,
    venue_details,
    address AS location,
    description,
    contact_email AS contact,
    competitor_limit AS \"competitorLimit\",
    \"startTime\" AS date,
    club_id AS \"clubId\",
    registration_link AS \"externalRegistrationLink\"
FROM competitions_competition
) TO 'Meetup.csv' DELIMITER ',' CSV HEADER;"


psql nzclubs -c "\copy (SELECT 
    cco.competition_id AS \"meetupId\", 
    cco.cuberprofile_id AS \"userId\" 
FROM competitions_competition_organizers cco
UNION 
SELECT 
    ccd.competition_id AS \"meetupId\", 
    ccd.cuberprofile_id AS \"userId\"
FROM competitions_competition_delegates as ccd
ORDER BY \"meetupId\"
) TO 'MeetupToUser.csv' DELIMITER ',' CSV HEADER;"



psql nzclubs -c "\copy (SELECT
    cr.cuber_id as \"userId\", 
    cr.comp_id as \"meetupId\", 
    ARRAY_AGG(cee.puzzle) as \"registeredEvents\" 
FROM competitions_registration cr 
INNER JOIN competitions_registration_events ce 
    ON cr.id = ce.registration_id 
INNER JOIN competitions_event cee 
    ON ce.event_id=cee.id 
GROUP BY cr.comp_id, cr.cuber_id 
ORDER BY cr.cuber_id
) TO 'UserInMeetup.csv' DELIMITER ',' CSV HEADER;"



psql nzclubs -c "\copy (SELECT id,name FROM organizers_club ORDER BY id) TO 'Club.csv' DELIMITER ',' CSV HEADER;"



psql nzclubs -c "\copy (SELECT 
    id,
    \"startTime\" AS \"startDate\",
    \"endTime\" AS \"endDate\",
    puzzle,
    format,
    proceed AS \"proceedNumber\",
    comp_id AS \"meetupId\"
FROM competitions_event
ORDER BY id
) TO 'Round.csv' DELIMITER ',' CSV HEADER;"




psql nzclubs -c "\copy (SELECT 
    id,
    event_id AS \"roundId\", 
    cuber_id AS \"userId\", 
    result 
FROM competitions_submission
) TO 'Result.csv' DELIMITER ',' CSV HEADER;"



psql nzclubs -c "\copy (SELECT 
    id, 
    time, 
    penalty, 
    submission_id AS \"resultId\" 
FROM competitions_solve 
ORDER BY submission_id, id
) TO 'Solve.csv' DELIMITER ',' CSV HEADER;"


tar cvf exports.tar *.csv
rm *.csv
