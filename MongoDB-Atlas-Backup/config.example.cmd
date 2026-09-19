:: ==========================================
:: MONGODB BACKUP CONFIGURATION
:: ==========================================
:: Rename this file to config.cmd and fill in your details.
:: IMPORTANT: config.cmd should be ignored by git!

:: Your Atlas connection string (Keep the quotes around the URI)
set MONGO_URI="mongodb+srv://<username>:<password>@<cluster-url>.mongodb.net/<dbname>"

:: Where to save the backups locally
set "BACKUP_DIR=F:\DB Backups\FOLDER NAME"

:: How many days of backups to retain
set RETENTION_DAYS=7