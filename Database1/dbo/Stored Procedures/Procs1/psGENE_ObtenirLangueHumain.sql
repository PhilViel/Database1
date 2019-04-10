/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Nom du service		: psGENE_ObtenirLangueHumain
But 				: Obtenir la langue de l'humain 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cConventionno				numéro de la convention
						humanID						ID du souscripteur

Exemple d’appel		:	EXECUTE psGENE_ObtenirLangueHumain 'I-20121012019', null
						EXECUTE psGENE_ObtenirLangueHumain 'I-20120509001', null
						EXECUTE psGENE_ObtenirLangueHumain '2037998,U-20011219005,U-20011219006', null

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-10-04		Maxime Martel						Création du service		
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirLangueHumain] 
(
	@cConventionno varchar(15) = null, 
	@humanID integer = null
)
AS
BEGIN
	
	if charindex(',',@cConventionno, 0) <> 0
		set @cConventionno = SUBSTRING(@cConventionno, 0, charindex(',',@cConventionno, 0) )
	
	IF @cConventionno is not null
	BEGIN
		SELECT
			L.vcLangueRapportSSRS
		FROM dbo.Un_Convention C JOIN
            Mo_Human H ON C.SubscriberID = h.HumanID join Mo_Lang L on H.LangID = L.LangID
		WHERE C.ConventionNo = @cConventionno
	END
	else 
	BEGIN
		SELECT
			l.vcLangueRapportSSRS 
		FROM dbo.Mo_Human h join Mo_Lang L on H.LangID = l.LangID
		WHERE H.HumanID = @humanID 
	END

END


