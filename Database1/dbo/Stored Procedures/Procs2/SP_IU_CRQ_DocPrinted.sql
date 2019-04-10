/****************************************************************************************************

	PROCEDURE DE MISE À JOUR DES DOCUMENTS IMPRIMÉS

*********************************************************************************
	13-05-2004  Dominic Létourneau	Création de la procedure pour CRQ-INT-00003
    2017-04-24  Pierre-Luc Simard   Ajout du délai d'une seconde
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_DocPrinted] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@BlobID INTEGER) -- ID du blob qui contient la liste des IDs des documents imprimés séparés par des virgules
AS
BEGIN
	-- Insertion du détail de l'impression d'un document dans la table CRQ_DocPrinted
	INSERT CRQ_DocPrinted(
		DocPrintConnectID,
		DocPrintTime,
		DocID)
	SELECT @ConnectID,
		GETDATE(),
		D.DocID
	FROM dbo.FN_CRQ_BlobToIntegerTable(@BlobID) T -- Construit une variable table avec la liste des IDs de documents imprimés
	JOIN CRQ_Doc D ON T.Val = D.DocID -- S'assure que le document existe

    -- Délai d'une seconde pour s'assurer que les documents du même type n'auront pas le même nom que celui-ci.
    WAITFOR DELAY '00:00:01'
	
    -- Note: Puisque l'opération peut mettre à jour un grand nombre de dossiers, la gestion du log ne sera pas implantée

	-- Fin des traitements
	RETURN @@ERROR -- Si une erreur s'est produite, elle est retournée, sinon 0 (modification effectuée avec succès)
END

