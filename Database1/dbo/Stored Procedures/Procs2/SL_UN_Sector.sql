/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Sector
Description         :	Procédure retournant un ou tous les secteurs.
Valeurs de retours  :	Dataset :
									iSectorID	INTEGER		ID du secteur.
									vcSector		VARCHAR(75)	Secteur (Nom).
Note                :	ADX0000730	IA	2005-07-06	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Sector] (
	@iSectorID INTEGER ) -- ID du secteur voulu, 0 pour tous.
AS
BEGIN
	SELECT 
		iSectorID, -- ID du secteur.
		vcSector -- Secteur (Nom).
	FROM Un_Sector
	WHERE @iSectorID = 0
		OR @iSectorID = iSectorID
	ORDER BY vcSector
END

