/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ObtenirUrlAccesObjet
Nom du service		: 1.5.1	Obtenir une url d’accès par objet 
But 				: Obtenir l’url d’accès à un objet dans le système en connaissant son type
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iId_TypeObjet				Identifiant du type de l’objet sur lequel construire le lien
						cCodeTypeObjet				Code du type de l’objet sur lequel construire le lien
						iObjet						Identifiant de l’objet à lier

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-04-09		DT							Création
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirUrlAccesObjet]
(	
	@iId_TypeObjet		INT,
	@cCodeTypeObjet		char(10),
	@iObjet				INT
)
RETURNS VARCHAR(255)
AS
BEGIN
	--Valeur de retour
	DECLARE @vcURL VARCHAR(255);

	SET @vcURL = NULL;
	
	SELECT @vcURL =  vcUrlAccess 
	FROM dbo.tblGENE_TypeObjet
	WHERE iID_TypeObjet = @iId_TypeObjet AND @iId_TypeObjet IS NOT NULL
			OR 
			cCodeTypeObjet = @cCodeTypeObjet AND @cCodeTypeObjet IS NOT NULL

	RETURN REPLACE ( @vcURL,'__IDOBJET__',isnull(rtrim(ltrim(cast(@iObjet as varchar(18)))),''));

END;
