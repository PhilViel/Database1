
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_ExternalPlan_IU
Description 		:	Procédure qui valide un régime externe avant l’insertion ou la mise à jour
Valeurs de retour	:	Dataset :
							ErrorCode	CHAR(3)			Code d’erreur
							ErrorText	VARCHAR(255)	Texte de l’erreur

						Code	Texte
						EP1		Le numéro d’enregistrement gouvernemental a déjà été saisi pour le promoteur nom du promoteur.
						EP2		Impossible de modifier le numéro d’enregistrement gouvernemental.  Celui-ci a déjà été utilisé dans un transfert externe ou interne.

Note			:		ADX0001159	IA	2007-02-12	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE dbo.VL_UN_ExternalPlan_IU (
	@ExternalPlanID INTEGER,					-- ID du régime externe
	@ExternalPlanGovernmentRegNo   VARCHAR(10)) -- Numéro d’enregistrement gouvernemental	
AS
BEGIN
	DECLARE @ErrTable TABLE(
		ErrorCode CHAR(3),
		ErrorText VARCHAR(255))
	
	IF EXISTS(	SELECT *
				FROM Un_ExternalPlan
				WHERE ExternalPlanGovernmentRegNo = @ExternalPlanGovernmentRegNo
						AND ExternalPlanID <> @ExternalPlanID)
		INSERT INTO @ErrTable
			SELECT DISTINCT
					'EP1',
					'Le numéro de régime spcéimen a déjà été saisi pour le promoteur ' + ISNULL(C.CompanyName, 'Inconnu')
			FROM Un_ExternalPlan EPL
			JOIN Un_ExternalPromo EPR ON EPL.ExternalPromoID = EPR.ExternalPromoID
			JOIN Mo_Company C ON C.CompanyID = EPR.ExternalPromoID
			WHERE EPL.ExternalPlanGovernmentRegNo = @ExternalPlanGovernmentRegNo
						AND EPL.ExternalPlanID <> @ExternalPlanID

	IF @ExternalPlanID > 0 --Mise à jour
	BEGIN
		IF EXISTS ( SELECT *
					FROM Un_ExternalPlan
					WHERE ExternalPlanID = @ExternalPlanID
							AND ExternalPlanGovernmentRegNo <> @ExternalPlanGovernmentRegNo)
		BEGIN --Modification du numéro du plan
			IF EXISTS ( SELECT *
						FROM Un_OUT
						WHERE ExternalPlanID = @ExternalPlanID)			-- Utilisé dans un OUT
				OR EXISTS ( SELECT *
							FROM Un_TIN
							WHERE ExternalPlanID = @ExternalPlanID)		-- Utilisé dans un TIN
				INSERT INTO @ErrTable
					SELECT
							'EP2',
							'Impossible de modifier le numéro de régime spécimen.  Celui-ci a déjà été utilisé dans un transfert IN ou OUT.'		
		END
	END
		
	SELECT *
	FROM @ErrTable
END

