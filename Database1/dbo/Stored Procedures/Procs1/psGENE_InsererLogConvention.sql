/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psGENE_InsererLogConvention
Nom du service		: insérer le log de la nouvelle convention
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psGENE_InsererLogConvention

Paramètres de sortie:	

Historique des modifications:
		Date				Programmeur					Description									Référence
		------------		-------------------------	-----------------------------------------	------------
		2014-09-19			Donald Huppé				Création du service	
		2014-10-29			Donald Huppé				Ajout du log du compte bancaire
		2014-11-11			Pierre-Luc Simard			Retrait du log du champ tiCESPState et des bRequest puisque gérés par la procédure psCONV_EnregistrerPrevalidationPCEE
		2015-01-09			Donald Huppé				Ajout de @LoginName
		2015-07-29			Steve Picard				Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_InsererLogConvention] (
	@ConventionID int,
	@ConnectID int,
	@LoginName varchar(50) = NULL
	)
	
AS
BEGIN

declare @cSep CHAR(1)

SET @cSep = CHAR(30)

	-- Insère un log de l'objet inséré.
	INSERT INTO CRQ_Log (
		LoginName,
		ConnectID,
		LogTableName,
		LogCodeID,
		LogTime,
		LogActionID,
		LogDesc,
		LogText)
		SELECT
			@LoginName,
			@ConnectID,
			'Un_Convention',
			@ConventionID,
			GETDATE(),
			LA.LogActionID,
			LogDesc = 'Convention : '+C.ConventionNo,
			LogText =
				'SubscriberID'+@cSep+CAST(C.SubscriberID AS VARCHAR)+@cSep+ISNULL(S.LastName+', '+S.FirstName,'')+@cSep+CHAR(13)+CHAR(10)+
				CASE 
					WHEN ISNULL(C.CoSubscriberID,0) <= 0 THEN ''
				ELSE 'CoSubscriberID'+@cSep+CAST(C.CoSubscriberID AS VARCHAR)+@cSep+ISNULL(CS.LastName+', '+CS.FirstName,'')+@cSep+CHAR(13)+CHAR(10)
				END+
				'BeneficiaryID'+@cSep+CAST(C.BeneficiaryID AS VARCHAR)+@cSep+ISNULL(B.LastName+', '+B.FirstName,'')+@cSep+CHAR(13)+CHAR(10)+
				'PlanID'+@cSep+CAST(C.PlanID AS VARCHAR)+@cSep+ISNULL(P.PlanDesc,'')+@cSep+CHAR(13)+CHAR(10)+
				'ConventionNo'+@cSep+C.ConventionNo+@cSep+CHAR(13)+CHAR(10)+
				'FirstPmtDate'+@cSep+CONVERT(CHAR(10), C.FirstPmtDate, 20)+@cSep+CHAR(13)+CHAR(10)+
				'PmtTypeID'+@cSep+C.PmtTypeID+@cSep+
				CASE C.PmtTypeID
					WHEN 'AUT' THEN 'Automatique'
					WHEN 'CHQ' THEN 'Chèque'
				ELSE ''
				END+@cSep+
				CHAR(13)+CHAR(10)+
				'tiRelationshipTypeID'+@cSep+CAST(C.tiRelationshipTypeID AS VARCHAR)+@cSep+
				CASE C.tiRelationshipTypeID
					WHEN 1 THEN 'Père/Mère'
					WHEN 2 THEN 'Grand-père/Grand-mère'
					WHEN 3 THEN 'Oncle/Tante'
					WHEN 4 THEN 'Frère/Soeur'
					WHEN 5 THEN 'Aucun lien de parenté'
					WHEN 6 THEN 'Autre'
					WHEN 7 THEN 'Organisme'
				ELSE ''
				END+@cSep+
				CHAR(13)+CHAR(10)+
				CASE 
					WHEN ISNULL(C.GovernmentRegDate,0) <= 0 THEN ''
				ELSE 'GovernmentRegDate'+@cSep+CONVERT(CHAR(10), C.GovernmentRegDate, 20)+@cSep+CHAR(13)+CHAR(10)
				END+
				CASE 
					WHEN ISNULL(C.TexteDiplome,'') = '' THEN ''
					ELSE 'TexteDiplome'+@cSep+ISNULL(TexteDiplome,'')+@cSep+CHAR(13)+CHAR(10)		-- 2015-07-29
				END+
				'bSendToCESP'+@cSep+CAST(ISNULL(C.bSendToCESP,1) AS VARCHAR)+@cSep+
				CASE 
					WHEN ISNULL(C.bSendToCESP,1) = 0 THEN 'Non'
				ELSE 'Oui'
				END+@cSep+
				CHAR(13)+CHAR(10)+/*
				'bCESGRequested'+@cSep+CAST(ISNULL(C.bCESGRequested,1) AS VARCHAR)+@cSep+
				CASE 
					WHEN ISNULL(C.bCESGRequested,1) = 0 THEN 'Non'
				ELSE 'Oui'
				END+@cSep+
				CHAR(13)+CHAR(10)+
				'bACESGRequested'+@cSep+CAST(ISNULL(C.bACESGRequested,1) AS VARCHAR)+@cSep+
				CASE 
					WHEN ISNULL(C.bACESGRequested,1) = 0 THEN 'Non'
				ELSE 'Oui'
				END+@cSep+
				CHAR(13)+CHAR(10)+
				'bCLBRequested'+@cSep+CAST(ISNULL(C.bCLBRequested,1) AS VARCHAR)+@cSep+
				CASE 
					WHEN ISNULL(C.bCLBRequested,1) = 0 THEN 'Non'
				ELSE 'Oui'
				END+@cSep+
				CHAR(13)+CHAR(10)+
				'tiCESPState'+@cSep+CAST(ISNULL(C.tiCESPState,0) AS VARCHAR)+@cSep+
				CASE ISNULL(C.tiCESPState,0)
					WHEN 1 THEN 'SCEE'
					WHEN 2 THEN 'SCEE et BEC'
					WHEN 3 THEN 'SCEE et SCEE+'
					WHEN 4 THEN 'SCEE, SCEE+ et BEC'
				ELSE ''
				END+@cSep+
				CHAR(13)+CHAR(10)+*/						
				CASE 
					WHEN ISNULL(C.iID_Destinataire_Remboursement,0) <= 0 THEN ''
				ELSE 'iID_Destinataire_Remboursement'+@cSep+CAST(ISNULL(C.iID_Destinataire_Remboursement,0) AS VARCHAR)+@cSep+
				CASE C.iID_Destinataire_Remboursement
					WHEN 1 THEN 'Souscripteur'
					WHEN 2 THEN 'Bénéficiaire'
					WHEN 3 THEN 'Autre'
				ELSE ''
				END+@cSep+
				CHAR(13)+CHAR(10)
				END+
				CASE 
					WHEN ISNULL(C.vcDestinataire_Remboursement_Autre,'') = '' THEN ''
				ELSE 'vcDestinataire_Remboursement_Autre'+@cSep+C.vcDestinataire_Remboursement_Autre+@cSep+CHAR(13)+CHAR(10)
				END+
				CASE 
					WHEN ISNULL(C.dtDateProspectus,0) <= 0 THEN ''
				ELSE 'dtDateProspectus'+@cSep+CONVERT(CHAR(10), C.dtDateProspectus, 20)+@cSep+CHAR(13)+CHAR(10)
				END+
				'bSouscripteur_Desire_IQEE'+@cSep+CAST(ISNULL(C.bSouscripteur_Desire_IQEE,1) AS VARCHAR)+@cSep+
				CASE 
					WHEN ISNULL(C.bSouscripteur_Desire_IQEE,1) = 0 THEN 'Non'
				ELSE 'Oui'
				END+@cSep+
				CHAR(13)+CHAR(10)+
				CASE 
					WHEN ISNULL(C.tiID_Lien_CoSouscripteur,0) <= 0 THEN ''
				ELSE 'tiID_Lien_CoSouscripteur'+@cSep+CAST(ISNULL(C.tiID_Lien_CoSouscripteur,0) AS VARCHAR)+@cSep+
				CASE C.tiID_Lien_CoSouscripteur
					WHEN 1 THEN 'Père/Mère'
					WHEN 2 THEN 'Grand-père/Grand-mère'
					WHEN 3 THEN 'Oncle/Tante'
					WHEN 4 THEN 'Frère/Soeur'
					WHEN 5 THEN 'Aucun lien de parenté'
					WHEN 6 THEN 'Autre'
					WHEN 7 THEN 'Organisme'
				ELSE ''
				END+@cSep+
				CHAR(13)+CHAR(10)+
				'bTuteur_Desire_Releve_Elect'+@cSep+CAST(ISNULL(C.bTuteur_Desire_Releve_Elect,1) AS VARCHAR)+@cSep+
				CASE 
					WHEN ISNULL(C.bTuteur_Desire_Releve_Elect,1) = 0 THEN 'Non'
				ELSE 'Oui'
				END+@cSep+
				CHAR(13)+CHAR(10)
				END/*+@cSep+
				CHAR(13)+CHAR(10)+						
				CASE 
					WHEN ISNULL(C.iID_Justification_Conv_Incomplete,0) <= 0 THEN ''
				ELSE 'iID_Justification_Conv_Incomplete'+@cSep+CAST(ISNULL(C.iID_Justification_Conv_Incomplete,0) AS VARCHAR)+@cSep+
				CASE C.iID_Justification_Conv_Incomplete
					WHEN 1 THEN 'Transfert In'
				ELSE ''
				END+@cSep+
				CHAR(13)+CHAR(10)
				END*/
			FROM dbo.Un_Convention C
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
			LEFT JOIN dbo.Mo_Human CS ON CS.HumanID = C.CoSubscriberID
			JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
			JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			--LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID		-- 2015-07-29
			WHERE C.ConventionID = @ConventionID

	IF EXISTS (SELECT 1 FROM Un_ConventionAccount WHERE ConventionID = @ConventionID)

	BEGIN

		INSERT INTO CRQ_Log (
			LoginName,
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText)
			SELECT
				@LoginName,
				@ConnectID,
				'Un_Convention',
				@ConventionID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Compte bancaire de convention : '+C.ConventionNo,
				LogText =
					'BankID'+@cSep+CAST(AC.BankID AS VARCHAR)+@cSep+ISNULL(BT.BankTypeCode+'-'+B.BankTransit,'')+@cSep+CHAR(13)+CHAR(10)+
					'AccountName'+@cSep+AC.AccountName+@cSep+CHAR(13)+CHAR(10)+
					'TransitNo'+@cSep+AC.TransitNo+@cSep+CHAR(13)+CHAR(10)
				FROM dbo.Un_Convention C
				JOIN Un_ConventionAccount AC ON AC.ConventionID = C.ConventionID
				JOIN Mo_Bank B ON B.BankID = AC.BankID
				JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
				WHERE C.ConventionID = @ConventionID
	END
end


