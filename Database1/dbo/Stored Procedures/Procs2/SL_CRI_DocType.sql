/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_CRI_DocType
Description         :	Retourne la liste des types de documents
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-16	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_DocType] (
	@ConnectID INTEGER) -- Identifiant unique de la connection	
AS
BEGIN

	-- Retourne tous les dossiers de la table CRQ_DocType
	SELECT 
		DocTypeID,
		DocTypeDesc,
		Selection = CONVERT(BIT, 0) -- Utilisé dans la grille Quantum pour les checkboxes
	FROM CRQ_DocType
	ORDER BY
		DocTypeDesc,
		DocTypeID

	-- Fin des traitements
	RETURN 0
END
