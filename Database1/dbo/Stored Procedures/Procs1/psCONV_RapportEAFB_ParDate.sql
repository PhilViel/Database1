/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_RapportEAFB_ParDate
Nom du service		: Obtenir le rapport EAFB d'une convention 
But 				: Obtenir les données du rapport des EAFB , à partir de la sp SL_UN_TransactionHistoryForEAFB, à partir du numéro de convention 
					  Crée pour les test de relevé de Dépôt.  Le filtre des dates est programmé dans le rapport SSRS à l'aide d'un filtre
					  Le but de tout ça est de partir de la sp original de l'historique des EAFB, afin de ne pas avoir à entretenir une autre SP
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	exec [dbo].[RapportEAFB_ParDate] 'R-20091203092'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-11-21		Donald Huppé						Création du service							
********************************************************************************************************************/

-- exec RapportEAFB_ParDate 'R-20091203092'

CREATE PROCEDURE [dbo].[psCONV_RapportEAFB_ParDate] 
						(
						@ConventionNO	varchar(15)
						)
AS						
BEGIN

	declare @ConventionID int
	
	SELECT @ConventionID = ConventionID FROM dbo.Un_Convention where ConventionNO = @ConventionNO

	exec SL_UN_TransactionHistoryForEAFB 'CNV',@ConventionID

END

