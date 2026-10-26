/* =====================================================================
   07_backup_restore.sql
   Backup strategy: a full backup every night and a differential backup
   every 6 hours. Change the folder (C:\Backups\) to one that exists on
   your machine and that the SQL Server service account can write to.

   Scheduling: in SQL Server Developer/Standard edition, create SQL Server
   Agent jobs for the two BACKUP commands. SQL Server Express has no
   Agent, so run them with sqlcmd from Windows Task Scheduler, e.g.:
     sqlcmd -S .\SQLEXPRESS -E -Q "BACKUP DATABASE SchoolDB TO DISK = N'C:\Backups\SchoolDB_FULL.bak' WITH INIT, CHECKSUM"
   ===================================================================== */

-- 1) Full backup (daily at 11:00 PM); INIT overwrites the previous file
BACKUP DATABASE SchoolDB
TO DISK = N'C:\Backups\SchoolDB_FULL.bak'
WITH INIT, CHECKSUM, NAME = N'SchoolDB - full backup';
GO

-- 2) Differential backup (every 6 hours): all changes since the last full backup
BACKUP DATABASE SchoolDB
TO DISK = N'C:\Backups\SchoolDB_DIFF.bak'
WITH DIFFERENTIAL, INIT, CHECKSUM, NAME = N'SchoolDB - differential backup';
GO

-- 3) Check that the backup files can be read
RESTORE VERIFYONLY FROM DISK = N'C:\Backups\SchoolDB_FULL.bak' WITH CHECKSUM;
RESTORE VERIFYONLY FROM DISK = N'C:\Backups\SchoolDB_DIFF.bak' WITH CHECKSUM;
GO

/* 4) Recovery after a failure (run only when you need to restore):
      first the full backup WITH NORECOVERY, then the latest differential.

USE master;
ALTER DATABASE SchoolDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE SchoolDB FROM DISK = N'C:\Backups\SchoolDB_FULL.bak' WITH REPLACE, NORECOVERY;
RESTORE DATABASE SchoolDB FROM DISK = N'C:\Backups\SchoolDB_DIFF.bak' WITH RECOVERY;
ALTER DATABASE SchoolDB SET MULTI_USER;
*/
