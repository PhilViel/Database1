/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service			: psTEMP_PCEEActiverBECSurconventionREE
Nom du service			: Procedure pour activer le BEC sur les conventions REE
But 					:  script original créé en 2015 (GLPI_14627 - Activer BEC sur convention REEE.SQL)
							Doit rouler à tous les fin de mois
Facette					: TEMP

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------

Exemple d’appel        :    exec psTEMP_PCEEActiverBECSurconventionREE


Paramètres de sortie:    

Historique des modifications:
    Date        Programmeur                 Description                                    Référence
    ----------  ------------------------    -----------------------------------------    ------------
    2013-02-27  Donald Huppé                Création du service        

***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_PCEEActiverBECSurconventionREE]

AS
BEGIN

		DECLARE 
			@BeneficiaryID INT,
			@ConnectID INT,
			@cSep CHAR(1),
			@iMaxConventionID INT

		--SET @BeneficiaryID = 634375
		SET @ConnectID = 2			
		SET @cSep = CHAR(30)

		SELECT 
			ConventionAActiver = C.ConventionID,
			--Etat = dbo.fnCONV_ObtenirStatutConventionEnDate(C.ConventionID, GETDATE()),
			ConventionADesactiver = dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 0, NULL)
		INTO #tConv -- drop table #tConv
		FROM Un_Convention C
		WHERE C.BeneficiaryID = ISNULL(@BeneficiaryID, C.BeneficiaryID)
			AND C.tiCESPState IN (2, 4) -- La convention passe les prévalidations pour le BEC
			AND C.SCEEFormulaire93BECRefuse = 0 -- Le BEC n'est pas refusé
			AND C.bCLBRequested = 0
			AND dbo.FN_CRQ_DateNoTime(C.dtRegStartDate) <= GETDATE()
			AND dbo.fnCONV_ObtenirStatutConventionEnDate(dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 0, NULL),GETDATE()) <> 'REE' -- La convention qui gère actuellement le BEC n'est pas à l'état REEE
			AND C.ConventionID = dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 1, NULL) -- La convention est celle suggérée
	
		SELECT 
			ConventionADesactiver = CD.ConventionNo,
			ConventionAActiver = CA.ConventionNo,
			CA.BeneficiaryID 
		FROM #tConv TC
		JOIN Un_Convention CA ON CA.ConventionID = TC.ConventionAActiver
		JOIN Un_Convention CD ON CD.ConventionID = TC.ConventionADesactiver
		ORDER BY CA.BeneficiaryID

		--RETURN

		/****** CORRECTION ******/

		-- Désactiver le BEC dans la convention qui n'est pas REEE
			SELECT @iMaxConventionID = MAX(TC.ConventionADesactiver) 
			FROM #tConv TC 
			JOIN Un_Convention C ON C.ConventionID = TC.ConventionADesactiver
					            		
			-- Boucler à travers les conventions pour désactiver les demandes		
			WHILE @iMaxConventionID	IS NOT NULL
				BEGIN
					EXECUTE psPCEE_DesactiverBec NULL, @ConnectID, @iMaxConventionID, 0
																	
					SELECT @iMaxConventionID = MAX(TC.ConventionADesactiver) 
					FROM #tConv TC
					JOIN Un_Convention C ON C.ConventionID = TC.ConventionADesactiver
					WHERE TC.ConventionADesactiver < @iMaxConventionID	
				END

		-- Mise à jour du champ bCLBRequested des convention REEE
			UPDATE C
			SET bCLBRequested = 1
			FROM Un_Convention C 
			JOIN #tConv TC ON TC.ConventionAActiver = C.ConventionID

		-- Faire la demande de BEC
			SELECT @iMaxConventionID = MAX(TC.ConventionAActiver) 
			FROM #tConv TC
			JOIN Un_Convention C ON C.ConventionID = TC.ConventionAActiver
            		
			-- Boucler à travers les conventions REEE pour créer les demandes		
			WHILE @iMaxConventionID	IS NOT NULL
				BEGIN
					EXECUTE TT_UN_CLB @iMaxConventionID		
											
					SELECT @iMaxConventionID = MAX(TC.ConventionAActiver) 
					FROM #tConv TC
					JOIN Un_Convention C ON C.ConventionID = TC.ConventionAActiver
					WHERE TC.ConventionAActiver < @iMaxConventionID	
				END
						
		-- Insertion du log sur les conventions modifiées
			INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Convention',
					C.ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Convention : ' + C.ConventionNo,
					LogText =
						'bCLBRequested'+@cSep+
						'0'+@cSep+
						'1'+@cSep+
						'Non'+@cSep+
						'Oui'+@cSep+
						CHAR(13)+CHAR(10)
					FROM #tConv TC
					JOIN Un_Convention C ON C.ConventionID = TC.ConventionAActiver
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'

			INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Convention',
					C.ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Convention : ' + C.ConventionNo,
					LogText =
						'bCLBRequested'+@cSep+
						'1'+@cSep+
						'0'+@cSep+
						'Oui'+@cSep+
						'Non'+@cSep+
						CHAR(13)+CHAR(10)
					FROM #tConv TC
					JOIN Un_Convention C ON C.ConventionID = TC.ConventionADesactiver
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
					

END