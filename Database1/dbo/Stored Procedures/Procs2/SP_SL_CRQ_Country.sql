/****************************************************************************************************

	PROCEDURE RETOURNANT LES PAYS

*********************************************************************************
	05-05-2004 Dominic Létourneau
		Migration de l'ancienne procedure selon les nouveaux standards
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_Country] (@ConnectID MoID) -- Identifiant unique de la connection
AS

BEGIN

	-- Retourne les dossiers de la table de pays
	SELECT 
		CountryID,
		CountryName
	FROM Mo_Country

END

