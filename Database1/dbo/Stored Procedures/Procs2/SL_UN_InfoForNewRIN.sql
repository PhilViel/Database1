/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_InfoForNewRIN
Description         :	Retourne le total d’épargne et de frais, ainsi que les données de preuve d’inscription du 
								bénéficiaire qui sont nécessaires lors de la création d’un nouveau RIN.
Valeurs de retours  :	Dataset contenant les données
Note                :	ADX0000625	IA	2005-01-05	Bruno Lapointe		Création
			ADX0001114	IA	2006-11-21	Alain Quirion		Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
							2008-10-08	Patrick Robitaille			Ajout des champs pour vérifier si convention individuelle issue d'un RIO et admissible au RI
							2011-03-11	Frédérick Thibault		Abolition de la validation de la règle des 12 mois si la date
																				de la convention 'T' entre dans la période validable (paramètre)
							2018-01-30	Pierre-Luc Simard		Cette procédure ne devrait plus être utilisée. Par contre, elle est appelée sans paramètre 
                                                                lors de la consultation d'un RIN dans Uniacces. On doit donc la laisser.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_InfoForNewRIN] (
	@UnitID INTEGER) -- ID unique du groupe d'unités
AS
BEGIN
	DECLARE @iNbMoisAvantRINApresRIO INTEGER

	-- Va chercher le nb de mois d'attente avant un RIN suite a un RIO dans Un_Def
	SELECT @iNbMoisAvantRINApresRIO = iNb_Mois_Avant_RIN_Apres_RIO 
	FROM Un_Def

	SELECT
		U.UnitID,
		B.StudyStart,
		B.ProgramLength,
		B.ProgramYear,
		B.CollegeID,
		B.ProgramID,
		Ct.Cotisation,
		Ct.Fee,
		CESGInt = SUM(ISNULL(CO.ConventionOperAmount,0)),
		IntReimbDate = CASE
					WHEN U.InforceDate < '01-05-2006' THEN	CASE 
											WHEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'05'+'01' AS DATETIME) >= dbo.FN_CRQ_DateNoTime(GETDATE()) THEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'05'+'01' AS DATETIME)
											WHEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'11'+'01' AS DATETIME) >= dbo.FN_CRQ_DateNoTime(GETDATE()) THEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'11'+'01' AS DATETIME)
											ELSE CAST(CAST(YEAR(GETDATE())+1 AS CHAR(4))+'05'+'01' AS DATETIME)
										END
					ELSE 	CASE 
							WHEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'01'+'15' AS DATETIME) >= dbo.FN_CRQ_DateNoTime(GETDATE()) THEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'01'+'15' AS DATETIME)
							WHEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'05'+'15' AS DATETIME) >= dbo.FN_CRQ_DateNoTime(GETDATE()) THEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'05'+'15' AS DATETIME)
							WHEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'09'+'15' AS DATETIME) >= dbo.FN_CRQ_DateNoTime(GETDATE()) THEN CAST(CAST(YEAR(GETDATE()) AS CHAR(4))+'09'+'15' AS DATETIME)
							ELSE CAST(CAST(YEAR(GETDATE())+1 AS CHAR(4))+'01'+'15' AS DATETIME)
						END
				END,
		tiCode_Provenance = CASE
								WHEN EXISTS (SELECT iID_Unite_Destination
											 FROM tblOPER_OperationsRIO
											 WHERE bRIO_Annulee = 0
											 AND bRIO_QuiAnnule = 0
											 AND @UnitID = iID_Unite_Destination) THEN
									1
								ELSE
									0
							END,
		dtDate_Debut_Regime = C.dtRegStartDate,
		
		iNb_Mois_Avant_RIN_Apres_RIO = CASE
											WHEN (SELECT dbo.fnGENE_ObtenirParametre (
																	'OPER_VALIDATION_12_MOIS'
																	,U.InforceDate
																	,NULL
																	,NULL
																	,NULL
																	,NULL
																	,NULL)) = 1 THEN
												@iNbMoisAvantRINApresRIO
											ELSE
												0
										END
	
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN (
		SELECT 
			UnitID,
			Cotisation = SUM(Cotisation),
			Fee = SUM(Fee)
		FROM Un_Cotisation
		WHERE UnitID = @UnitID
		GROUP BY UnitID
		) Ct ON Ct.UnitID = U.UnitID
	LEFT JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID = 'INS'
	WHERE U.UnitID = @UnitID
	GROUP BY 
		U.UnitID,
		U.InforceDate,
		B.StudyStart,
		B.ProgramLength,
		B.ProgramYear,
		B.CollegeID,
		B.ProgramID,
		C.dtRegStartDate,
		Ct.Cotisation,
		Ct.Fee		
END


