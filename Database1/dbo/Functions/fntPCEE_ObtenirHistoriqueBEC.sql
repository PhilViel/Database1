
/****************************************************************************************************
Code de service		:		fntPCEE_ObtenirHistoriqueBEC
Nom du service		:		1.1.1 Obtenir l'historique du BEC 
But					:		Obtenir l'historique complet du BEC
Description			:		Ce service reçoit en paramètre l'identifiant unique d'un bénéficiaire
							Toutes les transactions reliées au BEC y sont affichées : les demandes,
							les remboursements, les versements annuels, les transferts entre convention
							ainsi que les désactivations
Facette				:		PCEE
Reférence			:		Document psPCEE_ObtenirHistoriqueBEC.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						iID_Beneficiare				Identifiant unique du bénéficiaire

Exemples d'appel:
			SELECT * FROM dbo.fntPCEE_ObtenirHistoriqueBEC(418719, 'FRA')
			SELECT * FROM dbo.fntPCEE_ObtenirHistoriqueBEC(479667, NULL)
			SELECT * FROM dbo.fntPCEE_ObtenirHistoriqueBEC(479667, 'ENU')
			SELECT * FROM dbo.fntPCEE_ObtenirHistoriqueBEC(415835, 'FRA')
			SELECT * FROM dbo.fntPCEE_ObtenirHistoriqueBEC(420887, 'FRA')
			


Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						@tHistoriqueBEC				dtOperDate									Date de l'opération
													vcAction									Action de la transaction
													ConventionNo								Numéro de la convention							
													vcTransID									Identifiant de la transaction PCEE
													dtCESPSendFile								Date d'envoi du fichier
													dtRead										Date de réception du fichier
													mMontant									Montant BEC
													vcCESP9000CESGReason						Raison du PCEE
													siCESP800ErrorID							Code d'erreur s'il y a lieu			

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-15					Jean-François Gauthier					Création de la fonction
						2009-10-22					Jean-François Gauthier					Ajout du Order By
						2009-12-11					Jean-François Gauthier					Ajout de la raison pour le SCEE
						2010-01-05					Jean-François Gauthier					Modification du CASE pour le statut
																							Élimination du champ vcCESP9000ACESGReason
																							Ajout d'un CASE afin de ne pas toujours afficher la raison vcCESP900CESGReason
																							Ajout du champ vcCESP800Error contenant la description de l'erreur
						2010-01-06					Jean-François Gauthier					Ajout du champ bRenverse
						2010-01-06					Jean-François Gauthier					Correction d'une erreur de syntaxe dans les codes de retour
						2010-01-07					Jean-François Gauthier					Modification afin d'aller chercher les descriptions des actions BEC dans
																							la table tblCONV_ActionBEC
																							Ajout du paramètre de langue
						2010-01-12					Jean-François Gauthier					Intégration des modifications de Pierre Paquet
						2010-01-13					Jean-François Gauthier					Patch les NULL pour iCESP900ID 
						2010-01-15					Jean-François Gauthier					Correction d'un code de description erroné
						2010-01-21					Jean-François Gauthier					Modification de la validation du "non renversé"
						2010-02-15					Pierre Paquet							Ajout de AND ce.vcBeneficiarySIN = @vcNAS afin d'afficher uniquement les trx du bénéf.
						2010-02-15					Jean-François Gauthier					Ajout du tri sur la date
						2010-02-16					Pierre Paquet							Utiliser l'historique des NAS
						2010-04-15					Pierre Paquet							Correction: remplacer BEC015 par BEC014.
						2010-04-15					Pierre Paquet							Ajout du 'BEC remboursé'.
						2010-04-15					Pierre Paquet							Correction sur trx de renversement.
						2010-04-19					Pierre Paquet							Ajout du message 'BEC016'.
						2010-05-06					Pierre Paquet							Correction: Renversement BEC009.
						2010-05-07					Pierre Paquet							Correction: retirer les liens avec iID_Beneficiaire.
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fntPCEE_ObtenirHistoriqueBEC]
	(
		@iIDBeneficiaire	INT
		,@cLangue			CHAR(3)		
	)
RETURNS @tHistoriqueBEC TABLE
			(
				iCESP400ID				INT				-- IDENTIFIANT DE LA TRANSACTION 400
				,iCESP900ID				INT				-- IDENTIFIANT DE LA TRANSACTION 900
				,dtOperDate				DATETIME		-- DATE DE L'OPÉRATION
				,vcAction				VARCHAR(75)		-- ACTION DE LA TRANSACTION
				,ConventionNo			VARCHAR(15)		-- NUMÉRO DE CONVENTION
				,vcTransID				VARCHAR(15)		-- IDENTIFIANT DE LA TRANSACTION PCEE
				,mMontant				MONEY			-- MONTANT DU BEC
				,vcCESP9000CESGReason	VARCHAR(200)	-- RAISON DU PCEE
				,siCESP800ErrorID		SMALLINT		-- CODE D'ERREUR S'IL Y A LIEU			
				,dtEnvoi				DATETIME		-- DATE D'ENVOI DE LA TRANSACTION
				,dtReception			DATETIME		-- DATE DE RÉCEPTION DE LA RÉPONSE DU PCEE
				,vcCESP800Error			VARCHAR(200)	-- DESCRIPTION DE L'ERREUR S'IL Y A LIEU
				,bRenverse				BIT				-- INDIQUE SI LA TRANSACTION EST RENVERSÉE
			)
AS
	BEGIN
--		DECLARE @vcNAS	VARCHAR(75)
/*
		-- 1. RÉCUPÉRER LE NAS DU BÉNÉFICIAIRE
		SELECT
			@vcNAS = h.SocialNumber	
		FROM
			dbo.Mo_Human h
		WHERE
			h.HumanID = @iIDBeneficiaire
*/

		-- 1. RÉCUPÉRER LES NAS DU BÉNÉFICIAIRE
		DECLARE @NASBeneficiaire TABLE (vcNAS VARCHAR(75))

		INSERT INTO @NASBeneficiaire
		(vcNAS)
		 SELECT SocialNumber
			FROM UN_HumanSocialNumber 
			WHERE HumanID = @iIDBeneficiaire
	
			
		-- 2. RÉCUPÉRER TOUTES LES TRANSACTIONS 400 RELIÉES AU BEC
		 INSERT INTO @tHistoriqueBEC 
		(
			iCESP400ID	
			,iCESP900ID	
			,dtOperDate		
			,vcAction		
			,ConventionNo	
			,vcTransID		
			,dtEnvoi			
			,dtReception
			,mMontant		
			,vcCESP9000CESGReason
			,siCESP800ErrorID
			-- ,vcCESP9000ACESGReason	-- JFG : 2010-01-05 : Éliminé car non utilisé
			,vcCESP800Error
			,bRenverse
		)
		-- LES RÉPONSES DU PCEE
		SELECT
			DISTINCT
				ce.iCESP400ID
				,ce9.iCESP900ID
				,NULL
				,CASE	
						WHEN ce.iReversedCESP400ID IS NOT NULL AND ce9.cCESP900CESGReasonID = '0' THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC016', @cLangue)
						WHEN ce.tiCESP400TypeID = 24 AND ce9.fCLB > 0	THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC001', @cLangue)
						WHEN ce9.fCLB < 0	THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC015', @cLangue)
			  			ELSE dbo.fnPCEE_ObtenirDescActionBEC('BEC014', @cLangue)
				END	
				,ce.ConventionNO
				,ce.vcTransID
    			, NULL 
				,rf.dtRead 
				,ce9.fCLB 
				,CASE
					WHEN ce9.cCESP900CESGReasonID <> '0' THEN rea92.vcCESP900CESGReason
					ELSE
						NULL
				END
				,ce8.siCESP800ErrorID
				,ce8Err.vcCESP800Error
				,CASE	WHEN	ceRev.iReversedCESP400ID IS NOT NULL THEN 1
						ELSE	0
				 END 
		FROM
				dbo.UN_CESP900 ce9
				LEFT JOIN dbo.Un_CESP400 ce
					ON ce.iCESP400ID = ce9.iCESP400ID
				LEFT OUTER JOIN dbo.Un_CESP400 ceRev
					ON ce.iCESP400ID = ceRev.iReversedCESP400ID
				LEFT OUTER JOIN dbo.Un_CESPReceiveFile rf
					ON ce9.iCESPReceiveFileID = rf.iCESPReceiveFileID 
				INNER JOIN dbo.Un_Convention co
					ON co.ConventionID = ce.ConventionID
				LEFT OUTER JOIN dbo.Un_CESP900ACESGReason rea9
					ON rea9.cCESP900ACESGReasonID = ce9.cCESP900ACESGReasonID
				LEFT OUTER JOIN dbo.Un_CESP900CESGReason rea92
					ON rea92.cCESP900CESGReasonID = ce9.cCESP900CESGReasonID
				LEFT OUTER JOIN dbo.Un_CESP800 ce8
					ON ce.iCESP800ID = ce8.iCESP800ID
				LEFT OUTER JOIN dbo.Un_CESP800Error ce8Err
					ON ce8.siCESP800ErrorID = ce8Err.siCESP800ErrorID
		WHERE
			--	co.BeneficiaryID	= @iIDBeneficiaire
			--	AND
				(		
					ce.tiCESP400TypeId	= 24
					OR
					(ce.tiCESP400TypeId IN (13,19,21,23) AND ce.fCLB<>0)
				)
				AND ce.iCESP800ID IS NULL
				AND ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
		UNION 
		-- OPÉRATION
		SELECT
			DISTINCT
				ce.iCESP400ID
				,99999999
				,ce.dtTransaction
				,CASE	
						WHEN ce.tiCESP400TypeID = 24 AND ce.bCESPDemand = 1 THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC002', @cLangue)
						WHEN ce.tiCESP400TypeID = 24 AND ce.bCESPDemand = 0 THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC003', @cLangue)
						WHEN ce.tiCESP400TypeID = 19						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC004', @cLangue)
						WHEN ce.tiCESP400TypeID = 23						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC005', @cLangue)
						WHEN ce.tiCESP400TypeID = 21						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC006', @cLangue)
						WHEN ce.tiCESP400TypeID = 13						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC007', @cLangue)
				END	
				,ce.ConventionNO
				,ce.vcTransID
				,sf.dtCESPSendFile
				,NULL 
				,CASE
					WHEN ce.tiCESP400TypeID = 24 THEN 0
					ELSE ce.fCLB		
				 END
				,NULL
				,ce8.siCESP800ErrorID
				,ce8Err.vcCESP800Error
				,CASE	WHEN	ceRev.iReversedCESP400ID IS NOT NULL THEN 1
						ELSE	0
				 END 
		FROM
			dbo.Un_Oper o
			INNER JOIN dbo.Un_CESP400 ce
				ON o.OperID = ce.OperID
			LEFT OUTER JOIN dbo.Un_CESP400 ceRev
				ON ce.iCESP400ID = ceRev.iReversedCESP400ID
			LEFT OUTER JOIN dbo.Un_CESPSendFile sf
				ON ce.iCESPSendFileID = sf.iCESPSendFileID
			INNER JOIN dbo.Un_Convention co
				ON co.ConventionID = ce.ConventionID
			LEFT OUTER JOIN dbo.Un_CESP800 ce8
				ON ce.iCESP800ID = ce8.iCESP800ID
			LEFT OUTER JOIN dbo.Un_CESP800Error ce8Err
				ON ce8.siCESP800ErrorID = ce8Err.siCESP800ErrorID
		WHERE
			--ce.vcBeneficiarySIN = @vcNAS -- Ajout le 2010-02-15
			ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
		--	AND
		--	co.BeneficiaryID	= @iIDBeneficiaire
			AND
			(ce.tiCESP400TypeId	= 24
			OR
			(ce.tiCESP400TypeId IN (13,19,21,23) AND ce.fCLB <>0))
			AND 
				NOT EXISTS (SELECT 1 FROM UN_CESP400 c42 WHERE c42.iREVERSEDCESP400ID = ce.iCESP400ID) 
			AND 
				ce.iREVERSEDCESP400ID IS NULL -- 2010-04-15 Pierre Paquet
			AND NOT EXISTS (SELECT 1 FROM dbo.Un_CESP400 u2 WHERE ce.iCESP400ID = u2.iReversedCESP400ID AND u2.iCESP800ID IS NULL)	-- NON RENVERSÉ
		UNION 
		-- AFFICHAGE DES ERREURS
		SELECT
			DISTINCT
				ce.iCESP400ID
				,99999999
				,NULL
				,dbo.fnPCEE_ObtenirDescActionBEC('BEC014', @cLangue)
				,ce.ConventionNO
				,ce.vcTransID
				,NULL
				,rf.dtRead 
				,CASE
					WHEN ce.tiCESP400TypeID = 24 THEN 0
					ELSE ce.fCLB		
				 END
				,'ERR - ' + CONVERT(varchar(10), ce.iCESP800ID) + ' ' + ce8Err.vcCESP800Error
				,ce8.siCESP800ErrorID
				,ce8Err.vcCESP800Error
				,CASE	WHEN	ceRev.iReversedCESP400ID IS NOT NULL THEN 1
						ELSE	0
				 END 
		FROM
			dbo.Un_Oper o
			INNER JOIN dbo.Un_CESP400 ce
				ON o.OperID = ce.OperID
			LEFT OUTER JOIN dbo.Un_CESP400 ceRev
				ON ce.iCESP400ID = ceRev.iReversedCESP400ID
			INNER JOIN dbo.Un_Convention co
				ON co.ConventionID = ce.ConventionID
			LEFT OUTER JOIN dbo.Un_CESP800 ce8
				ON ce.iCESP800ID = ce8.iCESP800ID
			LEFT OUTER JOIN dbo.Un_CESP800Error ce8Err
				ON ce8.siCESP800ErrorID = ce8Err.siCESP800ErrorID
			LEFT JOIN dbo.Un_CESPReceiveFile rf
				ON ce8.iCESPReceiveFileID = rf.iCESPReceiveFileID 
		WHERE
			ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
			AND
		--	co.BeneficiaryID	= @iIDBeneficiaire
		--	AND
			(ce.tiCESP400TypeId	= 24
			OR
			(ce.tiCESP400TypeId IN (13,19,21,23) AND ce.fCLB <>0))
			AND 
			ce.iCESP800ID IS NOT NULL
		UNION
		-- OPÉRATIONS RENVERSÉES
		SELECT 
			DISTINCT
				ce.iCESP400ID
				,99999999
				,ce.dtTransaction 
				,CASE	
						WHEN ce.tiCESP400TypeID = 24 AND ce.bCESPDemand = 1 THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC002', @cLangue)
						WHEN ce.tiCESP400TypeID = 24 AND ce.bCESPDemand = 0 THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC003', @cLangue)
						WHEN ce.tiCESP400TypeID = 19						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC004', @cLangue)
						WHEN ce.tiCESP400TypeID = 23						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC005', @cLangue)
						WHEN ce.tiCESP400TypeID = 21						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC006', @cLangue)
						WHEN ce.tiCESP400TypeID = 13						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC007', @cLangue)
				END	
				,ce.ConventionNO
				,ce.vcTransID
				,sf.dtCESPSendFile
				,NULL 
				,CASE
					WHEN ce.tiCESP400TypeID = 24 THEN 0
					ELSE ce.fCLB		
				 END
				,NULL
				,ce8.siCESP800ErrorID
				,ce8Err.vcCESP800Error
				,CASE	WHEN	ceRev.iReversedCESP400ID IS NOT NULL THEN 1
						ELSE	0
				 END 
		FROM
			dbo.Un_Oper o
			INNER JOIN dbo.Un_CESP400 ce
				ON o.OperID = ce.OperID
			LEFT OUTER JOIN dbo.Un_CESP400 ceRev
				ON ce.iCESP400ID = ceRev.iReversedCESP400ID
			LEFT OUTER JOIN dbo.Un_CESPSendFile sf
				ON ce.iCESPSendFileID = sf.iCESPSendFileID
			INNER JOIN dbo.Un_Convention co
				ON co.ConventionID = ce.ConventionID
			LEFT OUTER JOIN dbo.Un_CESP800 ce8
				ON ce.iCESP800ID = ce8.iCESP800ID
			LEFT OUTER JOIN dbo.Un_CESP800Error ce8Err
				ON ce8.siCESP800ErrorID = ce8Err.siCESP800ErrorID
		WHERE
			ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
			AND
		--	co.BeneficiaryID	= @iIDBeneficiaire
		--	AND
			(ce.tiCESP400TypeId	= 24
			OR
			(ce.tiCESP400TypeId IN (13,19,21,23) AND ce.fCLB <>0))
			AND EXISTS (SELECT 1 FROM UN_CESP400 c42 WHERE c42.iREVERSEDCESP400ID = ce.iCESP400ID) 
		UNION
		-- LES RENVERSEMENTS
		SELECT 
			DISTINCT
				ce.iCESP400ID
				,99999999
				,ce.dtTransaction 
				,CASE	
						WHEN ce.tiCESP400TypeID = 24						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC008', @cLangue) + ' '  +  (SELECT vcTransID FROM UN_CESP400 c400 WHERE c400.iCESP400ID = ce.iREVERSEDCESP400ID)
						--WHEN ce.tiCESP400TypeID = 24 AND ce.bCESPDemand = 0 THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC009', @cLangue) + ' '  +  (SELECT vcTransID FROM UN_CESP400 c400 WHERE c400.iCESP400ID = ce.iREVERSEDCESP400ID)
						WHEN ce.tiCESP400TypeID = 19						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC010', @cLangue) + ' '  +  (SELECT vcTransID FROM UN_CESP400 c400 WHERE c400.iCESP400ID = ce.iREVERSEDCESP400ID)
						WHEN ce.tiCESP400TypeID = 23						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC011', @cLangue) + ' '  +  (SELECT vcTransID FROM UN_CESP400 c400 WHERE c400.iCESP400ID = ce.iREVERSEDCESP400ID)
						WHEN ce.tiCESP400TypeID = 21						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC012', @cLangue) + ' '  +  (SELECT vcTransID FROM UN_CESP400 c400 WHERE c400.iCESP400ID = ce.iREVERSEDCESP400ID)
						WHEN ce.tiCESP400TypeID = 13						THEN dbo.fnPCEE_ObtenirDescActionBEC('BEC013', @cLangue) + ' '  +  (SELECT vcTransID FROM UN_CESP400 c400 WHERE c400.iCESP400ID = ce.iREVERSEDCESP400ID)
				END	
				,ce.ConventionNO
				,ce.vcTransID
				,sf.dtCESPSendFile
				,NULL 
				,CASE
					WHEN ce.tiCESP400TypeID = 24 THEN 0
					ELSE ce.fCLB		
				 END
				,NULL
				,ce8.siCESP800ErrorID
				,ce8Err.vcCESP800Error
				,CASE	WHEN	ceRev.iReversedCESP400ID IS NOT NULL THEN 1
						ELSE	0
				 END 
		FROM
			dbo.Un_Oper o
			INNER JOIN dbo.Un_CESP400 ce
				ON o.OperID = ce.OperID
			LEFT OUTER JOIN dbo.Un_CESP400 ceRev
				ON ce.iCESP400ID = ceRev.iReversedCESP400ID
			LEFT OUTER JOIN dbo.Un_CESPSendFile sf
				ON ce.iCESPSendFileID = sf.iCESPSendFileID
			INNER JOIN dbo.Un_Convention co
				ON co.ConventionID = ce.ConventionID
			LEFT OUTER JOIN dbo.Un_CESP800 ce8
				ON ce.iCESP800ID = ce8.iCESP800ID
			LEFT OUTER JOIN dbo.Un_CESP800Error ce8Err
				ON ce8.siCESP800ErrorID = ce8Err.siCESP800ErrorID
		WHERE
			ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
			AND
			--co.BeneficiaryID	= @iIDBeneficiaire
			--AND
			(ce.tiCESP400TypeId	= 24
			OR
			(ce.tiCESP400TypeId IN (13,19,21,23) AND ce.fCLB <>0))
			AND 
			ce.iREVERSEDCESP400ID IS NOT NULL 
		ORDER BY 
			1 DESC, 2 DESC, 3 DESC
			
		RETURN
	END
