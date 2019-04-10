
CREATE PROCEDURE [dbo].[psTempChangerMotPassePortail] (
	@iUserIdOrigine int = 601813, 
	@Subscriberid int
	 )
AS
BEGIN
-- Outil créé pour tester le portail en test
-- exec psTempChangerMotPassePortail @iUserIdOrigine = 601813, @Subscriberid= 706614

/*
SELECT * 
from tblGENE_PortailAuthentification p
JOIN dbo.Mo_Human h ON p.iUserId = h.HumanID
--where h.HumanID = 159491
WHERE h.LastName = 'marion' AND h.FirstName LIKE '%marie-Eve%'
*/

if not exists (SELECT HumanID FROM dbo.Mo_Human where HumanID = @Subscriberid)
	begin
	 select changementFait = '!!!! Cet ID d''humain n''existe pas !!!! '
	 return
	end

IF @@servername = 'SRVSQL12'
	begin
	 select changementFait = '!!!! Cet outil est interdit en production !!!! '
	 return
	end

delete from tblGENE_PortailAuthentification where iUserId = @Subscriberid

INSERT INTO [tblGENE_PortailAuthentification]
           ([iUserId]
           ,[vbMotPasse]
           ,[iEtat]
           ,[iQS1id]
           ,[iQS2id]
           ,[iQS3id]
           ,[vbRQ1]
           ,[vbRQ2]
           ,[vbRQ3]
           ,[dtDernierAcces]
           ,[iCompteurEssais]
           ,[vbCleConfirmationMD5]
           ,[dtInscription]
           )
select
			[iUserId] = @Subscriberid
           ,[vbMotPasse]
           ,[iEtat]
           ,[iQS1id]
           ,[iQS2id]
           ,[iQS3id]
           ,[vbRQ1]
           ,[vbRQ2]
           ,[vbRQ3]
           ,[dtDernierAcces]
           ,[iCompteurEssais]
           ,[vbCleConfirmationMD5]
           ,[dtInscription]
 from   tblGENE_PortailAuthentification     
 where iUserId = @iUserIdOrigine
 
 select changementFait = 'Fait.'
 
 end
 

