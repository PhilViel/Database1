/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_LancerTraitementTIN_IQEE_Total
Nom du service		: Procedure pour calculer le total des montants saisi dans l'outil de traitement d'IQEE TIN
But 				: 
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------


Exemple d’appel		:	

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-02-27		Donald Huppé						Création du service		
			


exec psTEMP_LancerTraitementTIN_IQEE_Total 
	@mIQEE = 1, 
	@mRendIQEE = 2,
	@mIQEE_Plus = 3,
	@mRendIQEE_Plus  = 4

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_LancerTraitementTIN_IQEE_Total] 
(
	@mIQEE	money
	,@mRendIQEE money
	,@mIQEE_Plus money
	,@mRendIQEE_Plus money
)
AS
BEGIN

select TotalIQEE = @mIQEE + @mRendIQEE + @mIQEE_Plus + @mRendIQEE_Plus

END
