# Scripts & SQL queries to migrate data from the old database.

### Steps
1. set up db
```
npx prisma db push
```
2. set your password in the script
3. run migration script:
```
psql -d db -U postgres < migrate.sql
```
