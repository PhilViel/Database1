/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_CRI_DocTemplateDocTypeBlob
Description         :	Retourne un template pour la fusion de document
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-16	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_DocTemplateDocTypeBlob] (
	@DocTemplateID INTEGER) -- Identifiant d'un modèle	
AS
BEGIN
	-- Retourne les blobs reliés à un modèle de document
	SELECT 	
		A.DocTemplateID,
		F.DocTypeDataFormatID,
		A.DocTypeID,
		A.DocTypeTime,
		T.DocTemplate,	
		F.DocTypeDataFormat
	FROM (-- Recherche de la plus récente version du type de document  
				SELECT 
					DocTemplateID,
					DocTypeID,
					DocTypeTime = MAX(DocTypeTime)
				FROM (-- Recherche des infos reliées au template reçu en paramètre  
						SELECT 
							T.DocTemplateID,
							F.DocTypeID,
							F.DocTypeTime
						FROM CRQ_DocTemplate T
						INNER JOIN CRQ_DocType TY ON T.DocTypeID = TY.DocTypeID
						INNER JOIN CRQ_DocTypeDataFormat F 
							ON TY.DocTypeID = F.DocTypeID
							AND F.DocTypeTime <= T.DocTemplateTime
						WHERE T.DocTemplateID = @DocTemplateID
					) T
				GROUP BY DocTemplateID, DocTypeID
		) A
	JOIN CRQ_DocTypeDataFormat F ON A.DocTypeID = F.DocTypeID AND A.DocTypeTime = F.DocTypeTime
	JOIN CRQ_DocTemplate T ON A.DocTemplateID = T.DocTemplateID

	-- Fin des traitements
	RETURN 0
END
