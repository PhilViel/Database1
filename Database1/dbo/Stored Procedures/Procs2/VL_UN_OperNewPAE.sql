/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_OperNewPAE
Description         :	Valide si l’on peut faire un PAE
Exemple d'appel		:	DECLARE @i INT
						EXEC @i = dbo.VL_UN_OperNewPAE 123311
						SELECT @i
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Échec
										-1 : Preuve d’inscription incomplète
										-2 : Le bénéficiaire de la convention sera sans NAS et citoyen canadien.
Note                :	ADX0001419	IA	2007-06-19	Bruno Lapointe			Création
										2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																			afin de bloquer le traitement si l'état = "Proposition"
										2012-04-05	Donald Huppé		Enlever message GEN12 afin de faire des PAE postdaté (voir ME Nicolas)
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperNewPAE] (
	@ConventionID INTEGER ) -- ID de la convention
AS
BEGIN
    SELECT 1/0
    /*
	DECLARE 
		@iResult INT

	IF EXISTS (
			SELECT C.ConventionID
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			WHERE C.ConventionID = @ConventionID
				AND CASE
						WHEN ISNULL(B.CollegeID,0) > 0
							AND ISNULL(B.StudyStart,0) > 0
							AND B.ProgramYear > 0
							AND B.ProgramLength > 0 
							AND B.RegistrationProof <> 0 
							AND B.SchoolReport <> 0 THEN 1
					ELSE 0
					END = 0
			)
		SET @iResult = -1 -- Message : « Preuve d’inscription incomplète. »
	ELSE IF EXISTS (
			SELECT C.ConventionID
			FROM dbo.Un_Convention C
			JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
			-- Les deux prochaines lignes trouvent les conventions dont le bénéficiaire est citoyen canadien et sans NAS
			WHERE C.ConventionID = @ConventionID
				AND ISNULL(H.SocialNumber,'') = '' -- NAS absent
				AND H.ResidID = 'CAN' -- Citoyen du Canada
			)
		SET @iResult = -2 -- Message : « Le bénéficiaire de la convention sera sans NAS et citoyen canadien. »
	/*
	ELSE IF dbo.fnCONV_ObtenirStatutConventionEnDate(@ConventionID,GETDATE()) = 'PRP'	-- 2010-04-08 : JFG : Ajout
		
		SET @iResult = -3 -- Message : « Transaction refusée, car la convention est à l'état "Proposition" »
	*/
	ELSE
		SET @iResult = 1
		
	RETURN @iResult
    */
END