/**********************************************************************************************************************
Code de service :   psCONV_InitialiserPreferencesCommunicationSiegeSocial
Nom du service	:	psCONV_InitialiserPreferencesCommunicationSiegeSocial
But				:	Initialiser le nouveau champs de préférences de communications du siège social
Facette			:		
Reférence		:		

Parametres d'entrée :	
        Parametres			Obligatoire     Description                                 
        ----------          -----------     ----------------
		@SubscriberID       Non             Si spécifié, la mise à jour ne se fait que pour ce souscripteur

Exemple d'appel:
				EXECUTE dbo.ps_InitialiserPreferencesCommunicationSiegeSocial
				
Historique des modifications :

		Date        Programmeur             Description
		----------  --------------------    ------------------------------------------
		2016-07-13	Patrice Côté            Création de la procédure
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_InitialiserPreferencesCommunicationSiegeSocial]
(
	@SubscriberID INT = NULL
)

AS
BEGIN

	DECLARE @tblCourrielTemp TABLE
	(
		iID_Source int,
		cType_Source CHAR(1),
		vcCourriel VARCHAR(80),
		dtDate_Debut DATE,
		bInvalide BIT
	)
	  
	;WITH CTE_Courriel AS (
			SELECT iID_Source, cType_Source, vcCourriel, dtDate_Debut, bInvalide,
				   Row_Num = ROW_NUMBER() OVER(PARTITION BY iID_Source ORDER BY dtDate_Debut DESC)
			  FROM (SELECT * from dbo.fntGENE_CourrielEnDate_PourTous (GETDATE(), @SubscriberID, DEFAULT, 0)) FonctionCourriel
		)
		INSERT INTO @tblCourrielTemp (iID_Source, cType_Source, vcCourriel, dtDate_Debut, bInvalide)
		SELECT iID_Source, cType_Source, vcCourriel, dtDate_Debut, bInvalide
		  FROM CTE_Courriel
		 WHERE Row_Num = 1 AND (ISNULL(@SubscriberID, 1) = 1 OR iID_Source = @SubscriberID)
	     

	UPDATE Un_Subscriber SET iID_Preference_Suivi_Siege_Social = tblPreferencesSiegeSocialTemp.iID_Preference_Suivi_SiegeSocial  
	FROM
	(
		SELECT CASE WHEN PSREP.vcCode_Preference_Suivi = 'P' THEN (SELECT iID_Preference_Suivi FROM tblCONV_PreferenceSuivi WHERE vcCode_Preference_Suivi = 'P') 
					WHEN PSREP.vcCode_Preference_Suivi = 'C' THEN (SELECT iID_Preference_Suivi FROM tblCONV_PreferenceSuivi WHERE vcCode_Preference_Suivi = 'C')
					WHEN PSREP.vcCode_Preference_Suivi = 'T' THEN 
							CASE WHEN C.vcCourriel IS NULL THEN (SELECT iID_Preference_Suivi FROM tblCONV_PreferenceSuivi WHERE vcCode_Preference_Suivi = 'P') 
							ELSE (SELECT iID_Preference_Suivi FROM tblCONV_PreferenceSuivi WHERE vcCode_Preference_Suivi = 'C')
							END
					ELSE 1
				END AS iID_Preference_Suivi_SiegeSocial,
		S.SubscriberID, S.iID_Preference_Suivi, C.vcCourriel 
		FROM Un_Subscriber S 
			JOIN tblCONV_PreferenceSuivi PSREP 
				ON S.iID_Preference_Suivi = PSREP.iID_Preference_Suivi
			LEFT JOIN @tblCourrielTemp C ON S.SubscriberID = C.iID_Source  
		WHERE ISNULL(@SubscriberID, 1) = 1 OR SubscriberID = @SubscriberID
	) tblPreferencesSiegeSocialTemp 
	WHERE Un_Subscriber.SubscriberID = tblPreferencesSiegeSocialTemp.SubscriberID


END
