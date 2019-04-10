/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Region
Description         :	Procédure retournant une ou toutes les régions.
Valeurs de retours  :	Dataset :
									iRegionID	INTEGER		ID de la région.
									vcRegion		VARCHAR(75)	Région (Nom).
Note                :	ADX0000730	IA	2005-07-06	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Region] (
	@iRegionID INTEGER ) -- ID de la région voulue, 0 pour tous.
AS
BEGIN
	SELECT 
		iRegionID, -- ID de la région.
		vcRegion -- Région (Nom).
	FROM Un_Region
	WHERE @iRegionID = 0
		OR @iRegionID = iRegionID
	ORDER BY vcRegion
END

