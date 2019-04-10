/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service : fntOPER_ValiderRetransfertRIO
Nom du service  : Valider le retransfert RIO
But             : Valider si une convention collective est élligible à un retransfert RIO
Facette         : OPER

Paramètres d’entrée :	Paramètre					Description
						--------------------------	----------------------------------------------------------------
						@iID_Convention				Identifiant unique de la convention collective

Paramètres de sortie:	Table						Champs					Description
						--------------------------	-----------------------	----------------------------------------
						@tResultat					iElligible				Indicateur d'élligibilité du retransfert
						@tResultat					iConventionDestination	Convention destination si élligible

Exemple d’appel     : SELECT * FROM [dbo].[fntOPER_ValiderRetransfertRIO](191573)

Historique des modifications:
        Date            Programmeur						Description
        ------------    -----------------------------	---------------------------------------------------
        2011-02-28      Frédérick Thibault				Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ValiderRetransfertRIO]
(
   @iID_Convention INTEGER
)

RETURNS  @tResultat	TABLE 
						(
						 iElligible				TINYINT
						,iConventionDestination	INTEGER
						)

BEGIN
	
	DECLARE  @iElligible				TINYINT
			,@iConventionDestination	INTEGER
			,@ConventionStateID			CHAR(3)
		
	SET @iConventionDestination = NULL
	
	SELECT @iConventionDestination = iID_Convention_Destination
	FROM tblOPER_OperationsRIO
	WHERE iID_Convention_Source = @iID_Convention
	
	-- La convention a-t-elle déjà fait l'objet d'une conversion ?
	IF @iConventionDestination IS NOT NULL
		BEGIN
		
		SELECT @ConventionStateID = ConventionStateID
		FROM Un_ConventionConventionState CS
		WHERE CS.ConventionID = @iConventionDestination
		AND CS.StartDate = (SELECT MAX(StartDate)
							FROM Un_ConventionConventionState CS2
							WHERE CS2.ConventionID = CS.ConventionID
							) 
		
		--  Si la convention individuelle (cible) n'est pas fermée : élligible
		IF @ConventionStateID <> 'FRM'
			SET @iElligible = 1
		ELSE
			BEGIN
			
			-- La convention individuelle a été fermée:
			-- Est-ce qu'une autre convention individuelle ouverte existe pour le bénéficiaire / souscripteur ?
			SELECT   @iConventionDestination		= CInd.ConventionID
			
			FROM		dbo.Un_Convention CInd
			JOIN		dbo.Un_Convention CCol				ON CCol.ConventionID  = @iID_Convention
			JOIN		Un_Plan PL						ON PL.PlanID = CInd.PlanID
			JOIN		tblCONV_RegroupementsRegimes RR	ON RR.iID_Regroupement_Regime = PL.iID_Regroupement_Regime
			JOIN		dbo.Un_Unit UInd					ON UInd.ConventionID = CInd.ConventionID 
			JOIN		Un_ConventionConventionState CS	ON CS.ConventionID = CInd.ConventionID
			LEFT JOIN	dbo.Mo_Human H						ON CCol.BeneficiaryID = H.HumanId
			LEFT JOIN	dbo.Mo_Human H2						ON CInd.BeneficiaryID = H2.HumanId
			LEFT JOIN	Mo_Adr AH						ON H.AdrID = AH.AdrId
			LEFT JOIN	Mo_Adr AH2						ON H2.AdrId = AH2.AdrId
			LEFT JOIN	dbo.Mo_Human HS						ON CCol.SubscriberID = HS.HumanId
			LEFT JOIN	dbo.Mo_Human HS2					ON CInd.SubscriberID = HS2.HumanId
			LEFT JOIN	Mo_Adr AHS						ON HS.AdrID = AHS.AdrId
			LEFT JOIN	Mo_Adr AHS2						ON HS2.AdrId = AHS2.AdrId
			LEFT JOIN	dbo.Mo_Human HCS					ON CCol.CoSubscriberID = HCS.HumanId
			LEFT JOIN	dbo.Mo_Human HCS2					ON CInd.CoSubscriberID = HCS2.HumanId
			LEFT JOIN	Mo_Adr AHCS						ON HCS.AdrID = AHCS.AdrId
			LEFT JOIN	Mo_Adr AHCS2					ON HCS2.AdrId = AHCS2.AdrId
			
			WHERE	RR.vcCode_Regroupement = 'IND'
			
			AND		(CCol.BeneficiaryID		= CInd.BeneficiaryID 
						OR H.SocialNumber	= H2.SocialNumber 
						OR (H.LastName		= H2.LastName AND H.FirstName = H2.FirstName AND H.BirthDate= H2.BirthDate AND H.SexId = H2.SexId AND AH.ZipCode=AH2.ZipCode))
			
			AND		(ISNULL(CCol.SubscriberID,0)	= ISNULL(CInd.SubscriberID,0)
						OR HS.SocialNumber		= HS2.SocialNumber 
						OR (HS.LastName			= HS2.LastName 
									AND HS.FirstName	= HS2.FirstName 
									AND HS.BirthDate	= HS2.BirthDate 
									AND HS.SexId		= HS2.SexId 
									AND AHS.ZipCode		= AHS2.ZipCode))
			
			AND		(ISNULL(CCol.CoSubscriberID,0)	= ISNULL(CInd.CoSubscriberID,0)
						OR HCS.SocialNumber		= HCS2.SocialNumber 
						OR (HCS.LastName		= HCS2.LastName 
									AND HCS.FirstName	= HCS2.FirstName 
									AND HCS.BirthDate	= HCS2.BirthDate 
									AND HCS.SexId		= HCS2.SexId 
									AND AHCS.ZipCode	= AHCS2.ZipCode))
			
			AND		CS.StartDate = (SELECT MAX(StartDate)
									FROM Un_ConventionConventionState CS2
									WHERE CS2.ConventionID = CInd.ConventionID)
			
			AND		CS.ConventionStateID <> 'FRM'
			
			GROUP BY CInd.ConventionID
			HAVING CInd.ConventionID = MAX(CInd.ConventionID)
			
			IF @@ROWCOUNT > 0
				-- Il existe une convention individuelle ouverte
				SET @iElligible = 1
			ELSE
				BEGIN
				-- Aucune autre convention individuelle n'existe alors le retransfert n'est pas permis
				SET @iElligible = 0
				SET @iConventionDestination = NULL
				END
			
			END
		
		END
	ELSE
		BEGIN
		
		SET @iElligible = 0
		SET @iConventionDestination = NULL
		
		END
		

	INSERT INTO @tResultat VALUES
					(
					 @iElligible
					,@iConventionDestination
					)
	
	RETURN
	
END 
