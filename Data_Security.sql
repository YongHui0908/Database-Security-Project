-- Switch to the database
USE ApArenaManagementSystemDB;

-- Create encryption key and certificate
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongMasterKeyPassword1!';
CREATE CERTIFICATE ApArenaCert WITH SUBJECT = 'Data Encryption Certificate';

-- Create symmetric key for encryption
CREATE SYMMETRIC KEY DataKey 
WITH ALGORITHM = AES_256 
ENCRYPTION BY CERTIFICATE ApArenaCert;

-- Encrypt sensitive columns in Users table
OPEN SYMMETRIC KEY DataKey DECRYPTION BY CERTIFICATE ApArenaCert;

-- Encrypt Email and PhoneNumber
UPDATE Users
SET Email = ENCRYPTBYKEY(KEY_GUID('DataKey'), Email),
    PhoneNumber = ENCRYPTBYKEY(KEY_GUID('DataKey'), PhoneNumber);

CLOSE SYMMETRIC KEY DataKey;

-- Decryption Example: Retrieve encrypted data securely
OPEN SYMMETRIC KEY DataKey DECRYPTION BY CERTIFICATE ApArenaCert;
SELECT UserID,
       CONVERT(NVARCHAR, DECRYPTBYKEY(Email)) AS DecryptedEmail,
       CONVERT(NVARCHAR, DECRYPTBYKEY(PhoneNumber)) AS DecryptedPhoneNumber
FROM Users;
CLOSE SYMMETRIC KEY DataKey;

-- Log encryption operations to AuditLog
INSERT INTO AuditLog (UserID, Action, TableName, Details)
VALUES (NULL, 'Encrypt Data', 'Users', 'Email and PhoneNumber columns encrypted using DataKey');

-- Add guidelines for key rotation and secure management (Documented for clarity)
-- 1. Rotate the symmetric key periodically and re-encrypt sensitive data.
-- 2. Store the master key password securely using a hardware security module (HSM) or a secure vault.
-- 3. Audit all operations involving encryption keys.

-- Ensure RBAC implementation restricts access to encryption keys and decryption functionality
-- Example: Only Data Admins have access to encryption and decryption processes.

-- End of updated script
