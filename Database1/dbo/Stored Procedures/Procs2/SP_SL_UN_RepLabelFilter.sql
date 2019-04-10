/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_SL_UN_RepLabelFilter
Description         :	Retourne l’information nécessaire pour remplir la liste déroulante des représentants de la 
								fenêtre d’appelle des étiquettes de représentants et directeurs
Valeurs de retours  :	Dataset contenant la liste
Note                :	ADX0000629	IA	2005-01-04	Bruno Lapointe		Création
								ADX0001651	BR	2005-10-24	Bruno Lapointe		Doit sortir les représentants qui ont un niveau seulement
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_RepLabelFilter]
AS
BEGIN
	CREATE TABLE #tbRepFilter (
		RepID INTEGER,
		RepType CHAR(3),
		RepName VARCHAR(152),
		Actif BIT) 

	-- Ajoute l'option Tous les représentants et directeurs actifs
	INSERT INTO #tbRepFilter
	VALUES(0, 'AL1', 'Tous les représentants et directeurs actifs', 1)

	-- Ajoute l'option Tous les représentants actifs
	INSERT INTO #tbRepFilter
	VALUES(-1, 'AL2', 'Tous les représentants actifs', 1)

	-- Ajoute l'option Tous les directeurs actifs
	INSERT INTO #tbRepFilter
	VALUES(-2, 'AL3', 'Tous les directeurs actifs', 1)

	-- Ajoute la liste de tous les représentants et directeurs depuis le début
	INSERT INTO #tbRepFilter
		SELECT DISTINCT
			R.RepID,
			'REP',
			H.LastName+', '+H.FirstName,
			CASE 
				WHEN ISNULL(R.BusinessEnd, DATEADD(DAY,1,GETDATE())) > GETDATE() THEN 1
			ELSE 0
			END
		FROM dbo.Mo_Human H 
		JOIN Un_Rep R ON R.RepID = H.HumanID
		JOIN Un_RepLevelHist RLH ON RLH.RepID = R.RepID

	SELECT
		RepID,
		RepName,
		Actif
	FROM #tbRepFilter
	ORDER BY RepType, RepName, RepID

	DROP TABLE #tbRepFilter
END


