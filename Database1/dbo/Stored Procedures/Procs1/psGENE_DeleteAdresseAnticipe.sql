/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	psGENE_DeleteAdresseAnticipe
Description 	:	Destruction d'adresse anticipés
exec psGENE_DeleteAdresseAnticipe @SourceID

Notes :			2012-02-14	Eric Michaud	Création
*******************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_DeleteAdresseAnticipe] (
	@SourceID INTEGER)
AS
BEGIN

DECLARE @iID_Utilisateur_Systeme INT
	
SELECT TOP 1 @iID_Utilisateur_Systeme = CASE WHEN S.SubscriberID IS NOT NULL THEN MCS.ConnectID ELSE 0 END
FROM dbo.Mo_Human H
		LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
		JOIN tblGENE_TypesParametre TPS ON TPS.vcCode_Type_Parametre = 'GENE_AUTHENTIFICATION_SOUSC_CONNECTID' 
		JOIN tblGENE_Parametres PS ON TPS.iID_Type_Parametre = PS.iID_Type_Parametre
		JOIN Mo_Connect MCS ON PS.vcValeur_Parametre = MCS.ConnectID
WHERE H.HumanID = @SourceID

IF @iID_Utilisateur_Systeme <> 0 
BEGIN
	delete MA
	FROM dbo.Mo_Adr  MA
	JOIN dbo.Mo_Adr  MAS ON MA.AdrID = MAS.AdrID 
	JOIN dbo.Mo_Adr  MAB ON MA.AdrID = MAB.AdrID 
	WHERE (MAS.SourceID IN (SELECT @SourceID) OR
		  MAB.SourceID IN (SELECT DISTINCT Be.BeneficiaryId
							FROM dbo.Un_Subscriber Su 
							JOIN dbo.Un_Convention unCon on unCon.subscriberid = su.SubscriberId
							JOIN dbo.Un_Beneficiary Be on unCon.BeneficiaryId = Be.BeneficiaryId 
							WHERE Su.subscriberID = @SourceID))
		 AND MAS.ConnectID = MAB.ConnectID
		 AND MAS.CountryID = MAB.CountryID
		 AND MAS.inforce = MAB.inforce
		 AND MAS.Address = MAB.Address
		 AND MAS.City = MAB.City
		 AND isnull(MAS.StateName,1) = isnull(MAB.StateName,1)
		 AND isnull(MAS.ZipCode,1) = isnull(MAB.ZipCode,1)
		 AND MAS.Phone1 = MAB.Phone1
	     AND datediff(dd,dateadd(dd,1,getdate()),ma.InForce) >= 0
	     AND @iID_Utilisateur_Systeme = MA.ConnectID														
	
END
ELSE
BEGIN 
	DELETE
	FROM dbo.Mo_Adr  
	WHERE SourceID = @SourceID AND
--		 datediff(dd,getdate(),InForce) >= 0
		 datediff(dd,dateadd(dd,1,getdate()),InForce) >= 0
END
		
END


