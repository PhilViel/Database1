/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 					:	IU_UN_CancelCotisationCESP400 
Description 		:	Annule l’envoi au PCEE de cotisation 
Valeurs de retour	:	@ReturnValue :
								> 0 : Réussite
								<= 0 : Échec.
Note					:	
	ADX0001362	IA	2007-04-26	Bruno Lapointe			Création
	ADX0001260	UP	2007-10-26	Bruno Lapointe			Éliminer les doublons des blobs en paramètres	
					2009-11-20	Jean-François Gauthier	Validation des changements de bénéficiaires
					2010-03-03	Jean-François Gauthier	Vérifier si les transactions du BLOB à traiter ont été créées sous le bénéficiaire actuel
														Ajout du paramètre optionnel "iIDConnect" afin de retrouver le "UserID" et les droits associés
					2010-04-07	Pierre Paquet			Ajustement de la stored proc suite aux tests.
					2010-04-29	Jean-François Gauthier	Ajout du paramètre optionnel @bSansVerificationPCEE400 
					2010-04-30	Jean-François Gauthier	Modification du OR pour un AND dans la vérification de  @bSansVerificationPCEE400 
					2011-01-31	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+
                    2017-05-18  Pierre-Luc Simard       Ajout de la validation des sommes reçues pour ne pas annuler une opération sans subvention
                                                        (Ex: Cas de réévaluation du PCEE)
					2017-08-15	Donald Huppé			Ajustement de la modif précédente (2017-05-18) : Le solde doit être <> 0 ou lieu de > 0
*************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CancelCotisationCESP400] 
	(
		@iCotisationBlobID	INT,	-- ID du blob qui contient les CotisationID des cotisations dont il faut annuler l’envoi au PCEE. 0 = aucun
		@iOperBlobID		INT,	-- ID du blob qui contient les OperID des opérations dont il faut annuler l’envoi au PCEE. On doit y retrouver seulement les lignes pour lesquelles nous n’Avons pas de CotisationID (nulle) par exemple les PAE et les AVC. 0 = aucun
		@bInTransaction		BIT,	-- Indique si la procédure est appelée dans une transaction
		@iIDConnect			INT		= NULL,
		@bSansVerificationPCEE400 BIT = NULL
	) 
AS
BEGIN
	DECLARE 
		@iResult		INT
		,@iCESP400ID	INT
		,@iCompteEnrg	INT

	SET @iResult = 1

	DECLARE @tCotToCancel TABLE (
		CotisationID INT PRIMARY KEY )

	DECLARE @tOperToCancel TABLE (
		OperID INT PRIMARY KEY )

	IF @iCotisationBlobID > 0
		INSERT INTO @tCotToCancel
			SELECT DISTINCT iVal 
			FROM dbo.FN_CRI_BlobToIntegerTable(@iCotisationBlobID)

	IF @iOperBlobID > 0
		INSERT INTO @tOperToCancel
			SELECT DISTINCT iVal 
			FROM dbo.FN_CRI_BlobToIntegerTable(@iOperBlobID)

/* Pierre Paquet 2010-04-07 (On ne supprime pas toutes les transactions systématiquement, valider le droit PCEE_400_AUTRE_BENEF)
	-- 2009-11-20 : Validation des changements potentiels de bénéficiaire
	--				Il faut s'assurer que toutes les transactions dans le BLOB appartiennent aux bénéficiaires actuels,
	--				sinon, il faut les supprimer du BLOB

	-- Vérification pour les cotisations 
	SET ROWCOUNT 0
	DELETE FROM @tCotToCancel
	WHERE
		CotisationID IN	(				
						SELECT
							ce4.CotisationID
						FROM
							@tCotToCancel t		-- CotisationID
							INNER JOIN dbo.Un_CESP400 ce4
								ON t.CotisationID = ce4.CotisationID
							INNER JOIN dbo.Un_Convention c
								ON ce4.ConventionID = c.ConventionID
							INNER JOIN 
									(
									SELECT 
										ch2.iID_Convention, ch2.iID_Changement_Beneficiaire, ch2.dtDate_Changement_Beneficiaire
									FROM
										dbo.tblCONV_ChangementsBeneficiaire ch2
										INNER JOIN
											(
											SELECT
												tmp.iID_Convention, 
												dtDate_Changement_Beneficiaire = MAX(tmp.dtDate_Changement_Beneficiaire)
											FROM
												dbo.tblCONV_ChangementsBeneficiaire tmp
											GROUP BY 
												tmp.iID_Convention
											) ch1
												ON ch2.iID_Convention = ch1.iID_Convention AND ch2.dtDate_Changement_Beneficiaire = ch1.dtDate_Changement_Beneficiaire
									) cb
										ON cb.iID_Convention = c.ConventionID
						WHERE
							cb.iID_Changement_Beneficiaire <> c.BeneficiaryID
							AND
							ce4.dtTransaction				<  cb.dtDate_Changement_Beneficiaire
						)
	SET @iCompteEnrg = @@ROWCOUNT

	SET ROWCOUNT 0
	DELETE FROM @tOperToCancel
	WHERE
		OperID	IN (
					SELECT
						ce4.OperID
					FROM
						@tOperToCancel t					-- OperID
						INNER JOIN dbo.Un_CESP400 ce4
							ON t.OperID = ce4.OperID
						INNER JOIN dbo.Un_Convention c
							ON ce4.ConventionID = c.ConventionID
						INNER JOIN 
								(
								SELECT 
									ch2.iID_Convention, ch2.iID_Changement_Beneficiaire, ch2.dtDate_Changement_Beneficiaire
								FROM
									dbo.tblCONV_ChangementsBeneficiaire ch2
									INNER JOIN
										(
										SELECT
											tmp.iID_Convention, 
											dtDate_Changement_Beneficiaire = MAX(tmp.dtDate_Changement_Beneficiaire)
										FROM
											dbo.tblCONV_ChangementsBeneficiaire tmp
										GROUP BY 
											tmp.iID_Convention
										) ch1
											ON ch2.iID_Convention = ch1.iID_Convention AND ch2.dtDate_Changement_Beneficiaire = ch1.dtDate_Changement_Beneficiaire
								) cb
									ON cb.iID_Convention = c.ConventionID
					WHERE
						cb.iID_Changement_Beneficiaire <> c.BeneficiaryID
						AND
						ce4.dtTransaction				<  cb.dtDate_Changement_Beneficiaire
					)
	SET @iCompteEnrg = @iCompteEnrg + @@ROWCOUNT

*/

	-- 2010-03-03 : JFG : AJOUT
	-- Vérifier si l'utilisateur a le droit PCEE_400_AUTRE_BENEF
	-- Si le droit n'est pas présent, alors on doit supprimer toutes les transactions dont la date
	-- de la transaction est inférieure à la date changement de bénéficiaire.
	-- 2010-04-29 : Ajout de la vérification sur @bSansVerificationPCEE400
	IF 	(
		(NOT EXISTS(	SELECT
					1		-- Vérification du droit attribué à l'usager
				FROM
					dbo.Mo_Right r
					INNER JOIN dbo.Mo_UserRight ur
						ON r.RightID = ur.RightID
					INNER JOIN dbo.Mo_Connect c
						ON ur.UserID = c.UserID
				WHERE
					r.RightCode = 'PCEE_400_AUTRE_BENEF'
					AND
					c.ConnectID = ISNULL(@iIDConnect,-1))
		AND
		NOT EXISTS(	SELECT
					1		-- Vérification du droit attribué au groupe de l'usager
				FROM
					dbo.Mo_Right r
					INNER JOIN dbo.Mo_UserGroupRight ugr
						ON r.RightID = ugr.RightID
					INNER JOIN dbo.Mo_UserGroupDtl ugd
						ON ugd.UserGroupID = ugr.UserGroupID
					INNER JOIN dbo.Mo_Connect c
						ON ugd.UserID = c.UserID
				WHERE
					r.RightCode = 'PCEE_400_AUTRE_BENEF'
					AND
					c.ConnectID = ISNULL(@iIDConnect,-1)))
		AND
		ISNULL(@bSansVerificationPCEE400,0) <> 1		-- 2010-04-29 : JFG : Ajout de cette valiation
		)

		BEGIN		
			-- Suppression des cotisations
			SET ROWCOUNT 0
			DELETE FROM @tCotToCancel
			WHERE
				CotisationID IN
								(
									SELECT
										ce4.CotisationID
									FROM
										@tCotToCancel t		-- CotisationID
										INNER JOIN dbo.Un_CESP400 ce4
											ON t.CotisationID = ce4.CotisationID
										CROSS APPLY
										(
										SELECT 
											TOP 1 cb.dtDate_Changement_Beneficiaire  -- recherche de la date du dernier changement de bénéficiaire
										FROM
											dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, ce4.ConventionID, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) cb
										ORDER BY
											cb.dtDate_Changement_Beneficiaire DESC
										) f
									WHERE
										ce4.dtTransaction < f.dtDate_Changement_Beneficiaire
								)
				
			IF @@ROWCOUNT > 0	
				BEGIN
					SET @iCompteEnrg = @iCompteEnrg + @@ROWCOUNT
				END
			
			-- Suppression des opération
			SET ROWCOUNT 0
			DELETE FROM @tOperToCancel
			WHERE
				OperID	IN (
							SELECT
								ce4.OperID
							FROM
								@tOperToCancel t					-- OperID
								INNER JOIN dbo.Un_CESP400 ce4
									ON t.OperID = ce4.OperID
								CROSS APPLY
										(
										SELECT 
											TOP 1 cb.dtDate_Changement_Beneficiaire  -- recherche de la date du dernier changement de bénéficiaire
										FROM
											dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, ce4.ConventionID, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) cb
										ORDER BY
											cb.dtDate_Changement_Beneficiaire DESC
										) f
							WHERE
								ce4.dtTransaction < f.dtDate_Changement_Beneficiaire
							)
				
			IF @@ROWCOUNT > 0	
				BEGIN
					SET @iCompteEnrg = @iCompteEnrg + @@ROWCOUNT
				END
		END
				
	
	
	-- 	FIN AJOUT DU 2010-03-03


	-- 2009-11-20 : Retour du nombre de transactions non traitées (supprimées des tables temporaires)
	IF @iCompteEnrg > 0
		BEGIN
			SET @iResult = @iCompteEnrg
		END

	IF @bInTransaction = 0
		-----------------
		BEGIN TRANSACTION
		-----------------

	-- Supprime tous les 400 de la convention qui n'ont pas été envoyé et qui sont lié 
	-- aux cotisations dont on force le renvoi
	IF @iResult > 0 AND @iCotisationBlobID > 0
	BEGIN
		DELETE Un_CESP400
		WHERE iCESPSendFileID IS NULL
			AND CotisationID IN (SELECT CotisationID FROM @tCotToCancel)

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	-- Supprime tous les 400 de la convention qui n'ont pas été envoyé et qui sont lié 
	-- aux opérations dont on force le renvoi
	IF @iResult > 0 AND @iOperBlobID > 0
	BEGIN
		DELETE Un_CESP400
		WHERE iCESPSendFileID IS NULL
			AND OperID IN (SELECT OperID FROM @tOperToCancel)

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	SET @iCESP400ID = IDENT_CURRENT('Un_CESP400')

	-- Annulation des cotisations
	IF @iCotisationBlobID > 0 AND @iResult > 0
	BEGIN
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				iReversedCESP400ID,
				tiCESP400TypeID,
				tiCESP400WithdrawReasonID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				dtStudyStart,
				tiStudyYearWeek,
				fCESG,
				
				/* Modif Fred 2010-10-14 */
				fACESGPart,
				
				fEAPCESG,
				fEAP,
				fPSECotisation,
				iOtherPlanGovRegNumber,
				vcOtherConventionNo,
				tiProgramLength,
				cCollegeTypeID,
				vcCollegeCode,
				siProgramYear,
				vcPCGSINorEN,
				vcPCGFirstName,
				vcPCGLastName,
				tiPCGType,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				vcPGProv,
				fCotisationGranted )
			SELECT
				C4.OperID,
				C4.CotisationID,
				C4.ConventionID,
				C4.iCESP400ID,
				C4.tiCESP400TypeID,
				C4.tiCESP400WithdrawReasonID,
				'FIN',
				C4.dtTransaction,
				C4.iPlanGovRegNumber,
				C4.ConventionNo,
				C4.vcSubscriberSINorEN,
				C4.vcBeneficiarySIN,
				-C4.fCotisation,
				C4.bCESPDemand,
				C4.dtStudyStart,
				C4.tiStudyYearWeek,
				
				CASE
					WHEN C4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fCESG + C9.fACESG),0)
				ELSE -C4.fCESG
				END,
				CASE
					WHEN C4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fACESG),0)
				ELSE -C4.fACESGPart
				END,
				
				-C4.fEAPCESG,
				-C4.fEAP,
				-C4.fPSECotisation,
				C4.iOtherPlanGovRegNumber,
				C4.vcOtherConventionNo,
				C4.tiProgramLength,
				C4.cCollegeTypeID,
				C4.vcCollegeCode,
				C4.siProgramYear,
				C4.vcPCGSINorEN,
				C4.vcPCGFirstName,
				C4.vcPCGLastName,
				C4.tiPCGType,
				CASE 
					WHEN C4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fCLB),0)
				ELSE -C4.fCLB
				END,
				-C4.fEAPCLB,
				-C4.fPG,
				-C4.fEAPPG,
				C4.vcPGProv,
				-ISNULL(SUM(C9.fCotisationGranted),0)
			FROM @tCotToCancel Ct
			JOIN Un_CESP400 C4 ON C4.CotisationID = Ct.CotisationID
			LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
			LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
			WHERE	C4.iCESP800ID IS NULL -- Pas revenu en erreur
				AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
				AND R4.iCESP400ID IS NULL -- Pas annulé
			GROUP BY
				C4.OperID,
				C4.CotisationID,
				C4.ConventionID,
				C4.iCESP400ID,
				C4.tiCESP400TypeID,
				C4.tiCESP400WithdrawReasonID,
				C4.dtTransaction,
				C4.iPlanGovRegNumber,
				C4.ConventionNo,
				C4.vcSubscriberSINorEN,
				C4.vcBeneficiarySIN,
				C4.fCotisation,
				C4.bCESPDemand,
				C4.dtStudyStart,
				C4.tiStudyYearWeek,
				C4.fCESG,
				
				/* Modif Fred 2010-10-14 */
				C4.fACESGPart,
				
				C4.fEAPCESG,
				C4.fEAP,
				C4.fPSECotisation,
				C4.iOtherPlanGovRegNumber,
				C4.vcOtherConventionNo,
				C4.tiProgramLength,
				C4.cCollegeTypeID,
				C4.vcCollegeCode,
				C4.siProgramYear,
				C4.vcPCGSINorEN,
				C4.vcPCGFirstName,
				C4.vcPCGLastName,
				C4.tiPCGType,
				C4.fCLB,
				C4.fEAPCLB,
				C4.fPG,
				C4.fEAPPG,
				C4.vcPGProv
         --   HAVING SUM(C9.fCESG + C9.fACESG + C9.fCLB) >  0 OR COUNT(C9.iCESP900ID) = 0
			  HAVING SUM(C9.fCESG + C9.fACESG + C9.fCLB) <> 0 OR COUNT(C9.iCESP900ID) = 0 --2017-08-15

		IF @@ERROR <> 0
			SET @iResult = -5
	END

	IF @iOperBlobID > 0 AND @iResult > 0
	BEGIN
		-- Annulation des opérations
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				iReversedCESP400ID,
				tiCESP400TypeID,
				tiCESP400WithdrawReasonID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				dtStudyStart,
				tiStudyYearWeek,
				fCESG,
				
				/* Modif Fred 2010-10-14 */
				fACESGPart,
				
				fEAPCESG,
				fEAP,
				fPSECotisation,
				iOtherPlanGovRegNumber,
				vcOtherConventionNo,
				tiProgramLength,
				cCollegeTypeID,
				vcCollegeCode,
				siProgramYear,
				vcPCGSINorEN,
				vcPCGFirstName,
				vcPCGLastName,
				tiPCGType,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				vcPGProv,
				fCotisationGranted )
			SELECT
				C4.OperID,
				C4.CotisationID,
				C4.ConventionID,
				C4.iCESP400ID,
				C4.tiCESP400TypeID,
				C4.tiCESP400WithdrawReasonID,
				'FIN',
				C4.dtTransaction,
				C4.iPlanGovRegNumber,
				C4.ConventionNo,
				C4.vcSubscriberSINorEN,
				C4.vcBeneficiarySIN,
				-C4.fCotisation,
				C4.bCESPDemand,
				C4.dtStudyStart,
				C4.tiStudyYearWeek,
				
				CASE 
					WHEN C4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fCESG + C9.fACESG),0)
				ELSE -C4.fCESG
				END,
				CASE 
					WHEN C4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fACESG),0)
				ELSE -C4.fACESGPart
				END,

				-C4.fEAPCESG,
				-C4.fEAP,
				-C4.fPSECotisation,
				C4.iOtherPlanGovRegNumber,
				C4.vcOtherConventionNo,
				C4.tiProgramLength,
				C4.cCollegeTypeID,
				C4.vcCollegeCode,
				C4.siProgramYear,
				C4.vcPCGSINorEN,
				C4.vcPCGFirstName,
				C4.vcPCGLastName,
				C4.tiPCGType,
				CASE 
					WHEN C4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fCLB),0)
				ELSE -C4.fCLB
				END,
				-C4.fEAPCLB,
				-C4.fPG,
				-C4.fEAPPG,
				C4.vcPGProv,
				-ISNULL(SUM(C9.fCotisationGranted),0)
			FROM @tOperToCancel O
			JOIN Un_CESP400 C4 ON C4.OperID = O.OperID
			LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
			LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
			WHERE	C4.iCESP800ID IS NULL -- Pas revenu en erreur
				AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
				AND R4.iCESP400ID IS NULL -- Pas annulé
			GROUP BY 
				C4.OperID,
				C4.CotisationID,
				C4.ConventionID,
				C4.iCESP400ID,
				C4.tiCESP400TypeID,
				C4.tiCESP400WithdrawReasonID,
				C4.dtTransaction,
				C4.iPlanGovRegNumber,
				C4.ConventionNo,
				C4.vcSubscriberSINorEN,
				C4.vcBeneficiarySIN,
				C4.fCotisation,
				C4.bCESPDemand,
				C4.dtStudyStart,
				C4.tiStudyYearWeek,
				C4.fCESG,
				
				/* Modif Fred 2010-10-14 */
				C4.fACESGPart,
				
				C4.fEAPCESG,
				C4.fEAP,
				C4.fPSECotisation,
				C4.iOtherPlanGovRegNumber,
				C4.vcOtherConventionNo,
				C4.tiProgramLength,
				C4.cCollegeTypeID,
				C4.vcCollegeCode,
				C4.siProgramYear,
				C4.vcPCGSINorEN,
				C4.vcPCGFirstName,
				C4.vcPCGLastName,
				C4.tiPCGType,
				C4.fCLB,
				C4.fEAPCLB,
				C4.fPG,
				C4.fEAPPG,
				C4.vcPGProv
           -- HAVING SUM(C9.fCESG + C9.fACESG + C9.fCLB) >	0 OR COUNT(C9.iCESP900ID) = 0
			  HAVING SUM(C9.fCESG + C9.fACESG + C9.fCLB) <> 0 OR COUNT(C9.iCESP900ID) = 0 --2017-08-15

		IF @@ERROR <> 0
			SET @iResult = -6
	END
	
	IF @iResult > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN' 

		IF @@ERROR <> 0
			SET @iResult = -7
	END


	IF @bInTransaction = 0
	BEGIN
		IF @iResult > 0
			------------------
			COMMIT TRANSACTION
			------------------
		ELSE
			--------------------
			ROLLBACK TRANSACTION
			--------------------
	END

	RETURN(@iResult)
END

