/****************************************************************************************************
Code de service		:		fntPCEE_ObtenirTransactionBECEnAttente
Nom du service		:		1.1.1 Obtenir la liste des transactions BEC en attente
But					:		Obtenir la liste complète des transactions BEC n'ayant pas été envoyéees au PCEE
Description			:		Ce service est utilisé afin d'obtenir la liste complète des transactions qui sont pas
							encore envoyées au PCEE et qui ont été effectuées via l'outil de gestion du BEC. Les
							différents types de transactions sont 'Demande de BEC', 'Remboursement du BEC',
							'Transfert de solde entre convention' et 'Désactivation du BEC'
							
Facette				:		PCEE
Reférence			:		Document fntPCEE_ObtenirTransactionBECEnAttente.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						iID_Beneficiaire			Identifiant unique du bénéficiaire			Oui

Exemples d'appel:
				SELECT * FROM [dbo].[fntPCEE_ObtenirTransactionBECEnAttente](446695)
				SELECT * FROM [dbo].[fntPCEE_ObtenirTransactionBECEnAttente](547697)
				
Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						@tConvEnAttenteBEC			dtTransaction (Un_CESP400)					Date de l'opération
													vcAction									Description de l'action de la transaction en attente
													ConventionNO (Un_CESP400)					Numéro de la convention
													fCLB		 (Un_CESP400)					Montant du remboursement ou montant du transfert de solde
													iCESP400ID									Identifiant unique de la transaction

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-19					Jean-François Gauthier					Création de la fonction
						2009-10-29					Jean-François Gauthier					Ajout du champ iCESP400ID
						2009-10-30					Jean-François Gauthier					Ajout de iReversedCESP400ID <> NULL pour le cas "Demande de BEC"
						2009-12-15					Jean-François Gauthier					Élimination de la condition ce.iReversedCESP400ID <> NULL
						2010-02-02					Pierre Paquet							Affichage des 2 conventions si c'est un 'Transfert de convention'.
						2010-02-05					Pierre Paquet							Problème d'affichage de la transaction 'TRansfert'.
						2010-02-12					Pierre Paquet							Recherche des transactions BEC reliées via ConventionID. 
																							Permettre de voir les transactions en attente du bénéficiaire cédant.
						2010-02-16					Pierre Paquet							Utilisation de l'historique du NAS dans le cas d'un changement de NAS.
						2010-04-20					Pierre Paquet							Ajustement afin d'afficher les transactions de transfert à zéro.
						2010-04-22					Pierre Paquet							Rollback de 2010-04-20 : Ne pas afficher les trx de transfert si le solde est à zéro.
						2010-05-04					Pierre Paquet							Ne pas afficher les transactions de renversement.
						2010-05-10					Pierre Paquet							Correction sur l'affichage unique des trx du bénéficiaire.
						2010-08-16					Pierre Paquet							Correction: ne pas afficher les trx si le NAS est utilisé par un autre bénéficiaire actif.

N.B. OPTIMISATION NÉCESSAIRE

CREATE NONCLUSTERED INDEX [_dta_index_Un_CESP400_5_1672549192__K15_K8_K34_K20_K1_K11_K13_K2] ON [dbo].[Un_CESP400] 
(
	[vcBeneficiarySIN] ASC,
	[tiCESP400TypeID] ASC,
	[fCLB] ASC,
	[fCESG] ASC,
	[iCESP400ID] ASC,
	[dtTransaction] ASC,
	[ConventionNo] ASC,
	[iCESPSendFileID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF)
go

CREATE STATISTICS [_dta_stat_1672549192_2_1_15] ON [dbo].[Un_CESP400]([iCESPSendFileID], [iCESP400ID], [vcBeneficiarySIN])
go

CREATE STATISTICS [_dta_stat_1672549192_1_15_8] ON [dbo].[Un_CESP400]([iCESP400ID], [vcBeneficiarySIN], [tiCESP400TypeID])
go

CREATE STATISTICS [_dta_stat_1672549192_34_1_15] ON [dbo].[Un_CESP400]([fCLB], [iCESP400ID], [vcBeneficiarySIN])
go

CREATE STATISTICS [_dta_stat_1672549192_17_2_1_15] ON [dbo].[Un_CESP400]([bCESPDemand], [iCESPSendFileID], [iCESP400ID], [vcBeneficiarySIN])
go

CREATE STATISTICS [_dta_stat_1672549192_11_15_8_17] ON [dbo].[Un_CESP400]([dtTransaction], [vcBeneficiarySIN], [tiCESP400TypeID], [bCESPDemand])
go

CREATE STATISTICS [_dta_stat_1672549192_1_8_15_34] ON [dbo].[Un_CESP400]([iCESP400ID], [tiCESP400TypeID], [vcBeneficiarySIN], [fCLB])
go

CREATE STATISTICS [_dta_stat_1672549192_11_13_1_15_8] ON [dbo].[Un_CESP400]([dtTransaction], [ConventionNo], [iCESP400ID], [vcBeneficiarySIN], [tiCESP400TypeID])
go

CREATE STATISTICS [_dta_stat_1672549192_34_15_8_20_1] ON [dbo].[Un_CESP400]([fCLB], [vcBeneficiarySIN], [tiCESP400TypeID], [fCESG], [iCESP400ID])
go

CREATE STATISTICS [_dta_stat_1672549192_20_2_1_15_8_17] ON [dbo].[Un_CESP400]([fCESG], [iCESPSendFileID], [iCESP400ID], [vcBeneficiarySIN], [tiCESP400TypeID], [bCESPDemand])
go

CREATE STATISTICS [_dta_stat_1672549192_2_15_8_17_34_20] ON [dbo].[Un_CESP400]([iCESPSendFileID], [vcBeneficiarySIN], [tiCESP400TypeID], [bCESPDemand], [fCLB], [fCESG])
go

CREATE STATISTICS [_dta_stat_1672549192_11_13_34_1_15_8] ON [dbo].[Un_CESP400]([dtTransaction], [ConventionNo], [fCLB], [iCESP400ID], [vcBeneficiarySIN], [tiCESP400TypeID])
go

CREATE STATISTICS [_dta_stat_1672549192_8_1_2_15_17_34] ON [dbo].[Un_CESP400]([tiCESP400TypeID], [iCESP400ID], [iCESPSendFileID], [vcBeneficiarySIN], [bCESPDemand], [fCLB])
go

CREATE STATISTICS [_dta_stat_1672549192_15_8_17_1_11_2_34] ON [dbo].[Un_CESP400]([vcBeneficiarySIN], [tiCESP400TypeID], [bCESPDemand], [iCESP400ID], [dtTransaction], [iCESPSendFileID], [fCLB])
go

CREATE STATISTICS [_dta_stat_1672549192_11_34_15_8_20_1_2] ON [dbo].[Un_CESP400]([dtTransaction], [fCLB], [vcBeneficiarySIN], [tiCESP400TypeID], [fCESG], [iCESP400ID], [iCESPSendFileID])
go

CREATE STATISTICS [_dta_stat_1672549192_11_13_34_1_2_15_8_20] ON [dbo].[Un_CESP400]([dtTransaction], [ConventionNo], [fCLB], [iCESP400ID], [iCESPSendFileID], [vcBeneficiarySIN], [tiCESP400TypeID], [fCESG])
go

CREATE STATISTICS [_dta_stat_1672549192_34_15_20_1_2_8_17_11] ON [dbo].[Un_CESP400]([fCLB], [vcBeneficiarySIN], [fCESG], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [bCESPDemand], [dtTransaction])
go

CREATE STATISTICS [_dta_stat_1672549192_15_8_17_1_11_13_2_34_20] ON [dbo].[Un_CESP400]([vcBeneficiarySIN], [tiCESP400TypeID], [bCESPDemand], [iCESP400ID], [dtTransaction], [ConventionNo], [iCESPSendFileID], [fCLB], [fCESG])
go

 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntPCEE_ObtenirTransactionBECEnAttente]
		(
		@iID_Beneficiaire	INT
		)
RETURNS @tConvEnAttenteBEC TABLE
			(
			dtTransaction	DATETIME
			,vcAction		VARCHAR(75)
			,ConventionNO	VARCHAR(75)
			,fCLB			MONEY
			,iCESP400ID		INT
			)
AS
	BEGIN

		-- 0. Récupération des NAS du bénéficiaire
		DECLARE @NASBeneficiaire TABLE (vcNAS VARCHAR(75))

		INSERT INTO @NASBeneficiaire
		(vcNAS)
		 SELECT HSN.SocialNumber
			FROM UN_HumanSocialNumber HSN
			WHERE HumanID = @iID_Beneficiaire

		-- On exclus les NAS présentement utilisé par un autre bénéficiaire. 2010-08-16
	    DELETE FROM @NASBeneficiaire
			WHERE vcNAS IN (SELECT SocialNumber FROM dbo.Mo_Human WHERE HumanID <> @iID_Beneficiaire)

		-- 1. Afficher l'ensemble des transactions reliées au BEC du bénéficiaire qui n'ont pas encore été envoyées au PCEE	
		INSERT INTO @tConvEnAttenteBEC
		(
			dtTransaction
			,vcAction	
			,ConventionNO
			,fCLB
			,iCESP400ID
		)
		SELECT 
				x.dtTransaction
				,x.vcAction
				,x.ConventionNO
				,x.fCLB
				,x.iCESP400ID
		FROM
			(
			SELECT											-- Demandes de BEC non envoyées
				ce.dtTransaction
				,vcAction = 'Demande de BEC'
				,ce.ConventionNO
				,fCLB = 0
				,ce.iCESP400ID
			FROM
				dbo.Un_CESP400 ce
			WHERE
			--	(ce.vcBeneficiarySIN = @vcNAS OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
			--(ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
				ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
				AND
				ce.iCESPSendFileID	IS NULL
				AND
				ce.tiCESP400TypeID	= 24	
				AND
				ce.bCESPDemand		= 1
				AND 
				ce.iReversedCESP400ID IS NULL -- 2010-05-04 

			UNION 										-- Désactivations de BEC non envoyées
			SELECT
				ce.dtTransaction
				,vcAction = 'Désactivation de BEC'
				,ce.ConventionNO
				,fCLB = 0
				,ce.iCESP400ID
			FROM			
				dbo.Un_CESP400 ce
			WHERE
		--		(ce.vcBeneficiarySIN = @vcNAS OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
		--		(ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
				ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
				AND
				ce.iCESPSendFileID	IS NULL
				AND
				ce.tiCESP400TypeID	= 24	
				AND
				ce.bCESPDemand		= 0
				AND
				ce.iReversedCESP400ID IS NULL -- 2010-05-04 

			UNION 										-- Remboursement de BEC non envoyées
			SELECT
				ce.dtTransaction
				,vcAction = 'Remboursement au PCEE'
				,ce.ConventionNO
				,ce.fCLB
				,ce.iCESP400ID
			FROM			
				dbo.Un_CESP400 ce
			WHERE
			--	(ce.vcBeneficiarySIN = @vcNAS OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
			--	(ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
				ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
				AND
				ce.iCESPSendFileID	IS NULL
				AND
				ce.tiCESP400TypeID	= 21
				AND
				ce.fCLB				<> 0
				AND 
				ce.fCESG			= 0	
				AND
				ce.iReversedCESP400ID IS NULL -- 2010-05-04 
			UNION 										-- Transferts de solde
			SELECT
				ce.dtTransaction
				,vcAction = 'Transfert de solde'
				,ce2.ConventionNO + ' --> ' + ce.ConventionNo
				,ce.fCLB
				,ce.iCESP400ID
			FROM			
				dbo.Un_CESP400 ce
				INNER JOIN	dbo.Un_CESP400 ce2
					ON ce.vcBeneficiarySIN = ce2.vcBeneficiarySIN
			WHERE
			--	(ce.vcBeneficiarySIN = @vcNAS OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
			--	(ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) OR ce.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention WHERE @iID_Beneficiaire = BeneficiaryID))
				ce.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire)
				AND
				ce.iCESPSendFileID	IS NULL
				AND
				ce.fCLB				<> 0
				AND 
				ce2.fCLB			<> 0
				AND 	
				ce.fCESG			= 0	
				AND
				ce2.fCESG			= 0
				AND
				ce.tiCESP400TypeID	= 19
				AND
				ce2.tiCESP400TypeID	= 23
				AND
				ce.iReversedCESP400ID IS NULL -- 2010-05-04 
			) AS X
		ORDER BY
			x.dtTransaction
			
		RETURN
	END


