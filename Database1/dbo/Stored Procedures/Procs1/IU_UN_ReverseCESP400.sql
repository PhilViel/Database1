/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_ReverseCESP400
Description         :	Procédure qui renverse les enregistrements 400 pour une opération de type 11 seulement
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000847	IA	2006-03-16	Bruno Lapointe		Création
								ADX0001970	BR	2006-06-12	Bruno Lapointe		Ne gérait pas les opérations sans cotisations.
																				Exemple : les PAE.
								ADX0002065	BR	2006-08-18	Bruno Lapointe		Gestion du champ Un_CESP400.fCotisationGranted
								ADX0002426  BR	2007-05-08	Bruno Lapointe		Création de 900 pour PAE, TIN et OUT
								ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
								ADX0002465	BR	2007-05-31	Bruno Lapointe	Correction du problème des annualtions de 400 qui
																	se doublait quand il avait plus d'une 900 sur la 400 annulée.
												2011-01-31	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ReverseCESP400] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@CotisationID INTEGER, -- ID de la cotisation
	@OperID INTEGER ) -- ID de l'opération
AS
BEGIN
	DECLARE
		@iResult INT,
		@iCESP400ID INT,
		@iCESP900ID INT

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
			G4.OperID,
			G4.CotisationID,
			G4.ConventionID,
			G4.iCESP400ID,
			G4.tiCESP400TypeID,
			G4.tiCESP400WithdrawReasonID,
			'FIN',
			G4.dtTransaction,
			G4.iPlanGovRegNumber,
			G4.ConventionNo,
			G4.vcSubscriberSINorEN,
			G4.vcBeneficiarySIN,
			-G4.fCotisation,
			G4.bCESPDemand,
			G4.dtStudyStart,
			G4.tiStudyYearWeek,
			
			-- SCEE
			CASE 
				WHEN G4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fCESG + C9.fACESG),0)
			ELSE -G4.fCESG
			END,
			
			-- SCEE+
			CASE 
				WHEN G4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fACESG),0)
			ELSE -G4.fACESGPart
			END,
			
			-G4.fEAPCESG,
			-G4.fEAP,
			-G4.fPSECotisation,
			G4.iOtherPlanGovRegNumber,
			G4.vcOtherConventionNo,
			G4.tiProgramLength,
			G4.cCollegeTypeID,
			G4.vcCollegeCode,
			G4.siProgramYear,
			G4.vcPCGSINorEN,
			G4.vcPCGFirstName,
			G4.vcPCGLastName,
			G4.tiPCGType,
			CASE 
				WHEN G4.tiCESP400TypeID = 24 THEN -ISNULL(SUM(C9.fCLB),0)
			ELSE -G4.fCLB
			END,
			-G4.fEAPCLB,
			-G4.fPG,
			-G4.fEAPPG,
			G4.vcPGProv,
			-ISNULL(SUM(C9.fCotisationGranted),0)
		FROM Un_CESP400 G4
		LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID AND R4.iCESP800ID IS NULL
		LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = G4.iCESP400ID
		WHERE	( G4.OperID = @OperID
				OR G4.CotisationID = @CotisationID
				)
			AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
			AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
			AND R4.iCESP400ID IS NULL -- Pas annulé
		GROUP BY
			G4.OperID,
			G4.CotisationID,
			G4.ConventionID,
			G4.iCESP400ID,
			G4.tiCESP400TypeID,
			G4.tiCESP400WithdrawReasonID,
			G4.dtTransaction,
			G4.iPlanGovRegNumber,
			G4.ConventionNo,
			G4.vcSubscriberSINorEN,
			G4.vcBeneficiarySIN,
			G4.fCotisation,
			G4.bCESPDemand,
			G4.dtStudyStart,
			G4.tiStudyYearWeek,
			G4.fCESG,
			G4.fACESGPart,
			G4.fEAPCESG,
			G4.fEAP,
			G4.fPSECotisation,
			G4.iOtherPlanGovRegNumber,
			G4.vcOtherConventionNo,
			G4.tiProgramLength,
			G4.cCollegeTypeID,
			G4.vcCollegeCode,
			G4.siProgramYear,
			G4.vcPCGSINorEN,
			G4.vcPCGFirstName,
			G4.vcPCGLastName,
			G4.tiPCGType,
			G4.fCLB,
			G4.fEAPCLB,
			G4.fPG,
			G4.fEAPPG,
			G4.vcPGProv

	IF @@ERROR <> 0 
		SET @OperID = -100
	-- S'assure de retourner l'OperID si tout a bien fonctionné
	ELSE IF @OperID = 0 AND @CotisationID > 0
		SELECT @OperID = OperID
		FROM Un_Cotisation
		WHERE CotisationID = @CotisationID

	IF @OperID > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN' 

		IF @@ERROR <> 0
			SET @OperID = -101
	END

	RETURN @OperID
END
