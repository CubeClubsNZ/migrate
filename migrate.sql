BEGIN TRANSACTION;

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER IF NOT EXISTS cubeclubs_prod
	FOREIGN DATA WRAPPER postgres_fdw
	OPTIONS (host 'cubeclubs.nz', dbname 'nzclubs', port '5432');

CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER SERVER cubeclubs_prod OPTIONS (user 'postgres', password '<password>');

CREATE SCHEMA IF NOT EXISTS old_public;

IMPORT FOREIGN SCHEMA public
	FROM SERVER cubeclubs_prod
	INTO old_public;


INSERT INTO public.user (id, email, pass_hash, name, region, is_club_organiser)
	(SELECT
		ac.id,
		CASE
			-- Clear invalid or duplicate emails
			WHEN ac.id IN (396, 397,
				389, 390,
				371, 373,
				551, 552) OR
				ac.email in ('extra@extra.com', 'help@help.com', 'test@test.com', 'help@help.help', 'hello@hello.com') OR
				ac.email ~ '%@entry.com' THEN NULL
			ELSE ac.email
		END my_email,
		aa.password,
		initcap(ac.full_name),
		CASE
			WHEN ac.region = 'Manawatu' THEN 'MANAWATU_WHANGANUI'
			WHEN ac.region = 'Bay of Plenty' THEN 'BOP'
			ELSE cast(upper(regexp_replace(replace(ac.region, ' ', '_'), '\W+', '', 'g')) AS "Region")
		END my_region,
		-- Club organisers
		ac.id IN (1,27,5,34,55,50,92,147,268,287,591)
		FROM old_public.accounts_cuberprofile ac LEFT JOIN old_public.accounts_account aa ON ac.user_id=aa.id
		WHERE ac.id NOT IN (
			-- test users
			30, 23, 45, 46, 51, 52, 53,
			-- spam users
			530, 563, 596,
			-- in original script, but why delete?
			419, 574,
			-- keyboardspam@test.com
			440,
			-- Duplicates, these have no solves
			611, 391,
			-- Same last name, but first name doesn't match email
			-- Should have used your own email!
			-- (also it has 0 solves)
			615
		) AND ac.email !~ '^help@help\.(com|help)$'
		AND ac.email != 'hello@hello.com'
	);

-- Finished.
INSERT INTO club (id, name)
	(SELECT
		id,
		name
		FROM old_public.organizers_club
	);

-- Finished.
-- TODO: is there better way than case when x is null then '' else end
INSERT INTO meetup (id, name, venue, location, description, contact, competitor_limit, external_registration_link, date, is_published, club_id)
	(SELECT
		id,
		name,
		CASE
			WHEN (venue_details IS NULL OR venue_details = '-') AND (venue IS NULL OR venue= '-')
				THEN 'Unknown'
			WHEN (venue_details IS NULL OR venue_details = '-')
				THEN venue
			WHEN (venue IS NULL OR venue = '-')
				THEN venue_details
			ELSE venue_details || ', ' || venue
		END,
		CASE
			WHEN address IS NULL
				THEN 'Unknown'
			ELSE address
		END,
		CASE
			WHEN description IS NULL
				THEN ''
			ELSE description
		END,
		CASE
			WHEN (contact_email IS NULL OR contact_email = '-')
				THEN 'No contact information.'
			ELSE contact_email
		END,
		competitor_limit,
		registration_link,
		"startTime",
		NOT "isDraft",
		club_id
		FROM old_public.competitions_competition
	);


INSERT INTO organiser_in_meetup (user_id, meetup_id)
	(SELECT
		cco.cuberprofile_id,
		cco.competition_id
		FROM old_public.competitions_competition_organizers cco
		UNION
		SELECT
		ccd.cuberprofile_id,
		ccd.competition_id
		FROM old_public.competitions_competition_delegates ccd
	);


INSERT INTO user_in_meetup (user_id, meetup_id, registered_events)
	(SELECT
		cr.cuber_id,
		cr.comp_id,
		ARRAY_AGG(
			CAST(CASE cee.puzzle
				WHEN '3x3x3' THEN 'THREE'
				WHEN '2x2x2' THEN 'TWO'
				WHEN '4x4x4' THEN 'FOUR'
				WHEN '5x5x5' THEN 'FIVE'
				WHEN '6x6x6' THEN 'SIX'
				WHEN '7x7x7' THEN 'SEVEN'


				WHEN 'Square-1'	THEN 'SQ1'
				WHEN 'Skewb'	THEN 'SKEWB'
				WHEN 'Pyraminx'	THEN 'PYRA'
				WHEN 'Megaminx'	THEN 'MEGA'

				WHEN '3x3x3 One Handed' THEN 'OH'
				WHEN 'Clock' THEN 'CLOCK'

				WHEN 'FMC' THEN		'FMC'
				WHEN '3BLD' THEN	'THREEBLD'
				WHEN '3MBLD' THEN	'MULTIBLD'
			END AS "Puzzle")
		)
	FROM
		old_public.competitions_registration cr
	-- First, inner join with user and meetup in case the id is not valid
	INNER JOIN public.user
		ON public.user.id = cr.cuber_id
	INNER JOIN meetup
		ON meetup.id = cr.comp_id

	-- Then inner join the rest of the data
	INNER JOIN old_public.competitions_registration_events ce
		ON cr.id = ce.registration_id
	INNER JOIN old_public.competitions_event cee
		ON ce.event_id = cee.id
	-- Some values are empty
	WHERE (cr.comp_id IS NOT NULL AND cr.cuber_id IS NOT NULL)
	GROUP BY cr.comp_id, cr.cuber_id
	);


-- TODO: is there way to do this without temp_column
ALTER TABLE round ADD old_id bigint;

INSERT INTO round (id, old_id, start_date, end_date, puzzle, format, proceed_number, meetup_id)
	(
		SELECT
			gen_random_uuid(),
			competitions_event.id,
			"startTime",
			"endTime",
			-- TODO: make this a function so it is not duplicated
			CAST(CASE puzzle
				WHEN '3x3x3' THEN 'THREE'
				WHEN '2x2x2' THEN 'TWO'
				WHEN '4x4x4' THEN 'FOUR'
				WHEN '5x5x5' THEN 'FIVE'
				WHEN '6x6x6' THEN 'SIX'
				WHEN '7x7x7' THEN 'SEVEN'


				WHEN 'Square-1'	THEN 'SQ1'
				WHEN 'Skewb'	THEN 'SKEWB'
				WHEN 'Pyraminx'	THEN 'PYRA'
				WHEN 'Megaminx'	THEN 'MEGA'

				WHEN '3x3x3 One Handed' THEN 'OH'
				WHEN 'Clock' THEN 'CLOCK'

				WHEN 'FMC' THEN		'FMC'
				WHEN '3BLD' THEN	'THREEBLD'
				WHEN '3MBLD' THEN	'MULTIBLD'
			END AS "Puzzle"),
			CAST(UPPER(format) AS "Format"),
			coalesce(proceed, 0),
			comp_id
		FROM old_public.competitions_event
		WHERE
			puzzle != '' AND competitions_event.format != '' AND
			-- TODO: check with tim what he did with this one
				competitions_event.format != 'Bo2/Ao5'
	);

ALTER TABLE result ADD old_id bigint;

INSERT INTO result (old_id, value, user_id, round_id)
	(

		SELECT
			competitions_submission.id,
			coalesce(result, NUMERIC '+inf'),
			cuber_id,
			round.id
		FROM old_public.competitions_submission
		-- Inner join with user to make sure not a deleted user
		INNER JOIN public.user
			ON public.user.id = competitions_submission.cuber_id
		INNER JOIN round
			ON round.old_id = competitions_submission.event_id
	);

ALTER TABLE round DROP COLUMN old_id;

INSERT INTO solve (index, time, result_id)
	(
		SELECT
			ROW_NUMBER() OVER (
				PARTITION BY submission_id
				ORDER BY competitions_solve.id ASC
			) - 1,
			CASE
				WHEN penalty = 'DNF' OR penalty IS NULL THEN NUMERIC '+inf'
				WHEN penalty = '+2' THEN time + 2
				WHEN penalty = 'OK' THEN time
			END,
			result.id
		FROM old_public.competitions_solve
		-- Inner join to ensure result exists
		INNER JOIN result
			ON result.old_id = submission_id
		WHERE
			submission_id IS NOT NULL
	);

ALTER TABLE result DROP COLUMN old_id;


SELECT setval(pg_get_serial_sequence('public.user', 'id'), coalesce(max(id)+1, 1), false) FROM public.user;
SELECT setval(pg_get_serial_sequence('meetup', 'id'), coalesce(max(id)+1, 1), false) FROM meetup;
SELECT setval(pg_get_serial_sequence('club', 'id'), coalesce(max(id)+1, 1), false) FROM club;
SELECT setval(pg_get_serial_sequence('result', 'id'), coalesce(max(id)+1, 1), false) FROM result;

COMMIT;
