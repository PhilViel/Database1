/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_CRI_DocSelected
Description         :	Retourne les documents spécifiés dans le blob pour la fusion.
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-16	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_DocSelected] (
	@BlobID INTEGER) -- ID Unique du blob qui contient la liste des IDs de document spéaré par des virgules
AS
BEGIN
	-- Retourne les dossiers spécifiés de la table CRQ_Doc
	SELECT 
		D.DocID,
		D.DocTemplateID,
		T.DocTypeID,
		Y.DocTypeDesc,
		D.Doc
	FROM dbo.FN_CRQ_BlobToIntegerTable(@BlobID) L -- Construit une variable table de IDs de document avec le blob
	JOIN CRQ_Doc D ON L.Val = D.DocID
	JOIN CRQ_DocTemplate T ON D.DocTemplateID = T.DocTemplateID
	JOIN CRQ_DocType Y ON T.DocTypeID = Y.DocTypeID
	ORDER BY 
		D.DocTemplateID,
		L.ValID,
		D.DocID

	DELETE 
	FROM CRQ_Blob
	WHERE BlobID = @BlobID

	-- Fin des traitements
	RETURN @@ERROR -- Retourne 0 si tout a fonctionné, sinon l'erreur est retournée
END
