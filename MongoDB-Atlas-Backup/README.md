# MongoDB Atlas Automated Backup & Restore

This toolkit provides robust, foolproof Windows CMD scripts to automate daily backups and manage the restoration of your MongoDB Atlas databases locally.

Instead of manually running `mongodump` commands or writing custom scripts for every project, these scripts utilize a unified configuration file, automatic gzip compression, date-based folder organization, and built-in retention policies to keep your local drive from filling up.

## What it Does

1. **Automated Backups:** Creates compressed `.gz` backups organized into clean `YYYY-MM-DD` folders.
2. **Auto-Cleanup (Retention Policy):** Automatically scans and deletes backup folders older than your configured threshold (e.g., 7 days) to save disk space.
3. **Interactive Safe Restore:** The `restore.cmd` script uses dynamic numbered menus to let you easily pick a backup date and database to restore. It intentionally ignores the saved connection string and forces you to paste the target URI manually to prevent accidental production overwrites.
4. **Public Repo Safe:** Designed with a decoupled `config.cmd` file so the scripts can be safely committed to public repositories without leaking your Atlas credentials.

## Prerequisites

You must have the following installed on your Windows machine:

1. **[MongoDB Database Tools](https://www.mongodb.com/try/download/database-tools?utm_source=gemini):** This provides the `mongodump` and `mongorestore` commands. Ensure the `bin` folder is added to your Windows System PATH.
2. **Windows PowerShell:** Required internally by the scripts to safely format timestamps and parse database names.

## Usage

1. Clone or download this repository.
2. Duplicate the `config.example.cmd` file and rename the copy to `config.cmd`.
3. Edit `config.cmd` and insert your MongoDB Atlas URI, your local backup destination path, and your desired retention days. *(Note: Ensure `config.cmd` is added to your `.gitignore` if you are tracking this folder with Git).*
4. **To Backup:** Double-click `backup.cmd`. You will see a 10-second countdown before the backup begins.
5. **To Automate Backups:** Open Windows Task Scheduler, create a "Basic Task" set to run daily, and point the action to your `backup.cmd` file. Check "Run whether user is logged on or not" in the task properties for silent background execution.
6. **To Restore:** Double-click `restore.cmd` and follow the on-screen interactive prompts.

## Disclaimer

**Use these scripts at your own risk.**

While these scripts include built-in safety checks, any automated data operation carries risk.

* **Configuration:** Ensure your local machine is secure if you are storing your MongoDB Atlas URI in plaintext within `config.cmd`.
* **Restoration Overwrites:** The `restore.cmd` tool gives you the option to `--drop` existing collections before restoring. Doing this on the wrong target URI will permanently wipe your existing data before replacing it. Always double-check your connection strings and test restores in a development environment first.