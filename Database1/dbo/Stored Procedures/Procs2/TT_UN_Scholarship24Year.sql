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
Nom                 :	TT_UN_Scholarship24Year
Description         :	Traitement de résiliation de bourse pour 24 ans d’âge.  Ce traitement consistera à fermer
								toutes les bourses dont le statut sera « Admissible », « En attente » ou « En réserve » des
								conventions dont la première bourse sera dans un de ces trois statut et dont le 24ième
								anniversaire du bénéficiaire aura eu lieu l’année précédente.  La fermeture changera le
								statut de la bourse à « 24 ans d’âge ».
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_Scholarship24Year] 
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@iScholarshipYear INTEGER

	SELECT @iScholarshipYear = MAX(ScholarshipYear)
	FROM Un_Def

	-- Traitement de résiliation de bourse pour 24 ans d’âge.  Ce traitement consiste à fermer toutes les bourses dont
	-- le statut est « Admissible », « En attente » ou « En réserve » des conventions dont la première bourse est dans
	-- un de ces trois statut et dont le 24ième anniversaire du bénéficiaire a eu lieu l’année précédente.  La
	-- fermeture change le statut de la bourse à « 24 ans d’âge ».
	UPDATE Un_Scholarship
	SET
		ScholarshipStatusID = '24Y'
	FROM Un_Scholarship S
	JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
	JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
	JOIN ( -- Conventions dont la première bourse est dans un de ces trois statut : « Admissible », « En attente »
			 -- ou « En réserve »
		SELECT DISTINCT
			ConventionID
		FROM Un_Scholarship
		WHERE ScholarshipStatusID IN ('RES','ADM','WAI')
			AND ScholarshipNo = 1
		) V ON V.ConventionID = C.ConventionID
	-- le 24ième anniversaire du bénéficiaire a eu lieu avant le 1 octobre de l’année précédente
	WHERE YEAR(H.BirthDate) + 24 < @iScholarshipYear

	IF @@ERROR = 0
		RETURN 1
	ELSE
		RETURN -1
    */
END