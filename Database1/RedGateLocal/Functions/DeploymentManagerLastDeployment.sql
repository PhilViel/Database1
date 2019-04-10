
			CREATE FUNCTION [RedGateLocal].[DeploymentManagerLastDeployment] ()
			RETURNS @ret TABLE (PackageName NVARCHAR(MAX), PackageVersion NVARCHAR(MAX))
			AS
			BEGIN
				INSERT @ret VALUES (N'UnivBase.Production', N'3.2.4.6710');
				RETURN;
			END