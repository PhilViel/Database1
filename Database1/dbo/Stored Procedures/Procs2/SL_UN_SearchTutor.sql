/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_SearchTutor
Description         :	Procédure de recherche de tuteur.
Valeurs de retours  :	Dataset :
					iTutorID		INTEGER		ID du tuteur, correspond au HumanID.
					vcEN			VARCHAR(30)	Numéro d’entreprise, si le tuteur en est une.
					FirstName		VARCHAR(35)	Prénom du tuteur
					LastName		VARCHAR(50)	Nom
					SocialNumber		VARCHAR(75)	Numéro d’assurance sociale
					Address			VARCHAR(75)	# civique, rue et # d’appartement.
					Phone1			VARCHAR(27)	Tél. résidence

Note                :		ADX0000692	IA	2005-05-04	Bruno Lapointe		Création
				ADX0000827	IA	2006-03-16	Bruno Lapointe			Géré le prénom NULL des tuteurs-compagnies
											Alain Quirion			Optimisation
								2008-11-17	Donald Huppé			Recherche par "PHO" : On recherche maintenant dans tous les champs de numéro de téléphone
								2008-12-11	Pierre-Luc Simard		Recherche par nom et prénom sans tenir compte des accents
								2010-01-29	Jean-François Gauthier	Ajout du critère de recherche IDs afin de chercher avec l'identifiant du tuteur
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchTutor] (
	@ConnectID INTEGER,
	@vcSearchType VARCHAR(3),	-- Type de recherche : 
								--	FNa = Prénom, nom
								-- 	LNa = Nom, prénom
								--	SNu = Numéro d’assurance social
								--	ENu = Numéro d’entreprise
								--	Pho = Numéro de téléphone résidentiel
								--  IDs = Identifiant du tuteur
	@vcSearch VARCHAR(100) )	-- Valeur recherché selon le @vcSearchType.
AS
BEGIN
	DECLARE 
		@Today DATETIME,
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()
	SET @Today = GETDATE()

	DECLARE @tSearchTutors TABLE (
		iTutorID INTEGER PRIMARY KEY)

	-- Nom, prénom
	IF @vcSearchType = 'LNa'
		INSERT INTO @tSearchTutors
			SELECT H.HumanID
			FROM Un_Tutor T
			JOIN dbo.Mo_Human H ON H.HumanID = T.iTutorID
			WHERE H.LastName + ', ' + ISNULL(H.FirstName,'') COLLATE French_CI_AI LIKE @vcSearch			
				
	-- Prénom, nom
	ELSE IF @vcSearchType = 'FNa'
		INSERT INTO @tSearchTutors
			SELECT H.HumanID
			FROM Un_Tutor T
			JOIN dbo.Mo_Human H ON H.HumanID = T.iTutorID
			WHERE ISNULL(H.FirstName,'') + ', ' + H.LastName COLLATE French_CI_AI LIKE @vcSearch
				OR ( H.IsCompany = 1
					AND H.LastName COLLATE French_CI_AI LIKE @vcSearch
					)
				
	-- Téléphone résidentiel
	ELSE IF @vcSearchType = 'Pho'
		INSERT INTO @tSearchTutors
			SELECT H.HumanID
			FROM Un_Tutor T
			JOIN dbo.Mo_Human H ON H.HumanID = T.iTutorID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE A.Phone1 LIKE @vcSearch  
				or A.Phone2 like @vcSearch 
				or A.Fax like @vcSearch 
				or A.Mobile like @vcSearch 
				or A.WattLine like @vcSearch 
				or A.OtherTel like @vcSearch 
				or A.Pager like @vcSearch
	--Numéro d’assurance social
	ELSE IF @vcSearchType = 'SNu'
		INSERT INTO @tSearchTutors
			SELECT H.HumanID
			FROM Un_Tutor T
			JOIN dbo.Mo_Human H ON H.HumanID = T.iTutorID
			WHERE H.SocialNumber LIKE @vcSearch
	-- Numéro d'entreprise
	ELSE IF @vcSearchType = 'Enu'
		INSERT INTO @tSearchTutors
			SELECT H.HumanID
			FROM Un_Tutor T
			JOIN dbo.Mo_Human H ON H.HumanID = T.iTutorID
			WHERE ISNULL(T.vcEN,'') LIKE @vcSearch				
	--Identitifiant du tuteur -- 2010-01-29 : JFG : Ajout
	ELSE IF @vcSearchType = 'IDs'
		INSERT INTO @tSearchTutors
		(iTutorID)
		VALUES
		(CAST(@vcSearch AS INT))

	SELECT
		T.iTutorID,
		T.vcEN,
		H.FirstName,
		H.LastName,
		H.SocialNumber,
		A.Address,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(A.Phone1, A.CountryID),
		H.IsCompany
	FROM @tSearchTutors ST
	JOIN Un_Tutor T ON ST.iTutorID = T.iTutorID
	JOIN dbo.Mo_Human H ON H.HumanID = T.iTutorID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
	LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
/* -- Le Where est inutile car on a déjà le tuteur correspondant au critère de recherche dans la table @tSearchTutors
	WHERE	CASE  
				WHEN @vcSearchType IN ('LNa','FNa') AND H.IsCompany <> 0 THEN H.LastName
				WHEN @vcSearchType = 'LNa' THEN H.LastName  + ', ' + H.FirstName
				WHEN @vcSearchType = 'FNa' THEN H.FirstName + ', ' + H.LastName
				WHEN @vcSearchType = 'SNu' THEN H.SocialNumber
				WHEN @vcSearchType = 'Pho' THEN ISNULL(A.Phone1,'')
				WHEN @vcSearchType = 'ENu' THEN ISNULL(T.vcEN,'')
			END LIKE @vcSearch
*/
	ORDER BY
		CASE @vcSearchType
			WHEN 'LNa' THEN H.LastName 
			WHEN 'Pho' THEN A.Phone1 
			WHEN 'SNu' THEN H.SocialNumber 
			WHEN 'FNa' THEN H.FirstName 
			WHEN 'ENu' THEN T.vcEN
		END,
		CASE @vcSearchType
			WHEN 'LNa' THEN H.FirstName
			ELSE H.LastName 
		END,
		CASE 
			WHEN @vcSearchType IN ('LNa', 'FNa') THEN H.SocialNumber
			ELSE H.FirstName
		END, 
		H.SocialNumber

	/** GESTION DES REQUÊTES TROP LONGUES**/
	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				1,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Recherche de tuteurs par '+
						CASE @vcSearchType
							WHEN 'LNa' THEN 'nom, prénom : ' 
							WHEN 'Pho' THEN 'téléphone : ' 
							WHEN 'FNa' THEN 'prénom, nom : ' 
							WHEN 'SNu' THEN 'Numéro d’assurance social : ' 
							WHEN 'ENu' THEN 'Numéro d’entreprise : ' 
						END + @vcSearch,
				'SL_UN_SearchTutor',
				'EXECUTE SL_UN_SearchTutor @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
					', @SearchType='+@vcSearchType+
					', @Search='+@vcSearch	
	END
END


