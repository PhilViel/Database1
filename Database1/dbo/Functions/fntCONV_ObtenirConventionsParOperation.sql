/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntCONV_ObtenirConventionsParOperation
Nom du service		: Obtenir les conventions d'une opération
But 				: Obtenir les conventions d'une opération
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Oper					Identifiant unique de l'opération dont on cherche les conventions liées
						bObtenirIndividuelles		Booléen pour obtenir ou non les convention individuelles liées
						bObtenirCollectives			Booléen pour obtenir ou non les convention collectives liées

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Un_Convention				Données complètes
	
Exemple d'appel : 

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2011-04-19		Corentin Menthonnex			Création du service
		2015-07-29		Steve Picard				Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
		
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirConventionsParOperation]
    (
      @iID_Oper					INT ,
      @bObtenirIndividuelles	BIT,
      @bObtenirCollectives		BIT
    )
RETURNS @Convention TABLE
    (
		ConventionID							INT			NOT NULL,
		PlanID									INT			NOT NULL,				
		SubscriberID							INT			NOT NULL,
		BeneficiaryID							INT			NOT NULL,
		ConventionNo							VARCHAR(15) NOT NULL,
		YearQualif								INT			NOT NULL,
		FirstPmtDate							DATETIME	NOT NULL,
		PmtTypeID								CHAR(3)		NOT NULL,
		ScholarshipYear							SMALLINT	NOT NULL,
		ScholarshipEntryID						CHAR(1)		NOT NULL,
		GovernmentRegDate						DATETIME,
		CoSubscriberID							INT,
		DiplomaTextID							INT,
		bSendToCESP								BIT			NOT NULL,
		bCESGRequested							BIT			NOT NULL,
		bACESGRequested							BIT			NOT NULL,
		bCLBRequested							BIT			NOT NULL,
		tiRelationshipTypeID					TINYINT		NOT NULL,
		tiCESPState								TINYINT		NOT NULL,
		dtRegStartDate							DATETIME,
		InsertConnectID							INT,
		LastUpdateConnectID						INT,
		dtRegEndDateAdjust						DATETIME,
		dtInforceDateTIN						DATETIME,
		bSouscripteur_Desire_IQEE				INT,
		iID_Destinataire_Remboursement			INT,
		dtDateProspectus						DATETIME,
		vcDestinataire_Remboursement_Autre		VARCHAR(50),
		tiID_Lien_CoSouscripteur				TINYINT,
		bFormulaireRecu							BIT			NOT NULL,
		iSous_Cat_ID_Resp_Prelevement			INT,
		bTuteur_Desire_Releve_Elect				BIT
    )
AS
    BEGIN
		INSERT INTO @Convention
			SELECT DISTINCT CV.ConventionID,
							CV.PlanID,
							CV.SubscriberID,
							CV.BeneficiaryID,
							CV.ConventionNo,
							CV.YearQualif,
							CV.FirstPmtDate,
							CV.PmtTypeID,
							CV.ScholarshipYear,
							CV.ScholarshipEntryID,
							CV.GovernmentRegDate,
							CV.CoSubscriberID,
							0, --CV.DiplomaTextID,		-- 2015-07-29
							CV.bSendToCESP,
							CV.bCESGRequested,
							CV.bACESGRequested,
							CV.bCLBRequested,
							CV.tiRelationshipTypeID,
							CV.tiCESPState,
							CV.dtRegStartDate,
							CV.InsertConnectID,
							CV.LastUpdateConnectID,
							CV.dtRegEndDateAdjust,
							CV.dtInforceDateTIN,
							CV.bSouscripteur_Desire_IQEE,
							CV.iID_Destinataire_Remboursement,
							CV.dtDateProspectus,
							CV.vcDestinataire_Remboursement_Autre,
							CV.tiID_Lien_CoSouscripteur,
							CV.bFormulaireRecu,
							CV.iSous_Cat_ID_Resp_Prelevement,
							CV.bTuteur_Desire_Releve_Elect
			FROM Un_Oper OP
			LEFT JOIN Un_ConventionOper CO ON CO.OperID = OP.OperID
			LEFT JOIN Un_Cotisation CT ON CT.OperID = OP.OperID
				JOIN dbo.Un_Unit UN on UN.UnitID = CT.UnitID
			LEFT JOIN Un_CESP CE ON CE.OperID = OP.OperID
			JOIN dbo.Un_Convention CV ON CV.ConventionID = CO.ConventionID OR CV.ConventionID = UN.ConventionID OR CV.ConventionID = CE.ConventionID
			JOIN Un_Plan PL ON PL.PlanID = CV.PlanID
			WHERE OP.OperID = @iID_Oper
				AND (   ((@bObtenirIndividuelles = 1  AND @bObtenirCollectives = 1) AND (PL.PlanTypeID = 'IND' OR PL.PlanTypeID = 'COL'))
						OR ((@bObtenirIndividuelles = 0  AND @bObtenirCollectives = 1) AND PL.PlanTypeID = 'COL')
						OR ((@bObtenirIndividuelles = 1  AND @bObtenirCollectives = 0) AND PL.PlanTypeID = 'IND')
					)
		
		RETURN
	END


