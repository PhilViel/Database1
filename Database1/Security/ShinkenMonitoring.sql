CREATE ROLE [ShinkenMonitoring]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [ShinkenMonitoring] ADD MEMBER [UNIVERSITAS\shinken-svc];

