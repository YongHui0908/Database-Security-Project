-- Server Audit
USE master;
GO



--BACKUP TEST---

*/
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







CREATE SERVER AUDIT LoginLogoutAudit 
TO FILE ( FILEPATH = 'C:\SQL2022' );

ALTER SERVER AUDIT LoginLogoutAudit WITH (STATE = ON);

CREATE SERVER AUDIT SPECIFICATION LoginLogoutAuditSpec
FOR SERVER AUDIT LoginLogoutAudit
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (LOGOUT_GROUP),
ADD (FAILED_LOGIN_GROUP) -- Include failed login attempts
WITH (STATE = ON);

DECLARE @AuditFilePathLoginLogout NVARCHAR(MAX);

SELECT @AuditFilePathLoginLogout = audit_file_path 
FROM sys.dm_server_audit_status 
WHERE NAME = 'LoginLogoutAudit';

SELECT action_id, session_server_principal_name, server_principal_name, server_instance_name
FROM sys.fn_get_audit_file(@AuditFilePathLoginLogout, DEFAULT, DEFAULT);


-- Check if the audit exists, create or enable it
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = 'LoginLogoutAudit')
BEGIN
    -- Enable the existing audit
    ALTER SERVER AUDIT LoginLogoutAudit WITH (STATE = ON);
END
ELSE
BEGIN
    -- Create and enable the audit
    CREATE SERVER AUDIT LoginLogoutAudit 
    TO FILE (FILEPATH = 'C:\SQL2022');
    ALTER SERVER AUDIT LoginLogoutAudit WITH (STATE = ON);
END

-- Check if the audit specification exists, create or enable it
IF EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'LoginLogoutAuditSpec')
BEGIN
    -- Enable the existing audit specification
    ALTER SERVER AUDIT SPECIFICATION LoginLogoutAuditSpec WITH (STATE = ON);
END
ELSE
BEGIN
    -- Create and enable the audit specification
    CREATE SERVER AUDIT SPECIFICATION LoginLogoutAuditSpec
    FOR SERVER AUDIT LoginLogoutAudit
    ADD (SUCCESSFUL_LOGIN_GROUP),
    ADD (LOGOUT_GROUP),
    ADD (FAILED_LOGIN_GROUP)
    WITH (STATE = ON);
END

-- Declare a variable to hold the audit file path
DECLARE @AuditFilePathLoginLogout NVARCHAR(MAX);

-- Retrieve the audit file path
SELECT @AuditFilePathLoginLogout = audit_file_path 
FROM sys.dm_server_audit_status 
WHERE NAME = 'LoginLogoutAudit';

-- Query the audit log for events
SELECT 
    action_id, 
    session_server_principal_name, 
    server_principal_name, 
    server_instance_name
FROM sys.fn_get_audit_file(@AuditFilePathLoginLogout, DEFAULT, DEFAULT);



--

-- Disable the audit specification
ALTER SERVER AUDIT SPECIFICATION LoginLogoutAuditSpec WITH (STATE = OFF);

-- Disable the audit
ALTER SERVER AUDIT LoginLogoutAudit WITH (STATE = OFF);

-- Drop the audit specification
DROP SERVER AUDIT SPECIFICATION LoginLogoutAuditSpec;

-- Drop the audit
DROP SERVER AUDIT LoginLogoutAudit;



CREATE SERVER AUDIT LoginLogoutAudit 
TO FILE ( FILEPATH = 'C:\SQL2022' );

ALTER SERVER AUDIT LoginLogoutAudit WITH (STATE = ON);

CREATE SERVER AUDIT SPECIFICATION LoginLogoutAuditSpec
FOR SERVER AUDIT LoginLogoutAudit
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (LOGOUT_GROUP)
WITH (STATE = ON);

DECLARE @AuditFilePathLoginLogout NVARCHAR(MAX);

SELECT @AuditFilePathLoginLogout = audit_file_path 
FROM sys.dm_server_audit_status 
WHERE NAME = 'LoginLogoutAudit';

SELECT action_id, session_server_principal_name, server_principal_name, server_instance_name
FROM sys.fn_get_audit_file(@AuditFilePathLoginLogout, DEFAULT, DEFAULT);

ALTER SERVER AUDIT LoginLogoutAudit WITH (STATE = OFF);

SELECT action_id, session_server_principal_name, server_principal_name, server_instance_name
FROM sys.fn_get_audit_file(@AuditFilePathLoginLogout, DEFAULT, DEFAULT)

-- Step 1: Declare a variable to hold the audit file path
DECLARE @AuditFilePathLoginLogout NVARCHAR(MAX);

-- Step 2: Retrieve the audit file path for the LoginLogoutAudit
SELECT @AuditFilePathLoginLogout = audit_file_path 
FROM sys.dm_server_audit_status 
WHERE NAME = 'LoginLogoutAudit';

-- Step 3: Check if the variable has been set correctly
IF @AuditFilePathLoginLogout IS NOT NULL
BEGIN
    -- Step 4: Query the audit file using the retrieved file path
    SELECT action_id, 
           session_server_principal_name, 
           server_principal_name, 
           event_time
    FROM sys.fn_get_audit_file(@AuditFilePathLoginLogout, DEFAULT, DEFAULT);
END
ELSE
BEGIN
    PRINT 'Audit file path not found. Please check if the LoginLogoutAudit is created and enabled.';
END
go

-- Declare the variable
DECLARE @AuditFilePathLoginLogout NVARCHAR(MAX);

-- Assign a value to the variable
SELECT @AuditFilePathLoginLogout = audit_file_path 
FROM sys.dm_server_audit_status 
WHERE NAME = 'LoginLogoutAudit';

-- Check if the variable has been assigned a value
IF @AuditFilePathLoginLogout IS NOT NULL
BEGIN
    -- Use the variable in a query
    SELECT action_id, session_server_principal_name, server_principal_name, server_instance_name
    FROM sys.fn_get_audit_file(@AuditFilePathLoginLogout, DEFAULT, DEFAULT);
END
ELSE
BEGIN
    


CREATE SERVER AUDIT Audit_Actions
TO FILE (
	FILEPATH = 'C:\Users\USER\Documents\SQL Server Management Studio\DBS Assignment\Audit\Audit_Actions.audit',
	MAXSIZE = 10 MB, 
	MAX_ROLLOVER_FILES = 5, 
	RESERVE_DISK_SPACE = OFF
	);
GO
SELECT * FROM sys.server_audits WHERE name = 'Audit_Actions';

ALTER SERVER AUDIT Audit_Actions WITH (STATE = OFF);
GO
DROP SERVER AUDIT Audit_Actions;
GO
SELECT name, is_state_enabled 
FROM sys.server_audits
WHERE name = 'Audit_Actions';


SELECT * 
FROM sys.server_audit_specifications
WHERE audit_guid IN (SELECT audit_id FROM sys.server_audits WHERE name = 'Audit_Actions');


-- Drop existing Server Audit Specification if it exists
IF EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'ServerAuditSpec_Actions')
    DROP SERVER AUDIT SPECIFICATION ServerAuditSpec_Actions;
GO

-- Create a new Server Audit Specification
CREATE SERVER AUDIT SPECIFICATION ServerAuditSpec_Actions
FOR SERVER AUDIT Audit_Actions
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP);
GO

-- Enable the Server Audit Specification
ALTER SERVER AUDIT SPECIFICATION ServerAuditSpec_Actions WITH (STATE = ON);
GO

-- Database Audit Specification
USE ApArenaManagementSystemDB;
GO
CREATE DATABASE AUDIT SPECIFICATION Audit_DB_Actions
FOR SERVER AUDIT Audit_Actions
ADD (SELECT ON DATABASE::ApArenaManagementSystemDB BY DataAdmin),
ADD (SELECT ON DATABASE::ApArenaManagementSystemDB BY ComplexManager),
ADD (SELECT ON OBJECT::Users BY DataAdmin),
ADD (SELECT ON OBJECT::Payment BY ComplexManager),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP);
GO


ALTER DATABASE AUDIT SPECIFICATION Audit_DB_Actions WITH (STATE = ON);
GO



-- Check all server audits
SELECT * FROM sys.server_audits;

-- Check all server audit specifications
SELECT * FROM sys.server_audit_specifications;

-- Check active audit specification details
SELECT * 
FROM sys.server_audit_specification_details
WHERE server_specification_id = (
    SELECT server_specification_id 
    FROM sys.server_audit_specifications 
    WHERE name = 'ServerAuditSpec_Actions'
);
