/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_RP_UN_RepLabel
Description         :	Retourne les données pour les étiquettes de représentants et directeurs
Valeurs de retours  :	Dataset contenant les données
Note                :	ADX0000629	IA	2005-01-04	Bruno Lapointe		Création
								ADX0001474	BR	2005-06-29	Bruno Lapointe		Formatage du code postal
						2009-04-28	Donald Huppé	Remplacer le LongSexName par le ShortSexName (GLPI 1695)
-- exec SP_RP_UN_RepLabel 497165, 14
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_RepLabel] (
	@RepID INTEGER, -- ID unique du représentant ou directeur (0 = Tous les représentants et directeurs actifs, -1 = Tous les représentants actifs et -2 = Tous les directeurs actifs)
	@Qty INTEGER) -- Nombre de copie de chaque étiquettes
AS
BEGIN
	DECLARE 
		@iCurrentQty INTEGER

	SET @iCurrentQty = 0

	CREATE TABLE #tbRepLabel (
		Title VARCHAR(75),
		FirstName VARCHAR(35),
		LastName VARCHAR(50),
		Address VARCHAR(75),
		City VARCHAR(100),
		Statename VARCHAR(75),
		ZipCode VARCHAR(10))

	-- Fait un boucle pour avoir la quantité d'étiquettes voulues
	WHILE @iCurrentQty < @Qty
	BEGIN
		-- Insertion d'une fois les étiquettes
		INSERT INTO #tbRepLabel
			SELECT DISTINCT
				Title = S.ShortSexName,
				H.FirstName,
				H.LastName,
				A.Address,
				A.City,
				A.Statename,
				dbo.FN_CRQ_FormatZipCode(A.ZipCode, A.CountryID)
			FROM Un_RepLevelHist LH 
			JOIN Un_RepLevel L ON L.RepLevelID = LH.RepLevelID
			JOIN dbo.Mo_Human H ON H.HumanID = LH.RepID
			JOIN Un_Rep R ON R.RepID = H.HumanID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			JOIN Mo_Sex S ON S.SexID = H.SexID AND S.LangID = H.LangID
			WHERE (	@RepID = R.RepID	
					OR	(	(	(	@RepID IN (0, -2) -- Tous les directeurs
								AND L.RepRoleID IN ('DIR', 'DIS')
								)
							OR	(	@RepID IN (0, -1) -- Tous les représentants
								AND L.RepRoleID IN ('REP', 'VES')
								)
							)
						AND ISNULL(R.BusinessEnd, DATEADD(DAY,1,GETDATE())) > GETDATE() -- Actif
						)
					)

		SET @iCurrentQty = @iCurrentQty + 1
	END

	-- Sélection final
	SELECT
		Title,
		FirstName,
		LastName,
		Address,
		City,
		Statename,
		ZipCode
	FROM #tbRepLabel
	ORDER BY 
		LastName,
		FirstName,
		ZipCode,
		Address

	DROP TABLE #tbRepLabel
END


