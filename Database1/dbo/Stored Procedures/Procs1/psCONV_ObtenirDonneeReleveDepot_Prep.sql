/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:		psCONV_ObtenirDonneeReleveDepot_Prep
Nom du service		:		Obtenir toutes les données nécessaire pour l'impression du relevé de dépôt    
But					:		Preparer une table temporaire pour la sp psCONV_ObtenirDonneeReleveDepot_EXEC
							qui récupére toutes les données nécessaire pour l'impression du relevé de dépôt
Facette				:		P171U
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                                 Obligatoire
                        ----------                  ----------------                            --------------                       
						dtDateFin                   Date fin du relevé de dépôt                 Oui
                        iSubscriberID               Identifiant unique du souscripteur          Non

Exemple d'appel:
		DECLARE @i INT
		EXECUTE @i = dbo.psCONV_ObtenirDonneeReleveDepot_Prep	'2009-06-30', 387661
		SELECT @i
																
Parametres de sortie :  Table						Champs									Description
					    -----------------			---------------------------				--------------------------
						N/A							---										-1 : une erreur est survenue
																							1  : traitement sans erreur
																							
Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-03-13					Dan Trifan								Diviser le traitement en 2 parties : _Prep et _EXEC
																							pour implanter le traitement en plusieurs soustraitements parallèles
						2009-03-27					D.T.									filtre date entrée en vigeur <= date relevé
						2009-05-11					Jean-François Gauthier					Modification pour générer le nombre de souscripteurs désirés (pour DEBUG)
						2009-05-14					Jean-François Gauthier					Correction pour le nombre de souscripteur (DEBUG) si l'appel provient de START_SSIS
						2009-06-22					Jean-François Gauthier					Formatage et ajout du paramètre @bSemestriel
						2009-06-25					Jean-François Gauthier					Ajout de l'initialisation à NULL de @bSemestriel s'il est passé à zéro 
						2009-07-09					Jean-François Gauthier					Ajout du champ bSouscripteur_Desire_Releve_Elect
						2009-07-14					Jean-François Gauthier					Élimination du paramètre @bSemestriel dans l'appel de la procédure. 
																							Le critère de sélection des relevés semestriels
																							@iSubscriber = 0 et @dtDateFin = 2009-06-30				
						2009-07-15					Jean-François Gauthier					Ajout de la suppression des Souscripteurs qui ont une adresse courriel invalide dans les
																							cas de génération des relevés semestriels
						2009-07-16					Jean-François Gauthier					Élimination de @iSubscriberID = 0 pour les semestriels (seule la date du 06-30) agit comme critère maintenant
						2009-10-06					Jean-François Gauthier					Ajout de la suppression dans la table dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite
						2009-11-02					Jean-François Gauthier					Ajout d'une validation pour le relevé de dépôt semestriel
						2010-01-07					Jean-François Gauthier					Modification pour le traitement semestriel avec le champ bSouscripteur_Desire_Releve_Elect
																							qui lorsqu'à 0 signifie qu'on ne doit pas transmettre le relevé par courriel. 
						2010-05-05					Jean-François Gauthier					Ajout de la gestion des erreurs, mais sans transaction afin de ne pas créer de "lock"
																							sur les données, car la génération des relevés de dépôt est longue
																							Ajout d'une valeur de retour (-1 : erreur, 1 : sans erreur)
						2012-02-08					Mbaye Diakhate							Modification pour générer les adresses perdues
						2012-03-26                  Mbaye Diakhate 							Gérer les exclus
						2013-01-25					Pierre-Luc Simard						Permettre de reprendre la génération des données où nous étions rendu si le traitement a planté.
																							(Les tables tblCONV_DonneeReleveDepot_Lots et tblCONV_DonneeReleveDepotAvecDetailParUnite_Lots doivent être vidées
																							manuellement. Après toutes les générations, leurs données doivent être transférées dans les tables d'origine
																							pour la génération des PDF.) 
						2013-02-07					Pierre-Luc Simard						Validation du consentement pour ceux du Portail au lieu du champ bSouscripteur_Desire_Releve_Elect
						2014-09-04					Donald Huppé							Modification de l'appel de fnGENE_EvaluerRegEx
						2015-07-29					Steve Picard							Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

N.B.
	LA MODIFICATION DES PARAMÈTRES D'APPEL DE CETTE PROCÉDURE ENTRAÎNE AUTOMATIQUEMENT
	UNE MODIFICATION DE L'APPEL DU PACKAGE SSIS DANS _STARTSSIS AINSI QUE DU PACKAGE 
	EN LUI MÊME
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirDonneeReleveDepot_Prep]
@dtDateFin datetime, @iSubscriberID int
WITH EXEC AS CALLER
AS
BEGIN
	SELECT 1/0
    /*    
    SET NOCOUNT ON
	BEGIN TRY
		DECLARE 
			@bSemestriel INT,
			@iLot INT
		IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tblCONV_TMPRelDep]') AND type in (N'U'))
			BEGIN
				CREATE TABLE dbo.tblCONV_TMPRelDep(
					iID									INT IDENTITY,
					ConventionID							INT,
					SubscriberID							INT,
					BeneficiaryID						INT,
					ConventionNo							VARCHAR(20),
					PlanDesc								VARCHAR(75),
					PlantypeID							CHAR(3),
					TextDiploma							VARCHAR(150),
					Processed							BIT,
					dtDtHr								DATETIME,
					bSouscripteur_Desire_Releve_Elect	BIT	
					CONSTRAINT [PK_tblCONV_TMPRelDep] PRIMARY KEY CLUSTERED 
						(iID ASC)			   
					)
				CREATE INDEX ixtblCONV_TMPRelDep ON tblCONV_TMPRelDep (Processed)
			END

		TRUNCATE TABLE tblCONV_TMPRelDep

		IF (MONTH(@dtDateFin)=6 AND DAY(@dtDateFin)=30)	-- GÉNÉRATION DES RELEVÉS SEMESTRIELS
			AND (@iSubscriberID IS NULL OR @iSubscriberID = -1)
			BEGIN
				SET @bSemestriel = 1
			END
		ELSE											-- GÉNÉRATION DE TOUS LES RELEVÉS
			BEGIN
				SET @bSemestriel = NULL
			END

		SELECT @dtDateFin  = isnull(@dtDateFin,getdate()) 
		
		IF @iSubscriberID = -1
			BEGIN
				SELECT @iSubscriberID =  null
			END

		IF @iSubscriberID IS NULL OR @iSubscriberID = -1
			BEGIN
				-- Récupérer le dernier numéro de lot généré				
				SELECT @ilot = ISNULL(MAX(iLot),0) + 1
				FROM tblCONV_DonneeReleveDepot_Lots
				
				-- Copier le contenu des tables dans des tables temporaire pour conserver les données de tous les lots générés
				INSERT INTO tblCONV_DonneeReleveDepot_Lots 
				SELECT	
					tblCONV_DonneeReleveDepot.*, 
					@ilot, 
					GETDATE() 
				FROM tblCONV_DonneeReleveDepot
				WHERE iIDSouscripteur NOT IN (
					SELECT DISTINCT 
						iIDSouscripteur
					FROM tblCONV_DonneeReleveDepot_Lots)
					
				INSERT INTO tblCONV_DonneeReleveDepotAvecDetailParUnite_Lots 
				SELECT	
					tblCONV_DonneeReleveDepotAvecDetailParUnite.*, 
					@ilot, 
					GETDATE() 
				FROM tblCONV_DonneeReleveDepotAvecDetailParUnite
				WHERE iIDSouscripteur NOT IN (
					SELECT DISTINCT 
						iIDSouscripteur
					FROM tblCONV_DonneeReleveDepotAvecDetailParUnite_Lots)	
										
				-- On vide la table tblCONV_DonneeReleveDepot pour les nouveaux enregistrements
				TRUNCATE TABLE dbo.tblCONV_DonneeReleveDepot
				TRUNCATE TABLE dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite
			END
		ELSE
			BEGIN
				-- On régénere seulement le souscripteur demandé
				DELETE FROM dbo.tblCONV_DonneeReleveDepot WHERE iIDSouscripteur = @iSubscriberID
				DELETE FROM dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite  WHERE iIDSouscripteur = @iSubscriberID
			END

		INSERT INTO dbo.tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
		SELECT GETDATE(),'CONV','Calcul relevé de depôt', '-------------- Start ObtenirDonneeReleveDepot_Prep: -------------------------' 

		-- RECHERCHE DU PARAMÈTRE DU NOMBRE DE SOUSCRIPTEUR
		DECLARE @iNbPsPrep	INTEGER	
		
		SELECT TOP 1 @iNbPsPrep = iNbPsPrep FROM dbo.tblCONV_NbPsPrep
		--set @iNbPsPrep =57069 --POUR TESTER UN PETIT BATCH 1/2=57069 
		-- 
		IF @iNbPsPrep IS NULL	-- L'APPEL PROVIENT DE START_SSIS ET IL FAUT INITIALISER LA VALEUR
			BEGIN
				SET @iNbPsPrep = -1
			END

		IF @iNbPsPrep = -1	-- ON GÉNÈRE TOUS LES ENREGISTREMENTS
			BEGIN
			
				INSERT INTO dbo.tblCONV_TMPRelDep(	
					ConventionID ,
					SubscriberID ,
					BeneficiaryID, 
					ConventionNo,
					PlanDesc ,
					PlantypeID ,
					TextDiploma ,
					Processed,
					bSouscripteur_Desire_Releve_Elect	)		
				SELECT DISTINCT 
				--SELECT DISTINCT TOP 21324 -- LE QUART A GÉNÉRER
					V.ConventionID,
					V.SubscriberID ,
					V.BeneficiaryID ,
					V.ConventionNo,
					V.PlanDesc,
					V.PlantypeID,
					V.TextDiploma,
					0 as Processed,
					V.bSouscripteur_Desire_Releve_Elect
				FROM ( -- Retourne le plus grand ID pour la plus grande date de début d'un état par convention
					SELECT 
						T.ConventionID,
						ConventionConventionStateID = MAX(CCS.ConventionConventionStateID),
						T.SubscriberID ,
						T.BeneficiaryID ,
						T.ConventionNo,
						T.PlanDesc,
						T.PlantypeID,
						T.TextDiploma,
						T.bSouscripteur_Desire_Releve_Elect
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							 S.ConventionID,
							 MaxDate = MAX(S.StartDate),
							 SubscriberID = C.SubscriberID,
							 BeneficiaryID = C.BeneficiaryID,
							 ConventionNo = C.ConventionNo,
							 PlanDesc = P.PlanDesc,
							 TextDiploma = C.TexteDiplome,  -- D.DiplomaText,		-- 2015-07-29
							 PlantypeID = P.PlanTypeID,
							 bSouscripteur_Desire_Releve_Elect = CASE WHEN ISNULL(SP.iUserId,0) > 0 AND SB.bConsentement = 1 THEN 1 ELSE 0 END
						FROM dbo.Un_ConventionConventionState S
						INNER JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						INNER JOIN	dbo.Un_Subscriber SB ON C.SubscriberID = SB.SubscriberID
						LEFT JOIN tblGENE_PortailAuthentification SP ON SP.iUserId = SB.SubscriberID
						--LEFT OUTER JOIN dbo.Un_diplomatext D ON D.DiplomaTextID = C.DiplomaTextID		-- 2015-07-29
						INNER JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
						INNER JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
						WHERE S.StartDate <= @dtDateFin	-- État à la date de fin de la période
							AND C.SubscriberID = ISNULL(@iSubscriberID, C.SubscriberID)
							AND U.TerminatedDate IS NULL		-- Pas de date de RI 
							AND U.IntReimbDate IS NULL		-- Pas de date de résiliation  
							AND U.InForceDate <= @dtDateFin
							AND SB.SemiAnnualStatement = ISNULL(@bSemestriel, SB.SemiAnnualStatement)
							--AND C.ConventionNo IN (SELECT DISTINCT ConventionNo from tblCONV_TMPRelDep_ConvTest)
						GROUP BY 
							S.ConventionID,
							C.SubscriberID,
							C.BeneficiaryID,
							C.ConventionNo,
							P.PlanDesc,
							P.PlantypeID,
							C.TexteDiplome,	-- D.DiplomaText,		-- 2015-07-29
							CASE WHEN ISNULL(SP.iUserId,0) > 0 AND SB.bConsentement = 1 THEN 1 ELSE 0 END
						) T
					INNER JOIN dbo.Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					GROUP BY
						T.ConventionID,
						T.SubscriberID,
						T.BeneficiaryID,
						T.ConventionNo,
						T.PlanDesc,
						T.PlantypeID,
						T.TextDiploma, 
						T.bSouscripteur_Desire_Releve_Elect
					) V
				INNER JOIN dbo.Un_ConventionConventionState CCS ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
				INNER JOIN dbo.Un_Subscriber S ON V.SubscriberID = S.SubscriberID
				LEFT JOIN tblCONV_DonneeReleveDepot_Lots RDL ON RDL.iIDSouscripteur = S.SubscriberID
				--08022012 Mbaye diakhate: Modification pour générer les adresses perdues
				--WHERE (S.AddressLost = 0 OR @iSubscriberID IS NOT NULL)
				WHERE CCS.ConventionStateID = 'REE' -- L'état REEE  
					AND	(V.SubscriberID = @iSubscriberID 
						AND @iSubscriberID IS NOT NULL
							OR @iSubscriberID IS NULL)
					-- MBD 20120326: GERER LES EXCLUS	-----@@@@@@
					AND V.SubscriberID NOT IN (SELECT DISTINCT SubscriberId FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId =  V.SubscriberID AND te.ConventionId = V.ConventionID )
					AND V.ConventionID NOT IN (SELECT DISTINCT ConventionId FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId = V.SubscriberID AND te.ConventionId = V.ConventionID )
					-- Ne pas générer ceux qui ont déjà des données, lorsque le traitement précédant a planté
					-- AND V.SubscriberID NOT IN (SELECT DISTINCT iIDSouscripteur FROM tblCONV_DonneeReleveDepot_Lots)
					AND (RDL.iIDSouscripteur IS NULL OR @iSubscriberID IS NOT NULL) -- On génère les données uniquement pour un seul souscripteur ou pour tous, s'ils ne sont pas déjà dans les tables de lots
				--	AND V.SubscriberID =  484814  --  NOT IN (SELECT SubscriberId   FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId =  V.SubscriberID AND te.ConventionId = V.ConventionID )
				--	AND V.ConventionID =287340 -- NOT IN (SELECT ConventionId   FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId = V.SubscriberID AND te.ConventionId = V.ConventionID )
				ORDER BY V.SubscriberID	
			END
		ELSE			-- ON GÉNÈRE SEULEMENT LE NOMBRE DEMANDÉ
			BEGIN
				INSERT INTO dbo.tblCONV_TMPRelDep (
					ConventionID ,
					SubscriberID ,
					BeneficiaryID, 
					ConventionNo,
					PlanDesc ,
					PlantypeID ,
					TextDiploma ,
					Processed,
					bSouscripteur_Desire_Releve_Elect)		
				SELECT DISTINCT TOP (@iNbPsPrep)
					V.ConventionID,
					V.SubscriberID ,
					V.BeneficiaryID ,
					V.ConventionNo,
					V.PlanDesc,
					V.PlantypeID,
					V.TextDiploma,
					0 AS Processed,
					V.bSouscripteur_Desire_Releve_Elect
				FROM ( -- Retourne le plus grand ID pour la plus grande date de début d'un état par convention
					SELECT 
						T.ConventionID,
						ConventionConventionStateID = MAX(CCS.ConventionConventionStateID),
						T.SubscriberID ,
						T.BeneficiaryID ,
						T.ConventionNo,
						T.PlanDesc,
						T.PlantypeID,
						T.TextDiploma,
						T.bSouscripteur_Desire_Releve_Elect
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							S.ConventionID,
							MaxDate = MAX(S.StartDate),
							SubscriberID = C.SubscriberID,
							BeneficiaryID = C.BeneficiaryID,
							ConventionNo = C.ConventionNo,
							PlanDesc = P.PlanDesc,
							TextDiploma = C.TexteDiplome,	-- D.DiplomaText,	-- 2015-07-09
							PlantypeID = P.PlanTypeID,
							bSouscripteur_Desire_Releve_Elect = CASE WHEN ISNULL(SP.iUserId,0) > 0 AND SB.bConsentement = 1 THEN 1 ELSE 0 END
						FROM dbo.Un_ConventionConventionState S
						INNER JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						INNER JOIN	dbo.Un_Subscriber SB ON C.SubscriberID = SB.SubscriberID
						LEFT JOIN tblGENE_PortailAuthentification SP ON SP.iUserId = SB.SubscriberID
						--LEFT OUTER JOIN dbo.Un_diplomatext D ON D.DiplomaTextID = C.DiplomaTextID		-- 2015-07-29
						INNER JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
						INNER JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
						WHERE S.StartDate <= @dtDateFin				-- État à la date de fin de la période
							AND C.SubscriberID = ISNULL(@iSubscriberID, C.SubscriberID)
							AND U.TerminatedDate IS NULL			-- Pas de date de RI 
							AND U.IntReimbDate IS NULL				-- Pas de date de résiliation  
							AND U.InForceDate <= @dtDateFin
							AND SB.SemiAnnualStatement = ISNULL(@bSemestriel, SB.SemiAnnualStatement)
						GROUP BY 
							S.ConventionID,
							C.SubscriberID,
							C.BeneficiaryID,
							C.ConventionNo,
							P.PlanDesc,
							P.PlantypeID,
							C.TexteDiplome,	-- D.DiplomaText,	-- 2015-07-09
							CASE WHEN ISNULL(SP.iUserId,0) > 0 AND SB.bConsentement = 1 THEN 1 ELSE 0 END
						) T
						INNER JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					GROUP BY 
						T.ConventionID,
						T.SubscriberID,
						T.BeneficiaryID,
						T.ConventionNo,
						T.PlanDesc,
						T.PlantypeID,
						T.TextDiploma, 
						T.bSouscripteur_Desire_Releve_Elect
					) V
				INNER JOIN Un_ConventionConventionState CCS ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
				INNER JOIN dbo.Un_Subscriber S ON V.SubscriberID = S.SubscriberID
				--08022012 Mbaye diakhate: Modification pour générer les adresses perdues
				--WHERE -- (S.AddressLost = 0 OR @iSubscriberID IS NOT NULL)
				WHERE CCS.ConventionStateID = 'REE' -- L'état REEE  
					AND	(V.SubscriberID = @iSubscriberID AND @iSubscriberID IS NOT NULL	OR @iSubscriberID IS NULL)	
				ORDER BY V.SubscriberID	
			END

		IF @bSemestriel = 1		-- RELEVÉ SEMESTRIEL, ON DOIT CONSERVER UNIQUEMENT LES ENREGISTREMENTS POUR LESQUELS LE COURRIEL EST VALIDE
			BEGIN		
				DELETE FROM dbo.tblCONV_TMPRelDep	-- SUPPRESSION DES ADRESSES COURRIELS INVALIDES
				WHERE SubscriberID IN (
					SELECT DISTINCT 
						h.HumanID
					FROM dbo.tblCONV_TMPRelDep tmp
					INNER JOIN dbo.Mo_Human h ON tmp.SubscriberID = h.HumanID
					INNER JOIN dbo.Mo_Adr a ON h.AdrID = a.AdrID
					WHERE a.Email IS NULL
						OR
						(dbo.fnGENE_EvaluerRegEx('^[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$',LOWER(a.EMail),0) = 0
						OR (a.EMail LIKE '%/%'
							OR a.EMail LIKE '%\\%'
							OR a.EMail LIKE '%www%'
							OR a.EMail LIKE '%http%'
							)
						)
					)
					OR ISNULL(bSouscripteur_Desire_Releve_Elect,0) = 0
			END

		INSERT INTO tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
		SELECT GETDATE(),'CONV','Calcul relevé de depôt', '-------------- Fin ObtenirDonneeReleveDepot_Prep: -------------------------' 
		
		RETURN 1
		
	END TRY
	BEGIN CATCH
		DECLARE		 
			@iErrSeverite	INT
			,@iErrStatut	INT
			,@vcErrMsg		NVARCHAR(1024)
			
		SELECT
			@vcErrMsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
			,@iErrStatut	= ERROR_STATE()
			,@iErrSeverite	= ERROR_SEVERITY()

		RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
		RETURN -1
	END CATCH
    */
END