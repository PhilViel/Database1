/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                :	DL_UN_SubscriberProfile
Description        :	Supprime le profil d'investisseur du souscripteur
Valeurs de retours :	>0  : Tout à fonctionné
                      <=0 : Erreur SQL
								-1 : Erreur à la création du log	
								-2 : Erreur à la suppression du profil souscripteur
Note               :	2008-11-07  Patrick Robitaille			Création
						2011-05-11	Corentin Menthonnex	Ajout d'un champ au profile souscripteur pour projet 2011-12
						2011-10-24	Christian Chénard		Suppression des champs iID_Identite_Souscripteur et vcIdentiteVerifieeDescription de la journalisation (CRQ_LOG)
						2011-11-01	Christian Chénard		Ajout des champs iID_Estimation_Cout_Etudes et iID_Estimation_Valeur_Nette_Menage
						2012-09-14	Donald Huppé				Ajout de iID_Tolerance_Risque
						2014-09-12	Pierre-Luc Simard		Le log n'est plus créé à la suppression
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_SubscriberProfile] (
	@iConnectID INTEGER, -- ID Unique de connection de l'usager
	@iSubscriberID INTEGER) -- ID Unique du souscripteur
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)
	
	SET @cSep = CHAR(30)

	-----------------
	BEGIN TRANSACTION
	-----------------
	/*
	IF @iSubscriberID > 0
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO CRQ_Log (
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText)
			SELECT
				@iConnectID,
				'Un_Subscriber',
				@iSubscriberID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Profil souscripteur : '+H.LastName+', '+H.FirstName,
				LogText =
					'iID_Connaissance_Placements'+@cSep+CAST(ISNULL(PS.iID_Connaissance_Placements,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_Connaissance_Placements,0) = 0 THEN ''
					ELSE CP.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+				
					'iID_Tolerance_Risque'+@cSep+CAST(ISNULL(PS.iID_Tolerance_Risque,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_Tolerance_Risque,0) = 0 THEN ''
					ELSE CP.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+				
					'iID_Revenu_Familial'+@cSep+CAST(ISNULL(PS.iID_Revenu_Familial,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_Revenu_Familial, 0) = 0 THEN ''
					ELSE RF.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+
					'iID_Depassement_Bareme'+@cSep+CAST(ISNULL(PS.iID_Depassement_Bareme,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_Depassement_Bareme,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(PS.vcDepassementBaremeJustification,'') = '' THEN ''
					ELSE
						'vcDepassementBaremeJustification'+@cSep+PS.vcDepassementBaremeJustification+@cSep+CHAR(13)+CHAR(10)
					END+
					--'iID_Identite_Souscripteur'+@cSep+CAST(ISNULL(PS.iID_Identite_Souscripteur,0) AS CHAR(1))+@cSep+
					--CASE 
					--	WHEN ISNULL(PS.iID_Identite_Souscripteur,0) = 0 THEN ''
					--ELSE IDS.vcDescription+@cSep+CHAR(13)+CHAR(10)
					--END+
					--CASE 
					--	WHEN ISNULL(PS.vcIdentiteVerifieeDescription,'') = '' THEN ''
					--ELSE
					--	'vcIdentiteVerifieeDescription'+@cSep+PS.vcIdentiteVerifieeDescription+@cSep+CHAR(13)+CHAR(10)
					--END+
					'tiNB_Personnes_A_Charge'+@cSep+CAST(ISNULL(PS.tiNB_Personnes_A_Charge,0) AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)+
					'iID_ObjectifInvestissementLigne1'+@cSep+CAST(ISNULL(PS.iID_ObjectifInvestissementLigne1,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_ObjectifInvestissementLigne1, 0) = 0 THEN ''
					ELSE OI1.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+
					'iID_ObjectifInvestissementLigne2'+@cSep+CAST(ISNULL(PS.iID_ObjectifInvestissementLigne2,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_ObjectifInvestissementLigne2, 0) = 0 THEN ''
					ELSE OI2.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+
					'iID_ObjectifInvestissementLigne3'+@cSep+CAST(ISNULL(PS.iID_ObjectifInvestissementLigne3,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_ObjectifInvestissementLigne3, 0) = 0 THEN ''
					ELSE OI3.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+
						
					-- 2011-05-11 : + 2011-12 + CM 
					CASE 
						WHEN ISNULL(PS.vcJustifObjectifsInvestissement,'') = '' THEN ''
					ELSE
						'vcJustifObjectifsInvestissement'+@cSep+PS.vcJustifObjectifsInvestissement+@cSep+CHAR(13)+CHAR(10)
					END+				
					'iID_Estimation_Cout_Etudes'+@cSep+CAST(ISNULL(PS.iID_Estimation_Cout_Etudes,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_Estimation_Cout_Etudes, 0) = 0 THEN ''
					ELSE ECE.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+				
					'iID_Estimation_Valeur_Nette_Menage'+@cSep+CAST(ISNULL(PS.iID_Estimation_Valeur_Nette_Menage,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(PS.iID_Estimation_Valeur_Nette_Menage, 0) = 0 THEN ''
					ELSE VNM.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END
				FROM tblCONV_ProfilSouscripteur PS
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				JOIN dbo.Mo_Human H ON H.HumanID = PS.iID_Souscripteur
				JOIN tblCONV_ConnaissancesPlacements CP ON CP.iID_Connaissance_Placements = PS.iID_Connaissance_Placements
				--JOIN tblCONV_IdentiteSouscripteur IDS ON IDS.iID_Identite_Souscripteur = PS.iID_Identite_Souscripteur
				JOIN tblCONV_ObjectifsInvestissement OI1 ON OI1.iID_Objectif_Investissement = PS.iID_ObjectifInvestissementLigne1
				JOIN tblCONV_ObjectifsInvestissement OI2 ON OI2.iID_Objectif_Investissement = PS.iID_ObjectifInvestissementLigne2
				JOIN tblCONV_ObjectifsInvestissement OI3 ON OI3.iID_Objectif_Investissement = PS.iID_ObjectifInvestissementLigne3
				JOIN tblCONV_RevenuFamilial RF ON RF.iID_Revenu_Familial = PS.iID_Revenu_Familial
				JOIN tblCONV_EstimationCoutEtudes ECE ON ECE.iID_Estimation_Cout_Etudes = PS.iID_Estimation_Cout_Etudes
				JOIN tblCONV_EstimationValeurNetteMenage VNM ON VNM.iID_Estimation_Valeur_Nette_Menage = PS.iID_Estimation_Valeur_Nette_Menage
				WHERE PS.iID_Souscripteur = @iSubscriberID

		IF @@ERROR <> 0
			SET @iSubscriberID = -1
	END
	*/
	IF @iSubscriberID > 0
	BEGIN
		-- Suppression du profil souscripteur
		DELETE tblCONV_ProfilSouscripteur
		WHERE iID_Souscripteur = @iSubscriberID
		IF @@ERROR <> 0
			SET @iSubscriberID = -2
	END
	
	IF @iSubscriberID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	-- Fin des traitements	
	RETURN @iSubscriberID
END
