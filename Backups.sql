

-- Backup
BACKUP DATABASE ApArenaManagementSystemDB
TO DISK = 'C:\SQL2022\ApArenaManagementSystemDB.bak'
GO

-- Create another copy of this database on the same server
RESTORE DATABASE ApArenaManagementSystemDB_encrypted
FROM DISK = 'C:\SQL2022\ApArenaManagementSystemDB.bak'
WITH MOVE 'ApArenaManagementSystemDB' TO 'C:\SQL2022\ApArenaManagementSystemDB.mdf',
MOVE 'ApArenaManagementSystemDB_log' TO 'C:\SQL2022\ApArenaManagementSystemDB_log.ldf'

ALTER DATABASE ApArenaManagementSystemDB_encrypted MODIFY FILE ( NAME = ApArenaManagementSystemDB, NEWNAME = ApArenaManagementSystemDB_encrypted);
ALTER DATABASE ApArenaManagementSystemDB_encrypted MODIFY FILE ( NAME = ApArenaManagementSystemDB_log, NEWNAME = ApArenaManagementSystemDB_encrypted_log);

-- Perform encryption on the database
-- Create master key and certificate 
use master
go
create master key encryption by password = 'masterkey12'
go



Create Certificate CertMasterDB 
With Subject = 'CertMasterDB'
go

/
select * from sys.symmetric_keys
select * from sys.certificates
*/

-- Enable TDE for databases
use ApArenaManagementSystemDB_encrypted
go

CREATE DATABASE ENCRYPTION KEY  
   WITH ALGORITHM = AES_128
   ENCRYPTION BY SERVER CERTIFICATE CertMasterDB;
go

ALTER DATABASE ApArenaManagementSystemDB_encrypted
SET ENCRYPTION ON;

Use master
select b.name as [DB Name], a.encryption_state_desc, a.key_algorithm, a.encryptor_type
from sys.dm_database_encryption_keys a
inner join sys.databases b on a.database_id = b.database_id
where b.name = 'ApArenaManagementSystemDB_encrypted'

-- Backup encrypted database
BACKUP DATABASE ApArenaManagementSystemDB_encrypted 
TO DISK = 'C:\Temp\ApArenaManagementSystemDB_encrypted.bak'

Use master
Go
BACKUP CERTIFICATE CertMasterDB 
TO FILE = N'C:\Temp\CertMasterDB.cert'
WITH PRIVATE KEY (
    FILE = N'C:\Temp\CertMasterDB.key', 
ENCRYPTION BY PASSWORD = 'masterpassword123'
);
Go

/*
======================================== Backup for anoter server/instance ==================================================
*/
/*
USE MASTER
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MyBackUpPassword12345'

USE MASTER
GO
Create CERTIFICATE CertMasterDB 
From FILE = N'C:\Temp2\CertMasterDB.cert'
WITH PRIVATE KEY (
    FILE = N'C:\Temp2\CertMasterDB.key', 
DECRYPTION BY PASSWORD = 'masterpassword123'
);


RESTORE DATABASE APU_Sports_Equipment_encrypted
FROM DISK = 'C:\Temp2\APU_Sports_Equipment_encrypted.bak'
WITH MOVE 'APU_Sports_Equipment_encrypted' TO 'C:\Temp2\APU_Sports_Equipment_encrypted.mdf',
MOVE 'APU_Sports_Equipment_encrypted_log' TO 'C:\Temp2\APU_Sports_Equipment_encrypted_log.ldf'
*/





--------



-- Automate backups
-- BACKUP DATABASE ApArenaManagementSystemDB
-- TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\ApArenaManagementSystemDB.bak'
-- WITH FORMAT, INIT, SKIP, CHECKSUM, NAME = 'Full Backup';

-- Create Full Backup Job
EXEC msdb.dbo.sp_add_job @job_name = 'Full Backup';

-- Add Step for Full Backup
EXEC msdb.dbo.sp_add_jobstep 
   @job_name = 'Full Backup',
   @step_name = 'Run Full Backup',
   @subsystem = 'TSQL',
   @command = 
       'BACKUP DATABASE ApArenaManagementSystemDB
        TO DISK = ''C:\APDIFFBackup\ApArenaManagementSystemDB_Full.bak''
        WITH FORMAT, INIT, NAME = ''Full Backup'', CHECKSUM;',
   @on_success_action = 1;

-- Create Schedule for Full Backup (Daily at 12:00 AM)
EXEC msdb.dbo.sp_add_schedule 
   @schedule_name = 'Daily at Midnight',
   @freq_type = 4, -- Daily
   @freq_interval = 1, -- Every Day
   @active_start_time = 000000; -- 12:00 AM


   SELECT schedule_id, name
FROM msdb.dbo.sysschedules
WHERE name = 'Daily at Midnight';

-- Attach Schedule to Job
-- Replace '1' with the actual schedule_id you retrieved
EXEC msdb.dbo.sp_attach_schedule 
    @job_name = 'Full Backup',
    @schedule_id = 9; -- Schedule ID obtained from the previous query


-- Add the Job to the Server
EXEC msdb.dbo.sp_add_jobserver 
   @job_name = 'Full Backup';




-- Differential Backup Script (Runs every 6 hours)
EXEC msdb.dbo.sp_add_job @job_name = 'Differential Backup';

EXEC msdb.dbo.sp_add_jobstep 
   @job_name = 'Differential Backup',
   @step_name = 'Run Differential Backup',
   @subsystem = 'TSQL',
   @command = 
       'BACKUP DATABASE ApArenaManagementSystemDB
        TO DISK = ''C:\APDIFFBackup\ApArenaManagementSystemDB_Diff.bak''
        WITH DIFFERENTIAL, NAME = ''Differential Backup'';',
   @on_success_action = 1;

EXEC msdb.dbo.sp_add_schedule 
   @schedule_name = 'Every 6 Hours',
   @freq_type = 4, -- Daily
   @freq_interval = 1, -- Every Day
   @freq_subday_type = 8, -- Hours
   @freq_subday_interval = 6, -- Every 6 Hours
   @active_start_time = 0;

EXEC msdb.dbo.sp_attach_schedule 
   @job_name = 'Differential Backup',
   @schedule_name = 'Every 6 Hours';

EXEC msdb.dbo.sp_add_jobserver 
   @job_name = 'Differential Backup';




-- Create Transaction Log Backup Job
EXEC msdb.dbo.sp_add_job @job_name = 'Transaction Log Backup';

-- Add Step for Transaction Log Backup
EXEC msdb.dbo.sp_add_jobstep 
   @job_name = 'Transaction Log Backup',
   @step_name = 'Run Transaction Log Backup',
   @subsystem = 'TSQL',
   @command = 
       'BACKUP LOG ApArenaManagementSystemDB
        TO DISK = ''C:\APDIFFBackup\ApArenaManagementSystemDB_Log.bak''
        WITH NAME = ''Transaction Log Backup'', CHECKSUM;',
   @on_success_action = 1;

-- Create Schedule for Transaction Log Backup (Every 30 Minutes)
EXEC msdb.dbo.sp_add_schedule 
   @schedule_name = 'Every 30 Minutes',
   @freq_type = 4, -- Daily
   @freq_interval = 1, -- Every Day
   @freq_subday_type = 4, -- Minutes
   @freq_subday_interval = 30; -- Every 30 Minutes

-- Attach Schedule to Job
EXEC msdb.dbo.sp_attach_schedule 
   @job_name = 'Transaction Log Backup',
   @schedule_name = 'Every 30 Minutes';

-- Add the Job to the Server
EXEC msdb.dbo.sp_add_jobserver 
   @job_name = 'Transaction Log Backup';




-- Full Backup Script
BACKUP DATABASE ApArenaManagementSystemDB
TO DISK = 'C:\APDIFFBackup\ApArenaManagementSystemDB_Full.bak'
WITH FORMAT, INIT, NAME = 'Full Backup';

-- Differential Backup Script (Runs every 6 hours)
BACKUP DATABASE ApArenaManagementSystemDB
TO DISK = 'C:\APDIFFBackup\ApArenaManagementSystemDB_Diff.bak'
WITH DIFFERENTIAL, NAME = 'Differential Backup';

-- Transaction Log Backup Script
BACKUP LOG ApArenaManagementSystemDB
TO DISK = 'C:\APDIFFBackup\ApArenaManagementSystemDB_Log.bak'
WITH NAME = 'Transaction Log Backup';
