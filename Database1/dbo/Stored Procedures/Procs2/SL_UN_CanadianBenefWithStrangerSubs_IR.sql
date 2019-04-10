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
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CanadianBenefWithStrangerSubs_IR
Description         :	Recherche d'anomalies : Retrouver les bénéficiaires canadiens de souscripteurs étrangers
Valeurs de retours  :	Dataset de données
							ObjectCodeID 			INTEGER			ID unique de l'objet
							IrregularityLevel		TINYINT			Degrée de gravité
							ObjectType				VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							Bénéficiaire			VARCHAR(87)		Prénom et nom du bénéficiaire séparé par une espace.
							NAS						VARCHAR(75)		Numéro d’assurance sociale du bénéficiaire
							Date de naissance		DATETIME		Date de naissance du bénéficiaire

Note                :	ADX0000496	IA	2005-02-03	Bruno Lapointe		Création
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes Bénéficiare, NAS, Date de naissance suppression de la colonne Description
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CanadianBenefWithStrangerSubs_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75))	-- String recherché
AS
BEGIN
    
    SELECT 1/0
    /*
	SELECT
		ObjectCodeID,
		IrregularityLevel,
		ObjectType,
		[Bénéficiaire],
		[NAS],
		[Date de naissance],
		[État]
	FROM (
		SELECT  
			ObjectCodeID = C.ConventionID,
			IrregularityLevel = 1,
			ObjectType = 'TUnConvention', 
			[Bénéficiaire] = H2.LastName + ', ' + H2.FirstName,
			[NAS] = ISNULL( SUBSTRING(H2.SocialNumber, 1, 3) + ' ' + SUBSTRING(H2.SocialNumber, 4, 3) + ' ' + SUBSTRING(H2.socialnumber, 7, 3) , ''),
			[Date de naissance] = H2.BirthDate,
			[État] = Cst.ConventionStateName
		FROM dbo.Un_Convention C 
		JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID -- Info du souscripteur 
		JOIN dbo.Mo_Human H1 ON S.SubscriberID = H1.HumanID
		JOIN dbo.Mo_Adr A1 ON H1.AdrID = A1.AdrID
		JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID -- Info du beneficiaire
		JOIN dbo.Mo_human H2 ON B.BeneficiaryID = H2.HumanID
		JOIN dbo.Mo_Adr A2 ON H2.AdrID = A2.AdrID
		JOIN (
				SELECT
						ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM Un_ConventionConventionState CCS
				GROUP BY ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON Cst.ConventionStateID = CCS2.ConventionStateID
		WHERE A1.CountryID <> 'CAN' -- Le souscripteur ne vient pas du canada 
			AND A2.CountryID = 'CAN' -- Le beneficiaire vient du canada 
			AND U.TerminatedDate IS NULL -- Conventions non résiliées 
		GROUP BY C.ConventionID, H2.FirstName, H2.LastName, H2.socialnumber, H2.BirthDate, Cst.ConventionStateName
		) V 
	WHERE CASE @SearchType 
				WHEN 'Lvl' THEN CAST(V.IrregularityLevel AS VARCHAR)
				WHEN 'Obj' THEN V.ObjectType
				ELSE ''		-- Aucun critères de recherche
			END LIKE @Search

	ORDER BY
		IrregularityLevel,
		[Bénéficiaire],
		[NAS]
    */
END