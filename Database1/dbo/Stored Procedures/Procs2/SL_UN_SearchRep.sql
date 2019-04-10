/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchRep
Description         :	Procédure de recherche de représentant.

Exemple d'appel :
			EXECUTE [dbo].[SL_UN_SearchRep] 2, 'IDs', '149462', 	0, 0

Valeurs de retours  :	Dataset :
									RepID				INTEGER			ID du représentant
									RepCode				VARCHAR(75)		Code du représentant
									RepLicenseNo		VARCHAR(75)		Numéro de permis du représentant
									BusinessStart 		DATETIME			Date d'embauche
									BusinessEnd			DATETIME			Date du départ
									HistVerifConnectID	INTEGER		    ID unique de connexion (Mo_Connect.ConnectID) de l'usager 
																			qui a vérifier l'historique des boss et des niveaux de ce 
																			représentant. NULL=Personne ne l'a vérifié.
									LastName			VARCHAR(50)		Nom
									FirstName			VARCHAR(35)		Prénom 
									Phone1				VARCHAR(27)		Tél. résidence
									SocialNumber		VARCHAR(75)		Numéro d’assurance sociale
Note                :	
    ADX0001185	IA	2006-11-24	Bruno Lapointe			Optimisation, documentation
					2008-01-03	Pierre-Luc Simard		Ajout du mot Inactif dans le prénom du représentant lorsqu'il a une date de fin de contrat
					2008-09-29	Pierre-Luc Simard		Correction du prénom lorsque le code du représentant est inexistant	
					2008-11-17	Donald Huppé			Recherche par "PHO" : On recherche maintenant dans tous les champs de numéro de téléphone
					2008-12-11	Pierre-Luc Simard		Recherche par nom et prénom sans tenir compte des accents
					2010-02-19	Jean-François Gauthier  Ajout du critère de recherche IDs afin de chercher avec l'identifiant du bénéficiaire
					2010-02-22	Jean-François Gauthier	Ajout du champ iNumeroBDNI en valeur de retour
				    2016-02-26  Steeve Picard           Prendre en charge les cas de date post-datée lorsqu'on affiche «Inactif» pour le représentant
					2016-05-24	Donald Huppé			Correction de la modif du 2016-02-26.  On fait IsNull(R.BusinessEnd, '9999-12-31') au lieu de IsNull(R.BusinessEnd, getDate())
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchRep] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType CHAR(3), -- Type de recherche: LNa(Nom, prénom), FNa(Prénom, nom), SNu(Nas), Pho(Telephone), RCo(Code du représentant), IDs(Identifiant du représentant)
	@Search VARCHAR(87), -- Critère de recherche
	@RepID INTEGER = 0, -- Identifiant unique du représentant (0 pour tous)
	@BossID INTEGER = 0 ) -- Identifiant unique du directeur (0 = pas un directeur)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME = GETDATE(),
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	-- Création d'une table temporaire
	CREATE TABLE #tRep (RepID INTEGER)
	
	IF @BossID > 0 -- Si on recherche par directeur
		-- INSÈRE TOUS LES REPRÉSENTANTS SOUS UN REP DANS LA TABLE TEMPORAIRE
		INSERT #tRep
			EXECUTE SL_UN_BossOfRep @BossID
	ELSE
		INSERT #tRep
			EXECUTE SL_UN_BossOfRep @RepID

	-- Recherche du rep seulement ou des rep qui sont sous un directeur
	SELECT	
		R.RepID,
		RepCode = ISNULL(R.RepCode, ''),
		RepLicenseNo = ISNULL(R.RepLicenseNo, ''),
		R.BusinessStart, 
		R.BusinessEnd, 
		HistVerifConnectID = ISNULL(R.HistVerifConnectID, 0),
		H.LastName,
		--Firstname = H.FirstName,    	Ligne enlevée et remplacée par celle ci-dessous pour ajouter le mot Inactif au prénom
		Firstname = H.FirstName + IsNull(' (' + R.RepCode + ')', '')
		                        + CASE WHEN IsNull(R.BusinessEnd, '9999-12-31') > getDate() THEN '' 
		                               ELSE ' (Inactif)' 
		                          END,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(ISNULL(A.Phone1, ''), A.CountryID) ,
		H.SocialNumber,
		R.iNumeroBDNI
	FROM Un_Rep R
		JOIN #tRep B ON R.RepID = B.RepID OR B.RepID = 0
		JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
		LEFT JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
	WHERE CASE @SearchType 
				WHEN 'FNa' THEN H.FirstName + ', ' + H.LastName
				WHEN 'LNa' THEN H.LastName + ', ' + H.FirstName
				WHEN 'RCo' THEN R.RepCode
				WHEN 'SNu' THEN H.SocialNumber
				WHEN 'Pho' THEN A.Phone1
				WHEN 'IDs' THEN CAST(R.RepID AS VARCHAR(25))
			END COLLATE French_CI_AI LIKE @Search
		OR (@SearchType = 'Pho' 
			AND (A.Phone2 like @Search 
				or A.Fax like @Search 
				or A.Mobile like @Search 
				or A.WattLine like @Search 
				or A.OtherTel like @Search 
				or A.Pager like @Search))
	GROUP BY 
		R.RepID, 
		R.RepCode, 
		R.RepLicenseNo, 
		R.BusinessStart, 
		R.BusinessEnd, 
		R.HistVerifConnectID, 
		H.LastName, 
		H.FirstName, 
		A.Phone1, 
		A.CountryID, 
		H.SocialNumber,
		R.iNumeroBDNI
	ORDER BY 
		CASE @SearchType 
			WHEN 'FNa' THEN FirstName
			WHEN 'LNa' THEN LastName
			WHEN 'RCo' THEN RepCode
			WHEN 'SNu' THEN SocialNumber
			WHEN 'Pho' THEN Phone1
			WHEN 'IDs' THEN CAST(R.RepID AS VARCHAR(25))
		END,
		CASE @SearchType 
			WHEN 'LNa' THEN FirstName
		ELSE LastName
		END,
		CASE 
			WHEN @SearchType IN ('FNa', 'LNa') THEN SocialNumber
		ELSE
			FirstName
		END, 
		SocialNumber

	DROP TABLE #tRep 

	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceSearch.
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
				DATEDIFF(SECOND, @dtBegin, @dtEnd), -- Temps en seconde
				@dtBegin,
				@dtEnd,
				'Recherche de représentant par '+
					CASE @SearchType
						WHEN 'LNa' THEN 'nom, prénom : ' 
						WHEN 'Pho' THEN 'téléphone : ' 
						WHEN 'SNu' THEN 'NAS : '
						WHEN 'FNa' THEN 'prénom, nom : ' 
						WHEN 'RCo' THEN 'code : '
						WHEN 'IDs' THEN 'identifiant : '
					END + @Search,
				'SL_UN_SearchRep',
				'EXECUTE SL_UN_SearchRep @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)+
					', @BossID = '+CAST(@BossID AS VARCHAR)
END
